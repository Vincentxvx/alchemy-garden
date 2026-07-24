--!strict
-- Design tokens locked in CLAUDE.md "UI style (locked, Phase 4)" - the single source every
-- UI file pulls from. Change the look here (and in CLAUDE.md), never per-file.

export type UITheme = {
	Font: Enum.Font,
	CornerRadius: UDim,
	MinTouchSize: number,
	Colors: {
		Primary: Color3,
		Secondary: Color3,
		Surface: Color3,
		Ink: Color3,
		White: Color3,
	},
}

local UITheme: UITheme = {
	Font = Enum.Font.FredokaOne,
	CornerRadius = UDim.new(0, 16),
	MinTouchSize = 44,
	Colors = {
		Primary = Color3.fromRGB(255, 176, 59), -- Gold
		Secondary = Color3.fromRGB(94, 186, 88), -- Leaf
		Surface = Color3.fromRGB(255, 248, 231), -- Parchment
		Ink = Color3.fromRGB(59, 41, 28), -- Soil brown text
		White = Color3.fromRGB(255, 255, 255),
	},
}

return UITheme
