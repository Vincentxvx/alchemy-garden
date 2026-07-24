--!strict
-- Profiles, template, StateSync, leaderstats. Public API used by every other Service.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ProfileStoreLib = require(script.Parent.Parent.Lib.ProfileStore)
local Types = require(ReplicatedStorage.Shared.Types)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

type PlayerData = Types.PlayerData
type PlayerProfile = ProfileStoreLib.Profile<PlayerData>

local SYNC_INTERVAL = 1 -- seconds; max StateSync frequency per player
local STUDIO_TEST_GOLD = 10000 -- Studio-only playtesting convenience; never runs outside RunService:IsStudio()

local Template: PlayerData = {
	Version = GameConfig.DATA_VERSION,
	Gold = GameConfig.STARTING_GOLD,
	ResearchNotes = 0,
	Slots = {},
	UnlockedSlots = GameConfig.STARTING_SLOTS,
	Seeds = {},
	Plants = {},
	Grimoire = {},
	Hints = {},
	Brew = nil,
	Streak = { Count = 0, LastClaimDate = "" },
	Quests = { DateKey = "", List = {} },
	FTUE = { Step = 1, Done = false },
	Purchases = {},
	Stats = { TotalHarvests = 0, TotalBrews = 0, Discovered = 0, FirstJoin = 0, LastSeen = 0 },
}

-- Pre-fill every slot so the array has no numeric gaps (ProfileStore requirement);
-- slots beyond UnlockedSlots simply stay empty until purchased.
for i = 1, GameConfig.MAX_SLOTS do
	Template.Slots[i] = {}
end

local PlayerProfileStore = ProfileStoreLib.New("PlayerData", Template)

local DataService = {}

local profiles: { [Player]: PlayerProfile } = {}
local lastSync: { [Player]: number } = {}
local pendingSync: { [Player]: boolean } = {}

local function getOrCreateLeaderstats(player: Player): Folder
	local existing = player:FindFirstChild("leaderstats")
	if existing and existing:IsA("Folder") then
		return existing
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Parent = leaderstats

	local discovered = Instance.new("IntValue")
	discovered.Name = "Discovered"
	discovered.Parent = leaderstats

	leaderstats.Parent = player

	return leaderstats
end

local function updateLeaderstats(player: Player, data: PlayerData)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats == nil then
		return
	end

	local gold = leaderstats:FindFirstChild("Gold")
	if gold and gold:IsA("IntValue") then
		gold.Value = data.Gold
	end

	local discovered = leaderstats:FindFirstChild("Discovered")
	if discovered and discovered:IsA("IntValue") then
		discovered.Value = data.Stats.Discovered
	end
end

function DataService.GetProfile(player: Player): PlayerProfile?
	return profiles[player]
end

function DataService.GetData(player: Player): PlayerData?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end
	return profile.Data
end

-- Fires an immediate full-snapshot StateSync and keeps leaderstats in lockstep.
function DataService.Sync(player: Player)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end

	updateLeaderstats(player, data)
	Remotes.StateSync:FireClient(player, data)
	lastSync[player] = os.clock()
end

-- Call after any mutation; throttles to <=1 StateSync/sec per player. A mutation that lands
-- inside the throttle window is never silently dropped - it schedules one trailing catch-up
-- sync for when the window reopens (a no-op if one is already pending), so the client is
-- guaranteed to see the latest data within SYNC_INTERVAL even under rapid-fire actions
-- (e.g. spamming Shop's Buy buttons) instead of displaying whatever the last delivered
-- snapshot happened to be.
function DataService.MarkDirty(player: Player)
	local last = lastSync[player]
	if last == nil or os.clock() - last >= SYNC_INTERVAL then
		DataService.Sync(player)
		return
	end

	if pendingSync[player] then
		return
	end
	pendingSync[player] = true

	task.delay(SYNC_INTERVAL - (os.clock() - last), function()
		pendingSync[player] = nil
		if profiles[player] ~= nil then
			DataService.Sync(player)
		end
	end)
end

-- Clamps to >=0 and syncs. The only place gold should be mutated from.
function DataService.AdjustGold(player: Player, delta: number)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end

	data.Gold = math.max(0, data.Gold + delta)
	DataService.MarkDirty(player)
end

local function onPlayerAdded(player: Player)
	local profile = PlayerProfileStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Your data session failed to start (already active elsewhere). Please rejoin.")
		return
	end

	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		lastSync[player] = nil
		pendingSync[player] = nil
		player:Kick("Your data session has ended. Please rejoin.")
	end)

	if player.Parent ~= Players then
		-- Player left while the profile was loading.
		profile:EndSession()
		return
	end

	profiles[player] = profile
	profile:AddUserId(player.UserId)

	local data = profile.Data
	data.Stats.LastSeen = os.time()
	if data.Stats.FirstJoin == 0 then
		data.Stats.FirstJoin = os.time()
	end

	if RunService:IsStudio() then
		data.Gold = STUDIO_TEST_GOLD
	end

	getOrCreateLeaderstats(player)
	DataService.Sync(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
	profiles[player] = nil
	lastSync[player] = nil
	pendingSync[player] = nil
end

function DataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return DataService
