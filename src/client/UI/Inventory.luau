--!strict
-- Inventory screen: Seeds tab (view-only counts) and Plants tab (Sell 1x/all). Owned-item
-- sets change on every purchase/harvest/sale, so the row list is simplest rebuilt in full on
-- every StateSync rather than diffed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local PlantConfig = require(ReplicatedStorage.Shared.PlantConfig)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local Components = require(script.Parent.Components)
local UIController = require(script.Parent.Parent.Controllers.UIController)

-- Fixed row height (list content, not chrome) - comfortably clears the 44px touch floor and
-- avoids a circular Scale-vs-AutomaticSize dependency inside a variable-length list.
local ROW_HEIGHT = 56

local Inventory = {}

type Tab = "Seeds" | "Plants"

local activeTab: Tab = "Seeds"
local listFrame: ScrollingFrame? = nil
local seedsTabButton: TextButton? = nil
local plantsTabButton: TextButton? = nil

local function sortedOwnedIds(counts: { [string]: number }): { string }
	local ids = {}
	for id, count in counts do
		if count > 0 then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local defA, defB = PlantConfig[a], PlantConfig[b]
		if defA.Tier ~= defB.Tier then
			return defA.Tier < defB.Tier
		end
		return defA.Name < defB.Name
	end)
	return ids
end

local function clearList(frame: ScrollingFrame)
	for _, child in frame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function buildRow(
	parent: Instance,
	seedId: string,
	count: number,
	layoutOrder: number,
	sellable: boolean
)
	local def = PlantConfig[seedId]

	local row = Instance.new("Frame")
	row.Name = seedId
	row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	row.BackgroundColor3 = UITheme.Colors.Surface
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = row

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.fromScale(0.08, 0.7)
	swatch.Position = UDim2.fromScale(0.02, 0.15)
	swatch.BackgroundColor3 = def.Color
	swatch.BorderSizePixel = 0
	swatch.Parent = row

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UITheme.CornerRadius
	swatchCorner.Parent = swatch

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(0.45, 1)
	label.Position = UDim2.fromScale(0.12, 0)
	label.BackgroundTransparency = 1
	label.Text = `{def.Name}  x{count}`
	label.Font = UITheme.Font
	label.TextColor3 = UITheme.Colors.Ink
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	if sellable then
		local buttonRow = Instance.new("Frame")
		buttonRow.Name = "Buttons"
		buttonRow.Size = UDim2.fromScale(0.4, 0.8)
		buttonRow.Position = UDim2.fromScale(0.58, 0.1)
		buttonRow.BackgroundTransparency = 1
		buttonRow.Parent = row

		local rowLayout = Instance.new("UIListLayout")
		rowLayout.FillDirection = Enum.FillDirection.Horizontal
		rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		rowLayout.Padding = UDim.new(0.06, 0)
		rowLayout.Parent = buttonRow

		local sell1 = Components.MakeButton({
			Name = "Sell1",
			Text = "Sell 1",
			Size = UDim2.fromScale(0.45, 1),
			Color = UITheme.Colors.Secondary,
			OnActivated = function()
				Remotes.SellPlant:FireServer(seedId, 1)
			end,
		})
		sell1.Parent = buttonRow

		local sellAll = Components.MakeButton({
			Name = "SellAll",
			Text = "Sell All",
			Size = UDim2.fromScale(0.45, 1),
			Color = UITheme.Colors.Secondary,
			OnActivated = function()
				Remotes.SellPlant:FireServer(seedId, "all")
			end,
		})
		sellAll.Parent = buttonRow
	end

	row.Parent = parent
end

local function refreshTabButtons()
	if seedsTabButton ~= nil then
		seedsTabButton.BackgroundColor3 = if activeTab == "Seeds"
			then UITheme.Colors.Primary
			else UITheme.Colors.Secondary
	end
	if plantsTabButton ~= nil then
		plantsTabButton.BackgroundColor3 = if activeTab == "Plants"
			then UITheme.Colors.Primary
			else UITheme.Colors.Secondary
	end
end

local function render(data: Types.PlayerData)
	local frame = listFrame
	if frame == nil then
		return
	end
	clearList(frame)

	if activeTab == "Seeds" then
		local ids = sortedOwnedIds(data.Seeds)
		for i, seedId in ids do
			buildRow(frame, seedId, data.Seeds[seedId], i, false)
		end
	else
		local ids = sortedOwnedIds(data.Plants)
		for i, seedId in ids do
			buildRow(frame, seedId, data.Plants[seedId], i, true)
		end
	end

	refreshTabButtons()
end

local function setTab(tab: Tab)
	activeTab = tab
	local data = UIController.GetData()
	if data ~= nil then
		render(data)
	else
		refreshTabButtons()
	end
end

function Inventory.Init()
	local panel = Components.MakePanel({
		Name = "InventoryPanel",
		Title = "Inventory",
	})

	local tabs = Instance.new("Frame")
	tabs.Name = "Tabs"
	tabs.Size = UDim2.fromScale(1, 0.12)
	tabs.BackgroundTransparency = 1
	tabs.Parent = panel.Content

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabsLayout.Padding = UDim.new(0.04, 0)
	tabsLayout.Parent = tabs

	local seedsTab = Components.MakeButton({
		Name = "SeedsTab",
		Text = "Seeds",
		Size = UDim2.fromScale(0.45, 1),
		Color = UITheme.Colors.Primary,
		OnActivated = function()
			setTab("Seeds")
		end,
	})
	seedsTab.Parent = tabs
	seedsTabButton = seedsTab

	local plantsTab = Components.MakeButton({
		Name = "PlantsTab",
		Text = "Plants",
		Size = UDim2.fromScale(0.45, 1),
		Color = UITheme.Colors.Secondary,
		OnActivated = function()
			setTab("Plants")
		end,
	})
	plantsTab.Parent = tabs
	plantsTabButton = plantsTab

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 0.86)
	list.Position = UDim2.fromScale(0, 0.14)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 8
	list.CanvasSize = UDim2.fromScale(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel.Content

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	listFrame = list

	UIController.RegisterScreen("Inventory", { Frame = panel.Frame })
	UIController.OnDataChanged(render)
end

return Inventory
