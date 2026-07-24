# PROJECT.md — Living Project Summary

> **Purpose:** This is the single condensed file that brings any AI session up to speed without re-explaining everything or pasting the whole codebase. Keep it current. At the end of a work session, ask the AI to update it with what changed, then save the result.
>
> **How to use:** Paste this file (or attach it) at the start of a new chat. Keep it tighter than the raw code it replaces — if it bloats, trim it.
>
> **Last updated:** 2026-07-24 by Vincent

---

## 1. Snapshot

- **What we're building:** **Alchemy Garden** (working title; leading store name "Grow an Alchemy Garden 🌿") — a Roblox incremental garden game: plants grow offline, cross-breed at an alchemy table via ~40 hidden recipes into 45 discoverable species, tracked in a Grimoire collection log; 6-player neighborhood servers.
- **Primary track:** Roblox — this game.
- **Secondary track:** Fortnite (UEFN) — **paused** until Roblox v1.0 ships (research complete, see `fortnite.md`).
- **Current phase:** Phase 2 complete. Design + 12-phase plan locked in `BUILD_GUIDE.md` v1.1 (Solo Edition); all Claude Code prompts in `PROMPTS.md`.
- **Next milestone:** Phase 3 — economy: shop, selling, full 46-species content table (default model). Full PlantConfig + RecipeConfig, EconomyService buy/sell/slots.

---

## 2. Team & Roles

- **Vincent** — solo: all systems/code via Claude Code, plus Studio work, asset passes, store art, community, and launch.
- **Mio** — stepped away from the project (2026-07-05). Guide and scope restructured to solo; door stays open.
- **Working split:** single-track — code first each phase, small asset pass after; big art batch in Phase 10.

---

## 3. Roblox — Game State

### 3.1 The Game
- **Title / working name:** Alchemy Garden ("Grow an Alchemy Garden 🌿" leading candidate — final pick in Phase 11)
- **Genre / core loop:** plant → (offline) grow/water → harvest → sell for gold **or** brew 2 plants → discover hybrids → fill Grimoire → unlock slots/seeds/perks → plant better
- **Place/Universe ID:** private dev place published under the Greenhouse Studio group (Phase 0)

### 3.2 Systems (all planned — statuses flip as phases land)

| System | Status | Notes |
|---|---|---|
| Repo / toolchain / dev place | **done — Phase 0** | `Vincentxvx/alchemy-garden` on GitHub, origin connected; Rojo serving/syncing; both boot prints confirmed; private dev place published under Greenhouse Studio group, MaxPlayers 6, StreamingEnabled on |
| Data/saving (ProfileStore) | **done — Phase 1** | vendored, session-locked; schema per BUILD_GUIDE App. A; `DataService` live |
| leaderstats | **done — Phase 1** | Gold, Discovered, kept in sync via DataService |
| Plot assignment | **done — Phase 1** | 6 plots/server via `PlotService`, CollectionService tags, per-player plot claim/release, sign write-back |
| Garden growth | **done — Phase 2** | timestamp-based state machine (`GardenService`): plant/water/harvest, offline growth verified, 1 Hz visual loop + ProximityPrompt state, stub 4-species `PlantConfig` (replaced Phase 3) |
| Economy / shop | planned — Phase 3 | 46-species PlantConfig + ~40 RecipeConfig |
| GUI suite | planned — Phase 4 | mobile-first, scale-only sizing, component factory |
| Alchemy + Grimoire | planned — Phase 5 | hidden recipes, milestones, Research Notes pity |
| Streaks / quests / welcome-back | planned — Phase 6 | UTC date keys |
| Social (Friend Boost, gifting) | planned — Phase 7 | co-play = ranking signal |
| FTUE + telemetry | planned — Phase 8 | first reward ≤10s; AnalyticsService funnel |
| Monetization | planned — Phase 9 | 3 passes, 5 products, starter pack; **no paid RNG** |
| Polish / performance | planned — Phase 10 | art batch week; 30 fps low-end target |
| Publish / launch | planned — Phase 11 | Friday launch, Up & Coming push |

### 3.3 Script Map (source of truth: BUILD_GUIDE §3.3 — ✅ = implemented)

| Script | Type | Location in Studio | Responsibility | Status |
|---|---|---|---|---|
| `init.server` | Script | ServerScriptService.Server | boots Services in order (Data, Plot, Garden) | ✅ Phase 1 (Garden wired Phase 2) |
| `Lib/ProfileStore` | ModuleScript | …Server.Lib | vendored save library | ✅ Phase 0 |
| `DataService` | ModuleScript | …Server.Services | profiles, template, leaderstats, StateSync, AdjustGold | ✅ Phase 1 |
| `PlotService` | ModuleScript | …Server.Services | plot claim/release, sign write-back | ✅ Phase 1 |
| `GardenService` | ModuleScript | …Server.Services | plant/water/harvest state machine, EffectiveProgress math, 1 Hz visual loop, rate limiting | ✅ Phase 2 |
| `EconomyService` | ModuleScript | …Server.Services | buy/sell/slots, perks | planned — Phase 3 |
| `AlchemyService` | ModuleScript | …Server.Services | brewing, discovery, milestones | planned — Phase 5 |
| `QuestService` / `StreakService` | ModuleScripts | …Server.Services | daily loops | planned — Phase 6 |
| `SocialService` | ModuleScript | …Server.Services | Friend Boost, gifting | planned — Phase 7 |
| `MonetizationService` | ModuleScript | …Server.Services | passes, idempotent receipts | planned — Phase 9 |
| `TelemetryService` | ModuleScript | …Server.Services | onboarding funnel events | planned — Phase 8 |
| `init.client` + `Controllers/` | LocalScripts/Modules | StarterPlayerScripts.Client | `GardenController` fires plant/water/harvest remotes, local pop tween on harvest | ✅ Phase 2 (GardenController only — UI/Onboarding controllers still planned Phase 4+) |
| `UI/` (Components, HUD, Shop, …) | ModuleScripts | …Client.UI | all screens | planned — Phase 4 |
| `Shared/Types.luau` | ModuleScript | ReplicatedStorage.Shared | PlayerData types, Version = 1 | ✅ Phase 1 |
| `Shared/GameConfig.luau` | ModuleScript | ReplicatedStorage.Shared | tunables (slots, water mult, etc.) | ✅ Phase 1 |
| `Shared/Remotes.luau` | ModuleScript | ReplicatedStorage.Shared | sole source for all remotes | ✅ Phase 1 (garden remotes live Phase 2; shop/alchemy/social remotes wired as their phases land) |
| `Shared/PlantConfig.luau` | ModuleScript | ReplicatedStorage.Shared | species data | 🟡 Phase 2 stub (4 species) — full 46-species table replaces it Phase 3 |

### 3.4 Conventions (locked decisions)
- **Naming:** PascalCase modules/Services, camelCase locals; `--!strict` where practical.
- **Luau style:** `task.wait()`/`task.spawn()` only; no deprecated APIs; `os.time()` timestamps, `os.date("!%Y-%m-%d")` date keys.
- **Remotes:** created/fetched **only** via `Shared/Remotes.luau`; every C→S remote validated + rate-limited; server-authoritative everything.
- **Folder structure:** Rojo maps `src/server|shared|client` → Server/Shared/Client containers; Rojo owns code containers — scripts are never edited in Studio; Team Create stays off.
- **Data schema:** typed `PlayerData` (BUILD_GUIDE App. A), `Version` field + migration required for any shape change.
- **Asset contract:** `Assets/Plants/<Id>/Stage1..4` with code fallback; tags `GardenPlot`, `SoilSlot`, `SeedShop`, `AlchemyTable`, `QuestBoard`.
- **Growth math (locked, Phase 2):** derived not simulated — progress = elapsed effective time / GrowDuration, watered periods count ×1.25; only `PlantedAt`, `GrowDuration`, `WateredUntil` stored; offline growth falls out of the math for free; one 1 Hz server loop updates visuals only for slots of players present in that server.
- **Output format:** complete files only, one phase per Claude Code session, stylua+selene before commit, PROJECT.md updated after each phase.

---

## 4. Fortnite (UEFN) — Map State

**Track paused** until Roblox v1.0 ships. Research complete (`fortnite.md`); Verse learning continues low-priority. No island started.

### 4.1–4.4
| Element | Status | Notes |
|---|---|---|
| Everything | on hold | revisit after Roblox launch + first content waves |

---

## 5. Decision Log

- **2026-07-04** — Chose the **alchemy garden** concept over 4 alternatives — best risk-adjusted fit for a small team: systems-heavy, art-light, aligned with the 2026 retention-window algorithm (see `roblox.md`).
- **2026-07-04** — Locked v1.0 scope in BUILD_GUIDE: 46 species / 6 tiers, hidden recipes, 6-player servers, 12-phase plan; **deferred** trading, rebirth, pets, console; **never** paid randomized outcomes (loot-box legal risk).
- **2026-07-04** — **ProfileStore (vendored)** over hand-rolled DataStores — session locking eliminates dupe/data-loss class of bugs.
- **2026-07-04** — **Group ownership from Phase 0** — payout eligibility has waiting periods.
- **2026-07-05** — **Project goes solo** (Mio stepped away) — BUILD_GUIDE → v1.1 Solo Edition: art cut to 5 mesh families (20 models), store art via in-Studio screenshots, 1 launch clip/day, Team Create dropped; timeline held at 6–9 weeks via these cuts.
- **2026-07-05** — Pressure-washer game **parked indefinitely** — served its purpose as the toolchain learning project; patterns carry over.
- **2026-07-XX** — **Phase 0 shipped** — repo, Rojo, Greenhouse Studio group + private dev place, boot scripts verified.
- **2026-07-24** — **Phase 1 shipped** — data foundation + plot assignment (ProfileStore-backed DataService, PlotService, Types/GameConfig/Remotes scaffolding). Definition of Done met per BUILD_GUIDE (2-client plot/sign assignment, gold persistence across rejoin, Selene clean).
- **2026-07-24** — **Phase 2 shipped** — full garden state machine (`GardenService`): plant/water/harvest, watered-time growth math (EffectiveProgress), offline progression confirmed (stop/wait/resume test), 1 Hz stage-visual loop with ProximityPrompt state text, per-remote rate limiting, client `GardenController` with harvest pop tween. Temporary 4-species `PlantConfig` stub in place — full 46-species table is Phase 3. Definition of Done met (solo + 2-client tests, offline growth verified, rejected cross-plot harvest logs without erroring, mesh fallback confirmed).

---

## 6. Open Questions / Blockers

- [ ] Final store title (leading: "Grow an Alchemy Garden 🌿") — decide by Phase 11
- [ ] Recruit 3–5 playtesters (friends/Discord) before Phase 10
- [ ] Set up a second Roblox account friended to main for Phase 7 social testing
- [ ] Set up MCP bridge (`@chrrxs/robloxstudio-mcp`) so Claude Code can manipulate Studio Workspace directly

---

## 7. Parking Lot (ideas, not now)

- Trading system (v1.2 — only if D7 ≥ 10%; needs scam-safe UI)
- Transmutation / rebirth (v1.1, weeks 3–4 post-launch)
- Pets, seasonal events, premium currency, console support
- Fern / Tree-sapling / Aquatic mesh families (post-launch species waves)
- UEFN tycoon island (after Roblox v1.0)
- Pressure-washer game revival
