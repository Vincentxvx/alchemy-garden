--!strict
-- ~40 hidden brewing recipes. Key = the two parent ids (owned harvested Plants, §2.3) sorted
-- alphabetically and joined with "+" - see GetResult, the only place that ordering matters.
-- Every one of the 33 T2-T6 hybrids (PlantConfig) is reachable from this table; Legendary/Mythic
-- results require hybrid parents themselves (chains 3+ deep), matching BUILD_GUIDE Appendix B.
-- Undefined pairs are NOT an error here: GetResult simply returns nil and the caller
-- (AlchemyService, Phase 5) falls back to Sproutling + 1 Research Note. We deliberately do not
-- publish this table in-game (§2.3) - the community hunting combos is the retention meta.

export type RecipeMap = { [string]: string }

local function sortedKey(a: string, b: string): string
	if a <= b then
		return `{a}+{b}`
	end
	return `{b}+{a}`
end

-- ~35% of random Tier-1 x Tier-1 pairs (13 of the 36 possible, including self-pairs) resolve
-- to a real hybrid; the rest of the table leans on Tier-2 shop seeds so higher tiers don't feel
-- purely like a T1 lookup table.
local Recipes: RecipeMap = {
	-- ===== Tier 2 hybrids (6) =====
	[sortedKey("Glowcap", "Glowcap")] = "Twinshine",
	[sortedKey("Dewroot", "Thornrose")] = "Coppercress",
	[sortedKey("Mooncress", "Thornrose")] = "Bramblewick",
	[sortedKey("Frostfern", "Mooncress")] = "Palefrond",
	[sortedKey("Emberlily", "Glowcap")] = "Cinderpuff",
	[sortedKey("Dewroot", "Frostfern")] = "Mistleaf",

	-- ===== Tier 3 hybrids (10) =====
	[sortedKey("Emberlily", "Frostfern")] = "Mistrose",
	[sortedKey("Glowcap", "Mooncress")] = "Gloomcap",
	[sortedKey("Emberlily", "Thornrose")] = "Sablethorn",
	[sortedKey("Duskpetal", "Sunbud")] = "Prismbud",
	[sortedKey("Mooncress", "Sparkvine")] = "Wispvine",
	[sortedKey("Dewroot", "Mooncress")] = "Marrowroot",
	[sortedKey("Puffshroom", "Sunbud")] = "Suncrown",
	[sortedKey("Dewroot", "Honeybell")] = "Tidebloom",
	[sortedKey("Emberlily", "Tanglevine")] = "Ashfern",
	[sortedKey("Honeybell", "Puffshroom")] = "Chimebell",

	-- ===== Tier 4 hybrids (8) =====
	[sortedKey("Mooncress", "Sunbud")] = "Eclipsebell", -- sun+moon
	[sortedKey("Sparkvine", "Thornrose")] = "Stormbriar",
	[sortedKey("Sparkvine", "Tanglevine")] = "Ironbloom",
	[sortedKey("Mooncress", "Puffshroom")] = "Starcress",
	[sortedKey("Duskpetal", "Frostfern")] = "Voidpetal",
	[sortedKey("Dewroot", "Puffshroom")] = "Frostlily",
	[sortedKey("Duskpetal", "Glowcap")] = "Crystalcap",
	[sortedKey("Duskpetal", "Tanglevine")] = "Dreamvine",

	-- ===== Tier 5 hybrids (6) - both parents must be hybrids =====
	[sortedKey("Eclipsebell", "Stormbriar")] = "AuroraFern",
	[sortedKey("Cinderpuff", "Suncrown")] = "Phoenixbud",
	[sortedKey("Marrowroot", "Sablethorn")] = "MoonwellRose",
	[sortedKey("Tidebloom", "Wispvine")] = "LeviathanKelp",
	[sortedKey("Bramblewick", "Palefrond")] = "SylvanHeart",
	[sortedKey("Ashfern", "Prismbud")] = "CometOrchid",

	-- ===== Tier 6 hybrids (3) - both parents must be Tier-5 hybrids =====
	[sortedKey("AuroraFern", "SylvanHeart")] = "WorldtreeSapling",
	[sortedKey("CometOrchid", "MoonwellRose")] = "GenesisBloom",
	[sortedKey("LeviathanKelp", "Phoenixbud")] = "AlchemistsRose",

	-- ===== Alternate paths (7) - some species have a second recipe =====
	[sortedKey("Frostfern", "Honeybell")] = "Coppercress",
	[sortedKey("Emberlily", "Puffshroom")] = "Cinderpuff",
	[sortedKey("Sunbud", "Tanglevine")] = "Suncrown",
	[sortedKey("Dewroot", "Tanglevine")] = "Tidebloom",
	[sortedKey("Honeybell", "Tanglevine")] = "Chimebell",
	[sortedKey("Duskpetal", "Sparkvine")] = "Wispvine",
	[sortedKey("Puffshroom", "Tanglevine")] = "Frostlily",
}

local function GetResult(a: string, b: string): string?
	return Recipes[sortedKey(a, b)]
end

return {
	Recipes = Recipes,
	GetResult = GetResult,
}
