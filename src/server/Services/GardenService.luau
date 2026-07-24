--!strict
-- Authoritative plant/water/harvest state machine. Growth is derived (timestamp-based),
-- never simulated - see EffectiveProgress below. Design: BUILD_GUIDE.md §2.2 + Phase 2 notes.
-- World visuals + ProximityPrompt management land in a follow-up commit.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlantConfig = require(ReplicatedStorage.Shared.PlantConfig)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local GARDEN_PLOT_TAG = "GardenPlot"
local SOIL_SLOT_TAG = "SoilSlot"
local RATE_LIMIT_WINDOW = 1 -- seconds

local GardenService = {}

-- plotIndex -> slotIndex -> the physical SoilSlot part (scanned once from the Studio-built map)
-- Needed by WaterSlot's distance check.
local slotPartCache: { [number]: { [number]: BasePart } } = {}

-- player -> remote name -> current fixed-window rate limit counter
local rateState: { [Player]: { [string]: { count: number, windowStart: number } } } = {}

-- Client gets no explanation (BUILD_GUIDE §3.6: "reject silently, log loudly") - only the
-- server console records why an action was refused.
local function reject(remoteName: string, player: Player, reason: string)
	warn(`[GardenService] {remoteName} rejected for {player.Name}: {reason}`)
end

--[[
	EffectiveProgress computes 0..1 grow progress for a slot at time `now`.

	Model: growth accrues in real time at 1x, except during the most recent watering's
	active window, where it accrues at GameConfig.WATER_MULT. WaterSlot always assigns
	`WateredUntil = now + WATER_DURATION` (a flat set, not an additive stack - BUILD_GUIDE
	§2.2), so the start of that active window is always exactly
	`WateredUntil - WATER_DURATION` - no separate "WateredSince" field is needed, and the
	multiplier can never be applied retroactively to time before the water action (which
	would let a last-second water instantly finish a plant).

	Worked examples (GrowDuration=60, WATER_MULT=1.25, WATER_DURATION=600):
	  1. Never watered, planted 30s ago ->
	     elapsed=30, boosted=0 -> progress = 30/60 = 0.50
	  2. Watered at t=20 (WateredUntil=620), queried at t=40 ->
	     unwatered span [0,20)=20s @1x, watered span [20,40)=20s @1.25x
	     effective = 20*1 + 20*1.25 = 45 -> progress = 45/60 = 0.75 (vs 0.667 unwatered)
	  3. Watered right before harvest: planted t=0, watered+queried at t=59 ->
	     watered span is [59,59) (zero-length at query time) -> effective = 59
	     -> progress = 59/60 = 0.983 (watering this late buys ~nothing - not exploitable)
	  4. Offline growth: planted t=0, watered once at t=10 (WateredUntil=610), server never
	     evaluates until queried at t=700 (buff long expired) ->
	     watered span clipped to [10,610], unwatered spans [0,10) and [610,700)
	     effective = 10 + 600*1.25 + 90 = 850 -> progress = 850/60 -> clamped to 1.0
]]
function GardenService.EffectiveProgress(slot: Types.PlotSlot, now: number): number
	if slot.PlantedAt == nil or slot.GrowDuration == nil or slot.GrowDuration <= 0 then
		return 0
	end

	local plantedAt = slot.PlantedAt
	local growDuration = slot.GrowDuration
	local elapsed = math.max(0, now - plantedAt)

	local boostedSeconds = 0
	if slot.WateredUntil ~= nil then
		local wateredSince = slot.WateredUntil - GameConfig.WATER_DURATION
		local windowStart = math.max(plantedAt, wateredSince)
		local windowEnd = math.min(now, slot.WateredUntil)
		boostedSeconds = math.max(0, windowEnd - windowStart)
	end

	local normalSeconds = elapsed - boostedSeconds
	local effectiveSeconds = normalSeconds + boostedSeconds * GameConfig.WATER_MULT

	return math.clamp(effectiveSeconds / growDuration, 0, 1)
end

