--!strict
-- Shop screen: grid of the 12 shop seeds (PlantConfig entries with a SeedCost). Milestone-
-- gated ones (ShopUnlock set, not yet met) render greyed out with a lock hint instead of
-- Buy buttons. Buy 1x/5x fire BuySeed - the server is the only source of truth on price/
-- eligibility, this UI only reflects what it already knows from the last StateSync.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local PlantConfig = require(ReplicatedStorage.Shared.PlantConfig)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local Components = require(script.Parent.Components)
local UIController = require(script.Parent.Parent.Controllers.UIController)

local LOCKED_SURFACE = Color3.fromRGB(214, 209, 199)

local Shop = {}

-- Stable ordering: shop seeds sorted by Tier then Name so the grid doesn't reshuffle.
local shopSeedIds: { string } = {}
for seedId, def in PlantConfig do
	if def.SeedCost ~= nil then
		table.insert(shopSeedIds, seedId)
	end
end
table.sort(shopSeedIds, function(a, b)
	local defA, defB = PlantConfig[a], PlantConfig[b]
	if defA.Tier ~= defB.Tier then
		return defA.Tier < defB.Tier
	end
	return defA.Name < defB.Name
end)

type CardEntry = {
	Root: Frame,
	LockLabel: TextLabel,
	Buy1: TextButton,
	Buy5: TextButton,
}

local cardsById: { [string]: CardEntry } = {}

local function buildCard(parent: Instance, seedId: string, layoutOrder: number)
	local def = PlantConfig[seedId]

	local card = Instance.new("Frame")
	card.Name = seedId
	card.LayoutOrder = layoutOrder
	card.BackgroundColor3 = UITheme.Colors.Surface
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = def.Color
	stroke.Thickness = 3
	stroke.Parent = card

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.Size = UDim2.fromScale(1, 0.35)
	swatch.BackgroundColor3 = def.Color
	swatch.BorderSizePixel = 0
	swatch.Parent = card

	local swatchCorner = Instance.new("UICorner")
	swatchCorner.CornerRadius = UITheme.CornerRadius
	swatchCorner.Parent = swatch

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.fromScale(1, 0.18)
	nameLabel.Position = UDim2.fromScale(0, 0.35)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.Name
	nameLabel.Font = UITheme.Font
	nameLabel.TextColor3 = UITheme.Colors.Ink
	nameLabel.TextScaled = true
	nameLabel.Parent = card

	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "Cost"
	costLabel.Size = UDim2.fromScale(1, 0.15)
	costLabel.Position = UDim2.fromScale(0, 0.53)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = `🪙 {def.SeedCost}`
	costLabel.Font = UITheme.Font
	costLabel.TextColor3 = UITheme.Colors.Ink
	costLabel.TextScaled = true
	costLabel.Parent = card

	local lockLabel = Instance.new("TextLabel")
	lockLabel.Name = "LockHint"
	lockLabel.Size = UDim2.fromScale(1, 0.32)
	lockLabel.Position = UDim2.fromScale(0, 0.68)
	lockLabel.BackgroundTransparency = 1
	lockLabel.Text = ""
	lockLabel.Font = UITheme.Font
	lockLabel.TextColor3 = UITheme.Colors.Ink
	lockLabel.TextScaled = true
	lockLabel.Visible = false
	lockLabel.Parent = card

	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.Size = UDim2.fromScale(1, 0.32)
	buttonRow.Position = UDim2.fromScale(0, 0.68)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = card

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0.06, 0)
	rowLayout.Parent = buttonRow

	local buy1 = Components.MakeButton({
		Name = "Buy1",
		Text = "Buy 1",
		Size = UDim2.fromScale(0.45, 1),
		Color = UITheme.Colors.Secondary,
		OnActivated = function()
			Remotes.BuySeed:FireServer(seedId, 1)
		end,
	})
	buy1.Parent = buttonRow

	local buy5 = Components.MakeButton({
		Name = "Buy5",
		Text = "Buy 5",
		Size = UDim2.fromScale(0.45, 1),
		Color = UITheme.Colors.Secondary,
		OnActivated = function()
			Remotes.BuySeed:FireServer(seedId, 5)
		end,
	})
	buy5.Parent = buttonRow

	card.Parent = parent

	cardsById[seedId] = { Root = card, LockLabel = lockLabel, Buy1 = buy1, Buy5 = buy5 }
end

local function refreshLocks(data: Types.PlayerData)
	local discovered = data.Stats.Discovered

	for seedId, card in cardsById do
		local def = PlantConfig[seedId]
		local locked = def.ShopUnlock ~= nil and discovered < (def.ShopUnlock :: number)

		card.Buy1.Visible = not locked
		card.Buy5.Visible = not locked
		card.LockLabel.Visible = locked

		if locked then
			card.LockLabel.Text = `🔒 Unlocks at {def.ShopUnlock} discovered`
			card.Root.BackgroundColor3 = LOCKED_SURFACE
		else
			card.Root.BackgroundColor3 = UITheme.Colors.Surface
		end
	end
end

function Shop.Init()
	local panel = Components.MakePanel({
		Name = "ShopPanel",
		Title = "Seed Shop",
	})

	local grid = Instance.new("ScrollingFrame")
	grid.Name = "Grid"
	grid.Size = UDim2.fromScale(1, 1)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 8
	grid.CanvasSize = UDim2.fromScale(0, 0)
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.Parent = panel.Content

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromScale(0.31, 0.28)
	layout.CellPadding = UDim2.fromScale(0.02, 0.03)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	for i, seedId in shopSeedIds do
		buildCard(grid, seedId, i)
	end

	UIController.RegisterScreen("Shop", { Frame = panel.Frame })
	UIController.OnDataChanged(refreshLocks)
end

return Shop
