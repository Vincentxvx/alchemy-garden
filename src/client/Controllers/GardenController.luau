--!strict
-- Fires garden remotes from ProximityPrompt triggers; plays local harvest pop feedback.
-- No seed-picker UI exists yet (Phase 4) - planting an empty slot auto-picks the first
-- owned seed unless SetSelectedSeed has been called (the hook future UI wires into).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local SOIL_SLOT_TAG = "SoilSlot"
local GARDEN_PLOT_TAG = "GardenPlot"
local POP_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local localPlayer = Players.LocalPlayer

local GardenController = {}

local latestData: Types.PlayerData? = nil
local selectedSeedId: string? = nil
local ownPlotSlotParts: { [number]: BasePart } = {}

local function findPlotIndex(instance: Instance): number?
	local current: Instance? = instance
	while current ~= nil do
		local index = current:GetAttribute("PlotIndex")
		if type(index) == "number" then
			return index
		end
		current = current.Parent
	end
	return nil
end

local function rebuildOwnPlotCache()
	table.clear(ownPlotSlotParts)

	local plotIndex = localPlayer:GetAttribute("PlotIndex")
	if type(plotIndex) ~= "number" then
		return
	end

	for _, plot in CollectionService:GetTagged(GARDEN_PLOT_TAG) do
		if plot:GetAttribute("PlotIndex") == plotIndex then
			for _, descendant in plot:GetDescendants() do
				if
					descendant:IsA("BasePart")
					and CollectionService:HasTag(descendant, SOIL_SLOT_TAG)
				then
					local slotIndex = descendant:GetAttribute("SlotIndex")
					if type(slotIndex) == "number" then
						ownPlotSlotParts[slotIndex] = descendant
					end
				end
			end
			break
		end
	end
end

local function firstOwnedSeed(data: Types.PlayerData): string?
	for seedId, count in data.Seeds do
		if count > 0 then
			return seedId
		end
	end
	return nil
end

local function playHarvestPop(slotIndex: number)
	local part = ownPlotSlotParts[slotIndex]
	if part == nil then
		return
	end

	local pop = Instance.new("Part")
	pop.Name = "HarvestPop"
	pop.Shape = Enum.PartType.Ball
	pop.Size = Vector3.new(1, 1, 1)
	pop.Color = Color3.fromRGB(255, 230, 120)
	pop.Material = Enum.Material.Neon
	pop.Anchored = true
	pop.CanCollide = false
	pop.CanQuery = false
	pop.CastShadow = false
	pop.Position = part.Position + Vector3.new(0, part.Size.Y / 2 + 0.5, 0)
	pop.Parent = Workspace

	local tween = TweenService:Create(pop, POP_TWEEN_INFO, {
		Size = Vector3.new(2.5, 2.5, 2.5),
		Transparency = 1,
	})
	tween.Completed:Connect(function()
		pop:Destroy()
	end)
	tween:Play()
end

-- A slot that flips from occupied -> empty between two StateSyncs was just harvested
-- (Plant is the only way a slot fills, Harvest the only way it clears, in Phase 2 scope).
local function onStateSync(data: Types.PlayerData)
	local previous = latestData
	latestData = data

	if previous ~= nil then
		for slotIndex, prevSlot in previous.Slots do
			local newSlot = data.Slots[slotIndex]
			if prevSlot.SeedId ~= nil and newSlot ~= nil and newSlot.SeedId == nil then
				playHarvestPop(slotIndex)
			end
		end
	end
end

function GardenController.SetSelectedSeed(seedId: string?)
	selectedSeedId = seedId
end

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	if player ~= localPlayer then
		return
	end

	local part = prompt.Parent
	if
		part == nil
		or not part:IsA("BasePart")
		or not CollectionService:HasTag(part, SOIL_SLOT_TAG)
	then
		return
	end

	local slotIndex = part:GetAttribute("SlotIndex")
	if type(slotIndex) ~= "number" then
		return
	end

	if prompt.ActionText == "Plant" then
		local seedId = selectedSeedId
		if seedId == nil and latestData ~= nil then
			seedId = firstOwnedSeed(latestData)
		end
		if seedId == nil then
			return
		end
		Remotes.PlantSeed:FireServer(slotIndex, seedId)
	elseif prompt.ActionText == "Water" then
		local plotIndex = findPlotIndex(part)
		if plotIndex == nil then
			return
		end
		Remotes.WaterSlot:FireServer(plotIndex, slotIndex)
	elseif prompt.ActionText == "Harvest" then
		Remotes.HarvestSlot:FireServer(slotIndex)
	end
end

function GardenController.Init()
	Remotes.StateSync.OnClientEvent:Connect(onStateSync)
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	localPlayer:GetAttributeChangedSignal("PlotIndex"):Connect(rebuildOwnPlotCache)
	rebuildOwnPlotCache()
end

return GardenController
