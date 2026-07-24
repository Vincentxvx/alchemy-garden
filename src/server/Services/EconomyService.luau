--!strict
-- Buy/sell/slots. Prices come only from PlantConfig/GameConfig - never trust client-sent
-- amounts. Design: BUILD_GUIDE.md §3.5 (remotes contract) + §3.6 (security rules).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlantConfig = require(ReplicatedStorage.Shared.PlantConfig)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local SOIL_SLOT_TAG = "SoilSlot"
local RATE_LIMIT_WINDOW = 1 -- seconds

local EconomyService = {}

-- player -> remote name -> current fixed-window rate limit counter
local rateState: { [Player]: { [string]: { count: number, windowStart: number } } } = {}

-- Client gets no explanation (BUILD_GUIDE §3.6: "reject silently, log loudly") - only the
-- server console records why an action was refused.
local function reject(remoteName: string, player: Player, reason: string)
	warn(`[EconomyService] {remoteName} rejected for {player.Name}: {reason}`)
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

-- ===== BuySeed =====

function EconomyService.BuySeed(player: Player, seedId: string, qty: number)
	local plantDef = PlantConfig[seedId]
	if plantDef == nil then
		reject("BuySeed", player, `unknown seedId "{seedId}"`)
		return
	end

	if plantDef.SeedCost == nil then
		reject("BuySeed", player, `"{seedId}" is hybrid-only, not sold in the shop`)
		return
	end

	local data = DataService.GetData(player)
	if data == nil then
		reject("BuySeed", player, "no active profile")
		return
	end

	if plantDef.ShopUnlock ~= nil and data.Stats.Discovered < plantDef.ShopUnlock then
		reject(
			"BuySeed",
			player,
			`"{seedId}" is milestone-locked (needs {plantDef.ShopUnlock} discovered, has {data.Stats.Discovered})`
		)
		return
	end

	local cost = plantDef.SeedCost * qty
	if data.Gold < cost then
		reject("BuySeed", player, `insufficient gold ({data.Gold} < {cost})`)
		return
	end

	DataService.AdjustGold(player, -cost)
	data.Seeds[seedId] = (data.Seeds[seedId] or 0) + qty

	DataService.MarkDirty(player)
end

local function onBuySeed(player: Player, ...: any)
	if not checkRateLimit(player, "BuySeed") then
		return
	end

	local seedId, qty = ...
	if type(seedId) ~= "string" then
		reject("BuySeed", player, "malformed seedId")
		return
	end
	if type(qty) ~= "number" or qty ~= math.floor(qty) or qty < 1 then
		reject("BuySeed", player, "malformed qty")
		return
	end

	EconomyService.BuySeed(player, seedId, qty)
end

-- ===== SellPlant =====

function EconomyService.SellPlant(player: Player, seedId: string, qty: number | "all")
	local plantDef = PlantConfig[seedId]
	if plantDef == nil then
		reject("SellPlant", player, `unknown seedId "{seedId}"`)
		return
	end

	local data = DataService.GetData(player)
	if data == nil then
		reject("SellPlant", player, "no active profile")
		return
	end

	local owned = data.Plants[seedId] or 0

	local sellQty: number
	if qty == "all" then
		sellQty = owned
	else
		sellQty = qty :: number
		if sellQty > owned then
			reject("SellPlant", player, `sells {sellQty} {seedId} but only owns {owned}`)
			return
		end
	end

	if sellQty <= 0 then
		reject("SellPlant", player, `nothing to sell for "{seedId}"`)
		return
	end

	local proceeds = plantDef.SellValue * sellQty
	data.Plants[seedId] = owned - sellQty

	DataService.AdjustGold(player, proceeds)
	DataService.MarkDirty(player)
end

local function onSellPlant(player: Player, ...: any)
	if not checkRateLimit(player, "SellPlant") then
		return
	end

	local seedId, qty = ...
	if type(seedId) ~= "string" then
		reject("SellPlant", player, "malformed seedId")
		return
	end

	if qty == "all" then
		EconomyService.SellPlant(player, seedId, "all")
		return
	end

	if type(qty) ~= "number" or qty ~= math.floor(qty) or qty < 1 then
		reject("SellPlant", player, "malformed qty")
		return
	end

	EconomyService.SellPlant(player, seedId, qty)
end

-- ===== BuySlot =====

local function findSoilSlotPart(plot: Instance, slotIndex: number): BasePart?
	for _, descendant in plot:GetDescendants() do
		if descendant:IsA("BasePart") and CollectionService:HasTag(descendant, SOIL_SLOT_TAG) then
			if descendant:GetAttribute("SlotIndex") == slotIndex then
				return descendant
			end
		end
	end
	return nil
end

function EconomyService.BuySlot(player: Player)
	local data = DataService.GetData(player)
	if data == nil then
		reject("BuySlot", player, "no active profile")
		return
	end

	local nextSlot = data.UnlockedSlots + 1
	if nextSlot > GameConfig.MAX_SLOTS then
		reject("BuySlot", player, `already at max slots ({GameConfig.MAX_SLOTS})`)
		return
	end

	local cost = GameConfig.SLOT_COSTS[nextSlot]
	if cost == nil then
		reject("BuySlot", player, `no SLOT_COSTS entry for slot {nextSlot}`)
		return
	end

	if data.Gold < cost then
		reject("BuySlot", player, `insufficient gold ({data.Gold} < {cost})`)
		return
	end

	DataService.AdjustGold(player, -cost)
	data.UnlockedSlots = nextSlot

	local plot = PlotService.GetPlot(player)
	if plot == nil then
		warn(
			`[EconomyService] BuySlot granted for {player.Name} but they own no plot (no world part to reveal)`
		)
	else
		local slotPart = findSoilSlotPart(plot, nextSlot)
		if slotPart == nil then
			warn(
				`[EconomyService] BuySlot granted for {player.Name} but slot {nextSlot} has no world part`
			)
		else
			slotPart.Transparency = 0
			slotPart.CanCollide = true
		end
	end

	DataService.MarkDirty(player)
end

local function onBuySlot(player: Player)
	if not checkRateLimit(player, "BuySlot") then
		return
	end

	EconomyService.BuySlot(player)
end

local function onPlayerRemoving(player: Player)
	rateState[player] = nil
end

function EconomyService.Init()
	Remotes.BuySeed.OnServerEvent:Connect(onBuySeed)
	Remotes.SellPlant.OnServerEvent:Connect(onSellPlant)
	Remotes.BuySlot.OnServerEvent:Connect(onBuySlot)

	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return EconomyService
