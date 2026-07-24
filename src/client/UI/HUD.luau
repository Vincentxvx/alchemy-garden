--!strict
-- Always-visible chrome: gold pill (top-left, animated count-up), a quest tracker stub
-- (Phase 6 fills this in), and the bottom-right screen-toggle button stack. Not a
-- UIController "screen" itself - it never opens/closes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local Components = require(script.Parent.Components)
local UIController = require(script.Parent.Parent.Controllers.UIController)

local HUD = {}

local goldLabel: TextLabel? = nil
local lastGold: number? = nil

local function buildGoldPill(parent: ScreenGui)
	local pill = Instance.new("Frame")
	pill.Name = "GoldPill"
	pill.Size = UDim2.fromScale(0.32, 0.06)
	pill.Position = UDim2.fromScale(0.02, 0.02)
	pill.BackgroundColor3 = UITheme.Colors.Surface
	pill.BorderSizePixel = 0
	pill.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = pill

	local stroke = Instance.new("UIStroke")
	stroke.Color = UITheme.Colors.Primary
	stroke.Thickness = 2
	stroke.Parent = pill

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.03, 0)
	layout.Parent = pill

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(0.25, 0.7)
	icon.BackgroundTransparency = 1
	icon.Text = "🪙"
	icon.Font = UITheme.Font
	icon.TextScaled = true
	icon.Parent = pill

	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.Size = UDim2.fromScale(0.6, 0.7)
	label.BackgroundTransparency = 1
	label.Text = "0"
	label.Font = UITheme.Font
	label.TextColor3 = UITheme.Colors.Ink
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = pill

	goldLabel = label
end

local function buildQuestStub(parent: ScreenGui)
	local stub = Instance.new("Frame")
	stub.Name = "QuestTrackerStub"
	stub.Size = UDim2.fromScale(0.44, 0.045)
	stub.Position = UDim2.fromScale(0.02, 0.1)
	stub.BackgroundColor3 = UITheme.Colors.Surface
	stub.BackgroundTransparency = 0.3
	stub.BorderSizePixel = 0
	stub.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = stub

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Quests coming soon"
	label.Font = UITheme.Font
	label.TextColor3 = UITheme.Colors.Ink
	label.TextScaled = true
	label.Parent = stub
end

type StackButtonDef = { Name: string, Icon: string, Screen: string }

local STACK_BUTTONS: { StackButtonDef } = {
	{ Name = "ShopButton", Icon = "🌱", Screen = "Shop" },
	{ Name = "InventoryButton", Icon = "🎒", Screen = "Inventory" },
	{ Name = "GrimoireButton", Icon = "📖", Screen = "Grimoire" },
	{ Name = "AlchemyButton", Icon = "🧪", Screen = "Alchemy" },
}

local function buildButtonStack(parent: ScreenGui)
	local stack = Instance.new("Frame")
	stack.Name = "ButtonStack"
	stack.Size = UDim2.fromScale(0.16, 0.42)
	stack.AnchorPoint = Vector2.new(1, 1)
	stack.Position = UDim2.fromScale(0.98, 0.96)
	stack.BackgroundTransparency = 1
	stack.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0.05, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = stack

	for i, def in STACK_BUTTONS do
		local button = Components.MakeButton({
			Name = def.Name,
			Text = def.Icon,
			Size = UDim2.fromScale(1, 0.22),
			Color = UITheme.Colors.Primary,
			LayoutOrder = i,
			OnActivated = function()
				UIController.Toggle(def.Screen)
			end,
		})
		button.Parent = stack
	end
end

local function onDataChanged(data: Types.PlayerData)
	local label = goldLabel
	if label == nil then
		return
	end

	local newGold = data.Gold
	if lastGold == nil or lastGold == newGold then
		label.Text = tostring(newGold)
	else
		Components.Tweens.CountUp(label, lastGold, newGold, 0.4)
	end
	lastGold = newGold
end

function HUD.Init()
	local gui = UIController.GetGui()
	buildGoldPill(gui)
	buildQuestStub(gui)
	buildButtonStack(gui)

	UIController.OnDataChanged(onDataChanged)
end

return HUD