-- ===== World cache (Studio-built map: GardenPlot tag +PlotIndex, SoilSlot tag +SlotIndex) =====
-- Only the physical part lookup is needed here (WaterSlot's distance check); prompt/visual
-- management is added in a follow-up commit.

local function scanPlot(plot: Instance)
	local plotIndex = plot:GetAttribute("PlotIndex")
	if type(plotIndex) ~= "number" then
		warn(`[GardenService] GardenPlot {plot:GetFullName()} missing a valid PlotIndex attribute`)
		return
	end

	local slots = slotPartCache[plotIndex]
	if slots == nil then
		slots = {}
		slotPartCache[plotIndex] = slots
	end

	for _, descendant in plot:GetDescendants() do
		if descendant:IsA("BasePart") and CollectionService:HasTag(descendant, SOIL_SLOT_TAG) then
			local slotIndex = descendant:GetAttribute("SlotIndex")
			if type(slotIndex) == "number" then
				slots[slotIndex] = descendant
			end
		end
	end
end

local function buildPlotCache()
	for _, plot in CollectionService:GetTagged(GARDEN_PLOT_TAG) do
		scanPlot(plot)
	end
end

local function getSlotPart(plotIndex: number, slotIndex: number): BasePart?
	local slots = slotPartCache[plotIndex]
	if slots == nil then
		return nil
	end
	return slots[slotIndex]
end

-- ===== Rate limiting (fixed window, ≤ GameConfig.RATE_LIMIT_PER_SECOND calls/sec/remote) =====

local function checkRateLimit(player: Player, key: string): boolean
	local playerState = rateState[player]
	if playerState == nil then
		playerState = {}
		rateState[player] = playerState
	end

	local now = os.clock()
	local state = playerState[key]

	if state == nil or now - state.windowStart >= RATE_LIMIT_WINDOW then
		playerState[key] = { count = 1, windowStart = now }
		return true
	end

	if state.count >= GameConfig.RATE_LIMIT_PER_SECOND then
		return false
	end

	state.count += 1
	return true
end

-- ===== PlantSeed =====

function GardenService.PlantSeed(player: Player, slotIndex: number, seedId: string)
	local plantDef = PlantConfig[seedId]
	if plantDef == nil then
		reject("PlantSeed", player, `unknown seedId "{seedId}"`)
		return
	end

	local data = DataService.GetData(player)
	if data == nil then
		reject("PlantSeed", player, "no active profile")
		return
	end

	if slotIndex < 1 or slotIndex > data.UnlockedSlots then
		reject("PlantSeed", player, `slot {slotIndex} out of range/locked`)
		return
	end

	local slot = data.Slots[slotIndex]
	if slot == nil or slot.SeedId ~= nil then
		reject("PlantSeed", player, `slot {slotIndex} is occupied`)
		return
	end

	local owned = data.Seeds[seedId] or 0
	if owned < 1 then
		reject("PlantSeed", player, `no {seedId} seeds owned`)
		return
	end

	data.Seeds[seedId] = owned - 1

	slot.SeedId = seedId
	slot.PlantedAt = os.time()
	slot.GrowDuration = plantDef.GrowDuration
	slot.WateredUntil = nil

	DataService.MarkDirty(player)
end

local function onPlantSeed(player: Player, ...: any)
	if not checkRateLimit(player, "PlantSeed") then
		return
	end

	local slotIndex, seedId = ...
	if type(slotIndex) ~= "number" or slotIndex ~= math.floor(slotIndex) then
		reject("PlantSeed", player, "malformed slotIndex")
		return
	end
	if type(seedId) ~= "string" then
		reject("PlantSeed", player, "malformed seedId")
		return
	end

	GardenService.PlantSeed(player, slotIndex, seedId)
end

-- ===== WaterSlot =====

function GardenService.WaterSlot(waterer: Player, plotIndex: number, slotIndex: number)
	local owner = PlotService.GetOwner(plotIndex)
	if owner == nil then
		reject("WaterSlot", waterer, `plot {plotIndex} has no owner`)
		return
	end

	local data = DataService.GetData(owner)
	if data == nil then
		reject("WaterSlot", waterer, `owner {owner.Name} has no active profile`)
		return
	end

	if slotIndex < 1 or slotIndex > data.UnlockedSlots then
		reject("WaterSlot", waterer, `slot {slotIndex} out of range/locked`)
		return
	end

	local slot = data.Slots[slotIndex]
	if slot == nil or slot.SeedId == nil then
		reject("WaterSlot", waterer, `slot {slotIndex} is empty`)
		return
	end

	local slotPart = getSlotPart(plotIndex, slotIndex)
	if slotPart == nil then
		reject("WaterSlot", waterer, `no world part cached for plot {plotIndex} slot {slotIndex}`)
		return
	end

	local character = waterer.Character
	if character == nil then
		return -- no character (respawning etc.) - transient, not worth logging
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end

	-- Distance applies uniformly (owner included) per BUILD_GUIDE §3.5's WaterSlot row.
	local distance = (rootPart.Position - slotPart.Position).Magnitude
	if distance > GameConfig.WATER_RANGE then
		reject("WaterSlot", waterer, `too far ({math.floor(distance)} studs)`)
		return
	end

	slot.WateredUntil = os.time() + GameConfig.WATER_DURATION
	DataService.MarkDirty(owner)
end

local function onWaterSlot(player: Player, ...: any)
	if not checkRateLimit(player, "WaterSlot") then
		return
	end

	local plotIndex, slotIndex = ...
	if type(plotIndex) ~= "number" or plotIndex ~= math.floor(plotIndex) then
		reject("WaterSlot", player, "malformed plotIndex")
		return
	end
	if type(slotIndex) ~= "number" or slotIndex ~= math.floor(slotIndex) then
		reject("WaterSlot", player, "malformed slotIndex")
		return
	end

	GardenService.WaterSlot(player, plotIndex, slotIndex)
end

-- ===== HarvestSlot =====

function GardenService.HarvestSlot(player: Player, slotIndex: number)
	local data = DataService.GetData(player)
	if data == nil then
		reject("HarvestSlot", player, "no active profile")
		return
	end

	if slotIndex < 1 or slotIndex > data.UnlockedSlots then
		reject("HarvestSlot", player, `slot {slotIndex} out of range/locked`)
		return
	end

	local slot = data.Slots[slotIndex]
	if slot == nil or slot.SeedId == nil then
		reject("HarvestSlot", player, `slot {slotIndex} is empty`)
		return
	end

	if GardenService.EffectiveProgress(slot, os.time()) < 1 then
		reject("HarvestSlot", player, `slot {slotIndex} is not ready`)
		return
	end

	local seedId = slot.SeedId

	slot.SeedId = nil
	slot.PlantedAt = nil
	slot.GrowDuration = nil
	slot.WateredUntil = nil

	data.Plants[seedId] = (data.Plants[seedId] or 0) + 1

	local grimoireEntry = data.Grimoire[seedId]
	if grimoireEntry == nil then
		grimoireEntry = { DiscoveredAt = 0, Harvested = 0 }
		data.Grimoire[seedId] = grimoireEntry
	end
	grimoireEntry.Harvested += 1

	data.Stats.TotalHarvests += 1

	DataService.MarkDirty(player)
end

local function onHarvestSlot(player: Player, ...: any)
	if not checkRateLimit(player, "HarvestSlot") then
		return
	end

	local slotIndex = ...
	if type(slotIndex) ~= "number" or slotIndex ~= math.floor(slotIndex) then
		reject("HarvestSlot", player, "malformed slotIndex")
		return
	end

	GardenService.HarvestSlot(player, slotIndex)
end

local function onPlayerRemoving(player: Player)
	rateState[player] = nil
end

function GardenService.Init()
	buildPlotCache()

	Remotes.PlantSeed.OnServerEvent:Connect(onPlantSeed)
	Remotes.WaterSlot.OnServerEvent:Connect(onWaterSlot)
	Remotes.HarvestSlot.OnServerEvent:Connect(onHarvestSlot)

	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return GardenService
