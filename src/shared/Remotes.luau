--!strict
-- Single source of truth for all RemoteEvents. Server creates them under
-- ReplicatedStorage.Remotes on require; client waits for the same folder.
-- Remotes contract: BUILD_GUIDE.md §3.5.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local REMOTE_NAMES = {
	-- Client -> Server
	"PlantSeed",
	"WaterSlot",
	"HarvestSlot",
	"BuySeed",
	"SellPlant",
	"BuySlot",
	"StartBrew",
	"CollectBrew",
	"ClaimStreak",
	"ClaimQuest",
	"GiftSeed",
	-- Server -> Client
	"StateSync",
	"Notify",
	"Discovery",
}

export type RemotesTable = { [string]: RemoteEvent }

local Remotes: RemotesTable = {}

if RunService:IsServer() then
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"

	for _, name in REMOTE_NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end

	folder.Parent = ReplicatedStorage
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")

	for _, name in REMOTE_NAMES do
		Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
	end
end

return Remotes
