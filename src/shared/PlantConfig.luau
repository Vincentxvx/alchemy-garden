--!strict
-- TEMPORARY 4-species stub for Phase 2 (garden state machine) testing only.
-- Full 46-species table (BUILD_GUIDE.md Appendix B) replaces this wholesale in Phase 3 -
-- do not extend this table piecemeal.

export type PlantDef = {
	Name: string,
	Tier: number,
	SeedCost: number,
	SellValue: number,
	GrowDuration: number, -- seconds, base duration before water multiplier
	MeshFamily: string,
	Color: Color3,
}

export type PlantConfig = { [string]: PlantDef }

-- Keys are the species/seed id used throughout PlayerData (Seeds, Plants, Grimoire, Slots.SeedId).
local PlantConfig: PlantConfig = {
	Sunbud = {
		Name = "Sunbud",
		Tier = 1,
		SeedCost = 25,
		SellValue = 45,
		GrowDuration = 60,
		MeshFamily = "Flower",
		Color = Color3.fromRGB(255, 200, 40),
	},
	Dewroot = {
		Name = "Dewroot",
		Tier = 1,
		SeedCost = 25,
		SellValue = 45,
		GrowDuration = 60,
		MeshFamily = "Vine",
		Color = Color3.fromRGB(90, 190, 210),
	},
	Glowcap = {
		Name = "Glowcap",
		Tier = 2,
		SeedCost = 100,
		SellValue = 190,
		GrowDuration = 300,
		MeshFamily = "Mushroom",
		Color = Color3.fromRGB(120, 230, 160),
	},
	Emberlily = {
		Name = "Emberlily",
		Tier = 1,
		SeedCost = 25,
		SellValue = 45,
		GrowDuration = 60,
		MeshFamily = "Flower",
		Color = Color3.fromRGB(230, 90, 60),
	},
}

return PlantConfig
