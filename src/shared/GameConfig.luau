--!strict
-- Global tunables. No magic numbers in logic files - everything lives here.

export type GameConfig = {
	STARTING_GOLD: number,
	STARTING_SLOTS: number,
	MAX_SLOTS: number,
	WATER_MULT: number,
	WATER_DURATION: number,
	WATER_RANGE: number,
	PROMPT_MAX_DISTANCE: number,
	RATE_LIMIT_PER_SECOND: number,
	SLOT_COSTS: { [number]: number },
	DATA_VERSION: number,
}

local GameConfig: GameConfig = {
	STARTING_GOLD = 0,
	STARTING_SLOTS = 6,
	MAX_SLOTS = 24,

	WATER_MULT = 1.25, -- growth speed multiplier while a slot is watered
	WATER_DURATION = 600, -- seconds a single water application lasts
	WATER_RANGE = 20, -- studs a player must be within to water a slot (owner included)
	PROMPT_MAX_DISTANCE = 10, -- ProximityPrompt activation distance on soil slots

	RATE_LIMIT_PER_SECOND = 5, -- max client->server garden remote calls per player per second

	-- Cost (gold) to unlock the Nth soil slot, for N in 7..24 (slots 1-6 are free/starting).
	-- Placeholder curve (~1.3x per slot) - tune in playtest per BUILD_GUIDE §2.5.
	SLOT_COSTS = {
		[7] = 400,
		[8] = 500,
		[9] = 700,
		[10] = 900,
		[11] = 1150,
		[12] = 1500,
		[13] = 1950,
		[14] = 2500,
		[15] = 3250,
		[16] = 4250,
		[17] = 5500,
		[18] = 7200,
		[19] = 9350,
		[20] = 12150,
		[21] = 15750,
		[22] = 20500,
		[23] = 26650,
		[24] = 34650,
	},

	DATA_VERSION = 1,
}

return GameConfig
