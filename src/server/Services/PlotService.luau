--!strict
-- Assigns each joining player the lowest-index free GardenPlot; releases on leave.
-- Plots are Studio-owned world geometry, tagged per BUILD_GUIDE.md §3.7:
-- GardenPlot (+PlotIndex attribute), optionally containing a SurfaceGui name sign.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local GARDEN_PLOT_TAG = "GardenPlot"

local PlotService = {}

local plotByPlayer: { [Player]: Instance } = {}
local ownerByPlot: { [number]: Player } = {}

local function getPlotIndex(plot: Instance): number?
	local index = plot:GetAttribute("PlotIndex")
	if type(index) == "number" then
		return index
	end
	return nil
end

local function findSignLabel(plot: Instance): TextLabel?
	for _, descendant in plot:GetDescendants() do
		if descendant:IsA("SurfaceGui") then
			local label = descendant:FindFirstChildWhichIsA("TextLabel", true)
			if label ~= nil then
				return label
			end
		end
	end
	return nil
end

local function setSign(plot: Instance, text: string)
	local label = findSignLabel(plot)
	if label ~= nil then
		label.Text = text
	end
end

local function findFreePlot(): Instance?
	local plots = CollectionService:GetTagged(GARDEN_PLOT_TAG)

	table.sort(plots, function(a, b)
		local indexA = getPlotIndex(a) or math.huge
		local indexB = getPlotIndex(b) or math.huge
		return indexA < indexB
	end)

	for _, plot in plots do
		local index = getPlotIndex(plot)
		if index ~= nil and ownerByPlot[index] == nil then
			return plot
		end
	end

	return nil
end

function PlotService.GetPlot(player: Player): Instance?
	return plotByPlayer[player]
end

function PlotService.GetOwner(plotIndex: number): Player?
	return ownerByPlot[plotIndex]
end

local function onPlayerAdded(player: Player)
	local plot = findFreePlot()
	if plot == nil then
		warn(`[PlotService] No free GardenPlot available for {player.Name}`)
		return
	end

	local index = getPlotIndex(plot)
	if index == nil then
		warn(`[PlotService] GardenPlot missing a valid PlotIndex attribute`)
		return
	end

	ownerByPlot[index] = player
	plotByPlayer[player] = plot
	-- Replicated attribute so clients can identify their own plot without a remote (GardenController).
	player:SetAttribute("PlotIndex", index)

	setSign(plot, player.DisplayName)
end

local function onPlayerRemoving(player: Player)
	local plot = plotByPlayer[player]
	if plot == nil then
		return
	end

	local index = getPlotIndex(plot)
	if index ~= nil and ownerByPlot[index] == player then
		ownerByPlot[index] = nil
	end

	setSign(plot, "")
	plotByPlayer[player] = nil
	player:SetAttribute("PlotIndex", nil)
end

function PlotService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlotService
