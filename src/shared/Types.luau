--!strict
-- Exported Luau types for PlayerData. Schema source of truth: BUILD_GUIDE.md Appendix A.
-- Any shape change requires bumping GameConfig.DATA_VERSION and writing a migration.

export type PlotSlot = {
	SeedId: string?,
	PlantedAt: number?, -- os.time()
	GrowDuration: number?, -- seconds (base, pre-multipliers)
	WateredUntil: number?, -- os.time(); 1.25x growth while now < this
}

export type QuestEntry = { Id: string, Progress: number, Goal: number, Claimed: boolean }

export type PlayerData = {
	Version: number,
	Gold: number,
	ResearchNotes: number,
	Slots: { PlotSlot }, -- index = SlotIndex (1..24)
	UnlockedSlots: number, -- starts 6
	Seeds: { [string]: number },
	Plants: { [string]: number },
	Grimoire: { [string]: { DiscoveredAt: number, Harvested: number } },
	Hints: { [string]: boolean }, -- recipe keys revealed by Research Notes
	Brew: { PlantA: string, PlantB: string, ReadyAt: number }?,
	Streak: { Count: number, LastClaimDate: string }, -- "YYYY-MM-DD" UTC
	Quests: { DateKey: string, List: { QuestEntry } },
	FTUE: { Step: number, Done: boolean },
	Purchases: { [string]: boolean }, -- receipt ids + one-time flags
	Stats: {
		TotalHarvests: number,
		TotalBrews: number,
		Discovered: number,
		FirstJoin: number,
		LastSeen: number,
	},
}

return {}
