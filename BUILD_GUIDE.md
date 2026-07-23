# ALCHEMY GARDEN — Build & Publish Guide v1.1 · Solo Edition

**Project:** Alchemy Garden (working title) — Roblox / Luau
**Team:** Vincent — solo build (systems & code via Claude Code, plus Studio/art passes)
**Target:** publishable v1.0 in **6–9 weeks** part-time (solo, art-light scope — §2.7 and Appendix C)
**Companion docs:** `PROJECT.md` (living status) · `PROMPTS.md` (all prompts, repo root) · `CLAUDE.md` (Appendix D of this file — copy into repo root)

---

## 0. How to use this guide

1. **One phase = one Claude Code session.** Each phase below has a copy-paste prompt (all collected in `PROMPTS.md` too). Run it, test against the *Definition of Done*, commit, move on. Don't start two phases in one session.
2. **Code track first, asset pass second.** Every phase lists both. Land the systems, pass the Definition of Done, then do the phase's small asset pass — or batch several into Phase 10. The asset contract in §3.7 guarantees code always runs with placeholder visuals, so art never blocks shipping.
3. **Model choice:** default model for most phases; the heavier model only for Phase 2 and Phase 5 (the two genuinely architectural ones). Keep small-fix prompts constrained ("minimal change, don't refactor").
4. **After each phase:** update `PROJECT.md` (script map, decision log, status), small commit, push.
5. **Scope discipline:** if you're tempted to add something mid-phase, check the Deferred list (§2.6). If it's there, it waits. This is the #1 way two-person projects die.

---

## 1. What we're building — and why this can win in 2026

**Pitch:** A cozy incremental garden where you plant magical seeds, come back to harvests, and cross-breed mature plants at an alchemy table to **discover hidden hybrid species**. Fill the Grimoire (collection log), climb six rarity tiers, and garden in small 6-player neighborhood servers with friends.

**Core loop:**

```
PLANT ──▶ wait / water ──▶ HARVEST ──▶ SELL (gold) ──▶ buy better seeds, slots ──▶ PLANT
                                └─▶ BREW (2 plants) ──▶ DISCOVER hybrid ──▶ GRIMOIRE ──▶ milestone perks
```

**Why this maps onto the current algorithm (per our research doc `roblox.md`):**

| Algorithm signal (Jun 2026) | Our mechanic |
|---|---|
| Play days per user (D1, D2–7, D8–28 windows) | Offline growth — plants finish while away; streaks; daily quests |
| Play-through rate / low first-play bounce | First harvest ≤10s from spawn, first reward ≤60s, zero tutorial text |
| Intentional co-play days | 6-player neighborhoods, friend-watering buff, +gold "Friend Boost" while a friend is in the server |
| 60-min daily credit cap | Designed for multiple short sessions/day, not marathon grinding |
| Off-platform virality | Hidden recipes → discovery clips, community recipe-hunting, wiki meta |

**v1.0 success gates (do not spend a single Robux on ads before these):**
- D1 retention ≥ 20%
- First-play bounce rate < ~30%
- Average session ≥ 8 minutes
- Funnel: ≥70% of new players reach "first harvest", ≥40% reach "first brew"

---

## 2. Game design spec (v1.0 — locked)

### 2.1 First ten minutes (the experience we're engineering)

- **0:00** — Spawn facing *your* plot. One golden plant is already grown and glowing. A single floating prompt: **Harvest**.
- **0:10** — Tap → burst of coins, +50 Gold, satisfying pop. First win delivered.
- **0:20** — Arrow beam to the seed stall. First seed is free (auto-granted). Prompt: **Plant**.
- **0:40** — Seed planted; starter seeds grow in 45–60s so the player *watches* the first cycle complete.
- **1:40** — Second harvest. Shop now affordable. Player buys 2–3 seeds, fills slots.
- **3–5 min** — With two mature plants in inventory, the Alchemy Table pulses. First brew → **"You discovered Twinshine!"** full-screen celebration, Grimoire opens showing 2/45 with silhouettes of the rest.
- **5–10 min** — Player is planting multi-slot, experimenting with combos, sees locked seeds and Grimoire milestones. The "come back later" contract is visible: a 20-minute plant is growing when they consider leaving.

### 2.2 Garden & growth

- **Servers:** 6 players max. Six garden plots arranged around a central plaza (shop, alchemy table, quest board). Everyone sees everyone's garden — ambient social proof.
- **Slots:** each player starts with **6 soil slots**, expandable to **24** (gold + milestones + one game pass).
- **Growth model:** timestamp-based. A plant is `PlantedAt + GrowDuration` vs `os.time()`. No running timers per plant → **offline growth is free** and servers do near-zero work. A 1 Hz server loop updates visuals for plots in that server only.
- **Stages:** 4 visual stages (sprout → young → mature → ready). Ready plants sparkle.
- **Watering:** watering a slot sets `WateredUntil = now + 600`; growth accrues at **1.25×** while watered. Watering a *neighbor's* slot gives **both** players the buff (co-play hook).
- **Fertilizer:** consumable, instantly advances growth by 30 min. Earned from quests/streaks; also sold as a dev product.

### 2.3 Alchemy (the differentiator)

- Brew consumes **2 harvested plants from inventory** (not live plots — simpler, and lets players brew from the stockpile).
- Brew takes 60s at the Alchemy Table (one brew active at a time in v1).
- Result lookup in `RecipeConfig`: **~40 deterministic hidden recipes**. Defined pair → hybrid seed of that species. Undefined pair → a **Sproutling** (common filler species) + 1 *Research Note*.
- Research Notes are a pity/hint system: every 5 notes unlocks a silhouette hint on a random undiscovered recipe in the Grimoire.
- **First-time discovery** (per player): full-screen celebration + server-wide announcement ("Vincent discovered Stormbriar!"). First-time-ever *in this server session* gets confetti at the table — clippable moment.
- We deliberately **do not publish the recipe list**. The community hunting combos in Discord/wiki is the retention meta.

### 2.4 Grimoire (collection log)

- 45 species (+ Sproutling) across 6 tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic.
- Tracks: discovered (with date), total harvested per species.
- **Milestones:** 10 discovered → +2 slots · 20 → permanent +10% gold · 30 → +2 slots · 40 → permanent +15% gold · 45 → exclusive "Alchemist's Rose" seed + golden trophy for the plot.

### 2.5 Economy (starting values — tune in playtest)

| Tier | Seed cost | Grow time | Sell value | Rationale |
|---|---|---|---|---|
| 1 Common | 25 | 60s | 45 | Watch-it-grow onboarding |
| 2 Uncommon | 100 | 5 min | 190 | First session depth |
| 3 Rare | 400 | 20 min | 850 | "One more cycle" |
| 4 Epic | 1,600 | 1 h | 3,600 | Session-bridging |
| 5 Legendary | 6,400 | 4 h | 15,500 | Come-back-later contract |
| 6 Mythic | 25,600 | 12 h | 68,000 | Daily appointment |

Balance rules: next meaningful purchase always visible; affordable within 1–3 harvest cycles early, 1–2 sessions mid-game. Hybrids sell ~20% better per hour than shop seeds of the same tier — breeding must be economically correct, not just collectible.

### 2.6 Deferred to post-launch (write it on the wall)

**v1.1:** Transmutation (rebirth/prestige) · seasonal event framework
**v1.2:** Full trading (needs scam-safe UI — big) · pets
**Later:** console support, premium currency, music system
**Never:** paid randomized outcomes (loot boxes). Legal risk (Colvin v. Roblox settlement) and it poisons trust. All paid items are deterministic.

### 2.7 Content scope v1.0

- 12 shop seeds (Tiers 1–2; six unlock via Grimoire milestones)
- 33 hybrid species (Tiers 2–6) + Sproutling
- ~40 recipes (every hybrid reachable; some species have 2 recipes)
- Species use **5 mesh families** with recolors/size variants → 5 families × 4 stages = 20 models (Studio primitives/unions or free Creator Store meshes are fine), not 180. Three more families arrive as post-launch content waves.

---

## 3. Architecture & conventions

### 3.1 Repo & tooling

New repo, fresh start: `~/RobloxGames/alchemy-garden`. The pressure-washer repo stays parked as-is — it was the right learning scaffold, and its raycast/validation patterns carry over here.

**Connect the GitHub remote in Phase 0, first thing** — last session ended with the push failing because `origin` was never added. One command does repo + remote + push:

```bash
gh repo create Vincentxvx/alchemy-garden --private --source=. --remote=origin --push
# or manually:
# git remote add origin git@github.com:Vincentxvx/alchemy-garden.git && git push -u origin main
```

Toolchain is identical to the current setup: Rokit (Rojo 7.6.1, Wally, Selene, StyLua), VS Code + Luau LSP, Studio via Vinegar, MCP bridge for Studio introspection.

### 3.2 `default.project.json` (complete file)

```json
{
  "name": "alchemy-garden",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

Same mapping as before: `src/server` → ServerScriptService.Server, `src/client` → StarterPlayerScripts.Client, `src/shared` → ReplicatedStorage.Shared. Rojo owns **only code containers** — the map/Workspace belongs to Studio.

### 3.3 Final file tree (the whole game — ~30 files)

```
src/
├─ server/
│  ├─ init.server.luau          -- boots all Services in order
│  ├─ Lib/
│  │  └─ ProfileStore.luau      -- vendored (session-locked saves)
│  └─ Services/
│     ├─ DataService.luau       -- profiles, template, accessors, leaderstats
│     ├─ PlotService.luau       -- assigns players to garden plots
│     ├─ GardenService.luau     -- plant/water/harvest state machine
│     ├─ EconomyService.luau    -- buy/sell, gold mutations
│     ├─ AlchemyService.luau    -- brewing, recipes, discovery
│     ├─ QuestService.luau      -- daily quests
│     ├─ StreakService.luau     -- login streaks
│     ├─ SocialService.luau     -- friend watering, gifting, Friend Boost
│     ├─ MonetizationService.luau -- passes, products, receipts
│     └─ TelemetryService.luau  -- onboarding funnel + economy events
├─ client/
│  ├─ init.client.luau          -- boots all Controllers
│  ├─ Controllers/
│  │  ├─ GardenController.luau  -- prompts, plot visuals, client VFX
│  │  ├─ UIController.luau      -- screen routing, state cache
│  │  └─ OnboardingController.luau -- FTUE arrows/highlights
│  └─ UI/
│     ├─ Components.luau        -- button/panel/tween factory
│     ├─ HUD.luau  Shop.luau  Inventory.luau  Grimoire.luau
│     ├─ AlchemyUI.luau  QuestTracker.luau  DailyRewards.luau
│     ├─ WelcomeBack.luau  Notifications.luau
└─ shared/
   ├─ GameConfig.luau           -- tunables (buffs, prices of slots, etc.)
   ├─ Types.luau                -- all exported Luau types
   ├─ PlantConfig.luau          -- 46 species (data-driven content)
   ├─ RecipeConfig.luau         -- ~40 recipes
   ├─ QuestConfig.luau  RewardConfig.luau
   ├─ Remotes.luau              -- creates/returns all remotes (sole source)
   └─ Util.luau                 -- format numbers, table helpers
```

### 3.4 Player data schema v1 (source of truth — Appendix A has the full typed version)

Gold, ResearchNotes, Slots (array of `{SeedId?, PlantedAt?, GrowDuration?, WateredUntil?}`), UnlockedSlots, Seeds `{[id]: count}`, Plants `{[id]: count}`, Grimoire `{[id]: {DiscoveredAt, Harvested}}`, Brew (one active), Streak `{Count, LastClaimDate}`, Quests `{DateKey, List}`, FTUE `{Step, Done}`, Purchases, Passes, Stats, **Version** (schema migrations — never change shape without bumping and migrating).

### 3.5 Remotes contract (all remotes live in `Shared/Remotes.luau`, nowhere else)

| Remote | Dir | Payload | Server validates |
|---|---|---|---|
| PlantSeed | C→S | slotIndex, seedId | owns plot, slot in range+empty, has seed, rate ≤5/s |
| WaterSlot | C→S | plotIndex, slotIndex | slot occupied, distance ≤20 studs, rate ≤5/s (any plot — friend watering) |
| HarvestSlot | C→S | slotIndex | owns plot, plant is ready |
| BuySeed / SellPlant | C→S | id, qty | gold/stock, qty>0 integer, id exists, unlocked |
| BuySlot | C→S | — | gold, below cap |
| StartBrew / CollectBrew | C→S | plantA, plantB / — | owns both plants, no active brew / brew ready |
| ClaimStreak / ClaimQuest | C→S | — / questId | eligibility server-side only |
| GiftSeed | C→S | targetUserId, seedId | IsFriendsWith, 1/day, both in server |
| StateSync | S→C | full PlayerData snapshot | sent on join + throttled after mutations |
| Notify / Discovery | S→C(all) | toast payloads | — |

### 3.6 Security rules (non-negotiable, restated from CLAUDE.md)

1. The client **requests**; the server **decides**. Every price, timer, inventory count, and reward is computed server-side.
2. Validate type, range, and ownership of every remote argument. Reject silently, log loudly.
3. Per-player rate limits on all remotes (simple timestamp map).
4. ProcessReceipt must be idempotent (store granted receipt IDs in the profile).
5. Session-locking via ProfileStore = no duplication via rejoin races.

### 3.7 Asset contract (so art never blocks code)

- Plant models live at `ReplicatedStorage/Assets/Plants/<SpeciesId>/Stage1..Stage4` (Models, pivot at soil level).
- **Code falls back** to a scaled default sprout mesh for any missing species/stage — deliver art in waves whenever you feel like a Studio session.
- Plots: tag each garden plot `GardenPlot` (Tag Editor) with attribute `PlotIndex` (1–6). Each plot contains 24 parts named `SoilSlot` with attribute `SlotIndex` (1–24); slots 7–24 start invisible (code toggles).
- Plaza props: shop stall (`Tag: SeedShop`), alchemy table (`Tag: AlchemyTable`), quest board (`Tag: QuestBoard`).
- VFX/SFX dropped under `ReplicatedStorage/Assets/FX/<Name>`; code looks them up by name, skips if absent.

### 3.8 Solo workflow

- **Code = Git + Rojo.** `rojo serve` while you work. Rojo owns the three code containers and will overwrite manual edits — so scripts are only ever edited in VS Code, never in Studio.
- **World = the same Studio session.** Build Workspace directly. Keep Team Create **off** — it fights Rojo and you don't need it solo.
- Publish after each phase passes its Definition of Done. `PROJECT.md` updated same time.

---

## 4. Phase plan at a glance

| # | Phase | Ships | Est. | Track |
|---|---|---|---|---|
| 0 | Preflight & skeleton | repo, Rojo, empty boot scripts, group, dev place | ½–1 d | setup |
| 1 | Data & plots | ProfileStore saves, plot assignment, leaderstats | 2–3 d | code |
| 2 | Planting & growth | full grow/water/harvest loop, offline growth | 3–4 d | code |
| 3 | Economy | shop, selling, full 46-species config | 2–3 d | code |
| 4 | UI suite v1 | HUD, Shop, Inventory, Grimoire, Alchemy, toasts | 4–6 d | code + UI |
| 5 | Alchemy & Grimoire | brewing, discovery, milestones | 4–5 d | code |
| 6 | Retention layer | streaks, daily quests, welcome-back | 3–4 d | code |
| 7 | Social | friend watering, gifting, Friend Boost, invites | 2–3 d | code |
| 8 | Onboarding & telemetry | scripted first 60s, funnel analytics | 2–3 d | code |
| 9 | Monetization | 3 passes, 5 products, starter pack | 1–2 d | code |
| 10 | Polish & performance | art batch, audio, juice, perf, icon/thumbnails | ~1 wk | art & polish |
| 11 | Publish & launch | store page, questionnaire, launch week | 2–3 d | launch |

**Suggested summer schedule:** W1: 0–2 · W2: 2–3 · W3: 4 · W4: 5 · W5: 6–7 · W6: 8–9 · W7: 10 · W8: 11 + launch · W9: buffer + first patch.

---
## Phase 0 — Preflight & skeleton (½–1 day)

**Goal:** empty-but-running project: Rojo syncing, Git on GitHub, dev place published under a group.

**Vincent:**
1. If the reboot from the environment setup is still pending, do that first.
2. ```bash
   mkdir -p ~/RobloxGames/alchemy-garden && cd ~/RobloxGames/alchemy-garden
   git init -b main
   cp ~/RobloxGames/my-first-game/{rokit.toml,selene.toml,stylua.toml,.gitignore} .
   mkdir -p src/server/{Lib,Services} src/client/{Controllers,UI} src/shared
   ```
3. Create `default.project.json` (§3.2), `CLAUDE.md` (Appendix D), and stub `init.server.luau` / `init.client.luau` that just print a boot line.
4. Vendor ProfileStore: grab `ProfileStore.luau` from `github.com/MadStudioRoblox/ProfileStore` → `src/server/Lib/ProfileStore.luau`. (Why ProfileStore over hand-rolling DataStores: session locking kills the entire class of dupe/data-loss bugs; the tradeoff is one vendored dependency and slightly less learning-by-suffering. Worth it — data loss is the one bug players never forgive.)
5. First commit, then **connect origin** (§3.1 command) — verify with `git remote -v` and check the repo page.
6. `rojo serve` → connect the Studio plugin → confirm the Server/Client boot prints appear in Output.
7. In Studio: File → Publish to Roblox → under the **group** (created in the block below — do that first), name "Alchemy Garden [DEV]", private. Game Settings: MaxPlayers **6**, StreamingEnabled **on**.

**Also in this phase (you):**
1. Create the Roblox **group** (costs 100 Robux). Do this now, not at launch — group payouts and some monetization settings have waiting periods, and group ownership keeps future options (revenue splits, collaborators) open.
2. Spin up a small Discord (channels: announcements, recipe-hunting, bugs). Solo, this is your playtester pool and your second pair of eyes — start collecting people early.
3. Moodboard: pick 3 reference images for "cozy magical garden" (stylized, bright, low-poly). 30 minutes, then stop — deciding the look once beats re-deciding it per prop.

**Definition of done:** repo on GitHub with origin connected · `rojo serve` syncs and both boot scripts print · private dev place exists under the group.
**Commit:** `chore: project skeleton + toolchain`

---

## Phase 1 — Data foundation & plots (2–3 days)

**Goal:** players join, get a session-locked profile and an assigned garden plot; data survives rejoin.

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md first. Scope: data foundation and plot assignment ONLY — no gameplay yet.

Build, as complete files:
1. src/shared/Types.luau — exported Luau types for PlayerData exactly as specified in
   BUILD_GUIDE.md Appendix A (copy the schema faithfully, Version = 1).
2. src/shared/GameConfig.luau — constants: STARTING_GOLD=0, STARTING_SLOTS=6, MAX_SLOTS=24,
   WATER_MULT=1.25, WATER_DURATION=600, SLOT_COSTS table, DATA_VERSION=1.
3. src/shared/Remotes.luau — creates (server) / waits for (client) a Remotes folder in
   ReplicatedStorage with every remote named in BUILD_GUIDE.md §3.5. Single source of truth.
4. src/server/Services/DataService.luau — uses the vendored ProfileStore
   (src/server/Lib/ProfileStore.luau): template from Types, StartSession on join with session
   locking, EndSession on leave, kick on lock failure. Public API: GetProfile(player),
   GetData(player), AdjustGold(player, delta) (clamps ≥0, fires StateSync), MarkDirty/Sync
   helper that throttles full-snapshot StateSync to ≤1/sec per player. Creates leaderstats
   folder with Gold and Discovered IntValues kept in sync.
5. src/server/Services/PlotService.luau — on join, claims the lowest free Workspace plot
   tagged "GardenPlot" (CollectionService), stores the mapping, writes the player's
   DisplayName to a SurfaceGui sign if the plot has one, releases on leave. Public API:
   GetPlot(player), GetOwner(plotIndex).
6. Update src/server/init.server.luau to require Services in order: Data, Plot.

Complete files only. Keep it minimal — nothing outside this scope. After writing, run
stylua and selene and fix warnings.
Test plan: Studio multi-client (2 players) — each gets a distinct plot and sign; leaderstats
visible; give yourself gold via command bar through DataService.AdjustGold; rejoin persists it.
Commit: "feat: data foundation + plot assignment"
```

**Studio pass (you, ~half a day — the code above needs this map):** greybox — 6 plots in a ring around a central plaza; spawn at the plaza edge facing plot 1; placeholder shop stall, alchemy table, quest board (plain parts are fine). Apply the tags/attributes from §3.7 (Tag Editor for tags, Properties → Attributes for indices): 6 × `GardenPlot` with `PlotIndex`, each containing 24 `SoilSlot` parts with `SlotIndex` (a 6×4 grid; build one, duplicate-and-renumber). Skip lighting for now.

**Definition of done:** 2-client test assigns distinct plots with name signs · gold persists across rejoin · no session-lock errors in Output · Selene clean.

---

## Phase 2 — Planting, growth & offline progress (3–4 days) — *heavier model*

**Goal:** the full garden loop: plant → grow through 4 stages → water → harvest, with growth continuing while offline. This is the heart of the game — take the time to get it right.

**Design notes (read before prompting):**
- Growth is **derived, not simulated**: progress = elapsed effective time / GrowDuration, where watered periods count ×1.25. Store only `PlantedAt`, `GrowDuration`, `WateredUntil`. Offline growth then needs zero extra code — it falls out of the math on next evaluation.
- One 1 Hz server loop walks occupied slots *of players in this server* and updates stage visuals + "ready" sparkle. No per-plant timers, no Heartbeat spam.
- Interactions via **ProximityPrompt** per SoilSlot (works great on mobile): empty slot → "Plant", growing → "Water", ready → "Harvest". The server retags prompt ActionText as state changes.

**Vincent — Claude Code prompt (heavier model):**

```text
Read CLAUDE.md and BUILD_GUIDE.md §2.2 + Phase 2 design notes. Scope: the garden state
machine ONLY. No shop, no alchemy, no UI screens.

Build, as complete files:
1. src/shared/PlantConfig.luau — TEMPORARY 4-species stub (Sunbud, Dewroot, Glowcap,
   Emberlily): {Name, Tier, SeedCost, SellValue, GrowDuration, MeshFamily, Color}. Full
   table replaces this in Phase 3.
2. src/server/Services/GardenService.luau — authoritative state machine:
   - PlantSeed(player, slotIndex, seedId): validate per BUILD_GUIDE §3.5, consume seed,
     write slot record, timestamp with os.time().
   - WaterSlot(player, plotIndex, slotIndex): sets/extends WateredUntil. Owner OR any
     player within 20 studs may water (friend-watering lands in Phase 7; allow it now).
   - HarvestSlot(player, slotIndex): only when EffectiveProgress >= 1; clears slot,
     increments Plants[speciesId], Grimoire harvested count, Stats.TotalHarvests.
   - EffectiveProgress(slot, now): pure function implementing the watered-time math —
     put it in the module and unit-test it via comments with worked examples.
   - 1 Hz visual loop: for each occupied slot of present players, set stage model
     (Stage1-4 from ReplicatedStorage/Assets/Plants/<id>/, fallback to a scaled default
     part if missing), sparkle when ready, and keep the slot's ProximityPrompt
     ActionText correct (Plant/Water/Harvest).
   - Per-player rate limiting on all three remotes (≤5/s each).
3. src/client/Controllers/GardenController.luau — fires the remotes from prompt
   Triggered events, plays a local pop/scale tween on successful harvest (listen to
   StateSync diff or a lightweight HarvestOk signal — your call, keep it simple).
4. Wire into init scripts.

Complete files only. Run stylua + selene.
Test plan: solo — plant Sunbud (60s), watch 4 stages, water to confirm speedup, harvest
lands in Plants inventory (print StateSync). Offline growth: plant Glowcap, stop Play,
wait 2 min, Play again — progress advanced. 2-client: watering each other's slots works;
harvesting someone else's plot is rejected.
Commits (separate): "feat: garden state machine", "feat: growth visuals + prompts"
```

**Asset pass (you, ~2 hours, after the code works):** ONE mesh family × 4 stages — a generic flower from Studio parts/unions, ugly is fine — dropped into `Assets/Plants/...` per the contract, so you see the fallback→real-asset path working; a "ready" sparkle ParticleEmitter; a soil-slot texture so slots read clearly from 15 m; a watering-can prop if you're feeling it. Every other family waits for Phase 10.

**Definition of done:** full plant→water→harvest loop in solo and 2-client · offline progression verified · rejected actions log server-side without erroring · mesh fallback works for species without art.

---

## Phase 3 — Economy: shop, selling & full content table (2–3 days)

**Goal:** gold means something. Buy seeds, sell harvests, buy slots — plus the complete 46-species dataset (this is an AI-content task; don't hand-write 46 rows).

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md. Scope: economy + content data. No UI screens yet (command-bar testing).

1. REPLACE src/shared/PlantConfig.luau with the full 46-species table: use the name bank
   and tier curves in BUILD_GUIDE.md Appendix B exactly (12 shop seeds T1-T2 with six
   marked MilestoneLocked, 33 hybrids T2-T6, plus Sproutling). Fields: Name, Tier,
   SeedCost (nil for hybrid-only), SellValue, GrowDuration, MeshFamily, Color,
   ShopUnlock (nil | milestone count). Follow the curve formulas; hybrids sell ~20%
   better per hour than same-tier shop seeds.
2. CREATE src/shared/RecipeConfig.luau — ~40 recipes as { [key]: resultId } where key is
   the two parent ids sorted alphabetically and joined with "+". Every hybrid reachable;
   Legendary/Mythic require hybrid parents (chains). Include a GetResult(a, b) helper.
   Distribute recipes so ~35% of random T1×T1 pairs hit something real.
3. CREATE src/server/Services/EconomyService.luau — BuySeed / SellPlant / BuySlot per
   §3.5 validation, prices ONLY from configs, SellPlant supports qty (including "all"),
   slot purchase uses GameConfig.SLOT_COSTS and flips the SoilSlot visibility.
4. Wire into init. Complete files, stylua + selene.
Test plan: command-bar buy/sell round trip is profitable per the §2.5 table; buying with
insufficient gold rejects; slot purchase reveals slot 7 in-world.
Commit: "feat: economy + full plant/recipe config"
```

**Asset pass:** none — keep momentum on code. Stall dressing and plaza props are batched into Phase 10.

**Definition of done:** buy→plant→harvest→sell profitable and curve-correct · recipe table sanity-checked (spot-test 5 combos via command bar) · Selene clean.

---

## Phase 4 — UI suite v1 (4–6 days, two sessions)

**Goal:** the whole loop playable by touch, on a phone, with zero command-bar. This is the phase where the game starts *feeling* real — and where mobile-first is won or lost.

**Ground rules (from our UI discussion, now binding):** scale-based sizing only; primary buttons bottom corners, ≥44 px touch targets; HUD shows exactly: gold pill, quest tracker stub, and a 4-button bottom-right stack (Shop, Inventory, Grimoire, Alchemy); every press tweens; one font, 2–3 colors, one corner radius (decide before prompting and write the choices into CLAUDE.md so every session uses them).

**Vincent — session A prompt (default model):**

```text
Read CLAUDE.md (note the UI style constants). Scope: UI foundation + HUD + Shop + Inventory.

1. src/client/UI/Components.luau — factory module: MakeButton (auto press-tween, min
   44px touch size), MakePanel (corner, stroke, drop-in title bar + close), Tween presets
   (pop, slideIn, countUp for numbers), MakeToast. All scale-based (UDim2 scale + UIAspect
   or UIListLayout; zero pixel-offset layout).
2. src/client/Controllers/UIController.luau — owns ScreenGui, caches latest StateSync
   snapshot, exposes Open/Close/Toggle per screen (only one main panel open at a time),
   binds the bottom-right button stack.
3. src/client/UI/HUD.luau — gold pill (top-left, animated count-up), bottom-right stack.
4. src/client/UI/Shop.luau — grid of shop seeds from PlantConfig (locked ones greyed with
   milestone hint), buy 1x/5x, fires BuySeed.
5. src/client/UI/Inventory.luau — tabs Seeds/Plants, sell 1x/all from Plants tab.
Complete files, stylua + selene. Test on the Studio device emulator: iPhone SE and a
small Android preset — everything reachable by thumb, nothing clipped.
Commit: "feat: UI foundation + HUD/shop/inventory"
```

**Vincent — session B prompt (default model):**

```text
Scope: remaining screens, wired to existing remotes/state.
1. src/client/UI/Grimoire.luau — 46-cell grid by tier; undiscovered = black silhouette
   (use stage-4 mesh ViewportFrame or a ? card); detail pane; milestone progress track
   along the top (10/20/30/40/45 with reward icons).
2. src/client/UI/AlchemyUI.luau — two plant slots (pick from owned Plants), Brew button,
   60s progress state, Collect state. Opens via ProximityPrompt on the AlchemyTable tag
   OR the HUD button.
3. src/client/UI/Notifications.luau — toast queue + full-screen Discovery celebration
   (name, tier color burst, "NEW!" stamp) with a Continue button.
4. src/client/UI/WelcomeBack.luau — placeholder panel (content in Phase 6).
Complete files, stylua + selene, same device-emulator pass.
Commit: "feat: grimoire + alchemy + notification UI"
```

**Asset pass (you, ~1 hour):** icons — don't draw them; grab a free Creator Store icon pack or use clean text/emoji glyphs for v1 (coin, seed packet, flask, book, scroll). The device-emulator QA sweep is already part of this phase's Definition of Done.

**Definition of done:** entire loop (buy→plant→water→harvest→sell) playable on iPhone SE emulator by touch only · no offset sizing anywhere · discovery celebration triggerable via command bar.

---

## Phase 5 — Alchemy & Grimoire logic (4–5 days) — *heavier model*

**Goal:** the differentiator goes live: brewing, hidden recipes, discovery moments, milestone perks.

**Vincent — Claude Code prompt (heavier model):**

```text
Read CLAUDE.md, BUILD_GUIDE.md §2.3–2.4. Scope: alchemy + grimoire/milestones. UI exists.

1. src/server/Services/AlchemyService.luau —
   - StartBrew(player, plantA, plantB): validates ownership of both (can be same species
     x2), consumes them, writes Brew{PlantA, PlantB, ReadyAt = now + 60}.
   - CollectBrew(player): when ready — result = RecipeConfig.GetResult(a, b);
     defined → grant 1 seed of result + first-time discovery flow;
     undefined → grant 1 Sproutling seed + ResearchNotes += 1, and every 5 notes reveal
     a hint (mark a random undiscovered recipe's Grimoire cell as "hinted": show one
     parent silhouette).
   - Discovery flow: write Grimoire entry with DiscoveredAt, update Discovered
     leaderstat, apply milestone perks from BUILD_GUIDE §2.4 (slots via PlotService
     visibility + UnlockedSlots; gold multipliers stored as a Perks table the
     EconomyService reads on SellPlant), fire Discovery to the discoverer (full
     celebration) and a toast to the server ("<name> discovered <species>!").
   - Milestone perk application must be idempotent and re-applied on join (derive from
     Grimoire count, don't trust stored flags).
2. Wire AlchemyUI fully; brewing state survives rejoin (ReadyAt timestamp).
3. Extend EconomyService.SellPlant to apply the gold-multiplier perks.
Complete files for every touched module (full files, no diffs). stylua + selene.
Test plan: brew Sunbud+Dewroot → configured result; brew an undefined pair → Sproutling +
note; 5 notes → hint appears; reach 10 discoveries via command bar → +2 slots appear and
persist across rejoin; server toast fires exactly once per player-species.
Commit: "feat: alchemy brewing + grimoire milestones"
```

**Asset pass (you, ~2 hours):** brew VFX from ParticleEmitter presets (bubbles + a glow ramp as ReadyAt approaches) and a Creator Store discovery sting + confetti. The table's final model waits for Phase 10.

**Definition of done:** every test in the prompt passes · one recruited tester (friend or Discord) discovers a hybrid unprompted and *visibly reacts* (the real test) · perks re-derive correctly on rejoin.

---
## Phase 6 — Retention layer: streaks, quests, welcome-back (3–4 days)

**Goal:** the reasons to come back tomorrow — this phase is what the D2–7 and D8–28 algorithm windows actually measure.

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md. Scope: streaks + daily quests + welcome-back. UI shells exist.

1. src/shared/RewardConfig.luau — 7-day streak table (escalating gold + fertilizer;
   day 7 = one T3 seed), repeating with +10% gold each full week.
2. src/server/Services/StreakService.luau — UTC date keys (os.date("!*t")); on join:
   consecutive day → claimable, gap ≥2 days → reset to day 1. ClaimStreak validates
   server-side; ignores client entirely.
3. src/shared/QuestConfig.luau — pool of 12 quest defs {Id, Text, Stat, Goal, Reward}:
   harvest N, water N, brew N, sell-value N, water-a-friend N, discover 1, etc.
4. src/server/Services/QuestService.luau — on join, if Quests.DateKey ≠ today (UTC),
   roll 3 from the pool (no duplicates, at most one "discover"). Expose
   QuestService.Bump(player, stat, amount); call it from GardenService (harvest, water),
   AlchemyService (brew, discover), EconomyService (sell), SocialService placeholder.
   ClaimQuest grants reward, marks claimed.
5. Welcome-back: on join, if last session ended >1h ago, count ready plants and hours
   away; populate WelcomeBack.luau panel ("While you were away: 4 plants finished
   growing!") shown once, before anything else. Suppress during FTUE.
6. Wire DailyRewards.luau (streak UI) + QuestTracker.luau (HUD strip, 3 rows, claim
   buttons) to real data.
Complete files for every touched module. stylua + selene.
Test: fake the date key via a debug function to simulate day 2 / day 9 / lapsed;
quest progress bumps from real actions; welcome-back appears after a simulated absence.
Commit: "feat: streaks + daily quests + welcome back"
```

**Asset pass:** none required — the Phase 4 component kit carries the DailyRewards panel. Chest prop and quest-board dressing land in Phase 10.

**Definition of done:** simulated multi-day sequences behave (consecutive, lapsed, week-2) · all 12 quests progress from real play · welcome-back shows accurate counts and only once.

---

## Phase 7 — Social layer: the co-play signal (2–3 days)

**Goal:** make playing together mechanically better than playing alone — this is a top-tier ranking signal and our organic-growth engine.

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md. Scope: social mechanics.

1. src/server/Services/SocialService.luau —
   - Friend Boost: while ≥1 Roblox friend (player:IsFriendsWith) is in the server, both
     get +25% gold on sells. EconomyService queries SocialService.GetBoost(player).
     Include DEBUG_FRIEND_MODE flag in GameConfig treating everyone as friends for
     Studio testing.
   - Friend watering: watering a slot you don't own (already allowed by GardenService)
     now ALSO grants the waterer +25 gold (cap 20/day) and bumps the water-a-friend
     quest for both.
   - GiftSeed(player, targetUserId, seedId): friends only, both in server, 1 gift/day
     each direction, T1-T3 seeds only.
2. Client: "Invite Friends" button on the HUD (SocialService:PromptGameInvite wrapped in
   CanSendGameInviteAsync), plus a passive banner when no friends present: "Garden with
   a friend: +25% gold for both!".
3. Gift flow UI: small panel from the player list (nearest 5 players) — pick friend,
   pick seed, send; recipient gets a toast + accept.
Complete files for every touched module. stylua + selene.
Test with DEBUG_FRIEND_MODE in 2-client: boost applies to both, watering pays and caps,
gifting round-trips, invite prompt opens.
Commit: "feat: friend boost + gifting + invites"
```

**Asset pass (you, ~30 min):** heart/sparkle ParticleEmitter when someone waters your plant — it sells the mechanic. Benches/fountain plaza dressing waits for Phase 10.

**Definition of done:** all DEBUG-mode tests pass · one real-account test before launch using a second account friended to your main, or any willing friend (calendar it) · invite prompt works on mobile emulator.

---

## Phase 8 — Onboarding & telemetry (2–3 days)

**Goal:** the engineered first 60 seconds (§2.1) plus the instrumentation to prove it works. Bounce rate is a *negative* ranking signal — this phase is pure algorithm defense.

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md + BUILD_GUIDE.md §2.1. Scope: FTUE + analytics funnel.

1. FTUE (server-driven, FTUE.Step in profile):
   Step 1: new profiles spawn with slot 1 pre-planted, ready GoldenSprout (special
   config entry, sell 50) — spawn point faces it; harvest → +50 gold with an
   extra-juicy burst. Step 2: beam/arrow to seed stall, auto-grant 1 free Sunbud,
   highlight Plant prompt. Step 3: after first manual harvest, grant 1 Dewroot free.
   Step 4: when 2+ plants in inventory, pulse the Alchemy Table + arrow. Step 5: first
   brew collected → FTUE.Done. Suppress WelcomeBack/streak popups until Done (queue
   streak claim after). All steps skippable by just... playing; never lock input.
2. src/client/Controllers/OnboardingController.luau — renders beams/arrows/highlights
   from FTUE step, cleans up on advance.
3. src/server/Services/TelemetryService.luau — wraps AnalyticsService:
   LogOnboardingFunnelStepEvent steps: 1 spawned, 2 first_harvest, 3 first_plant,
   4 shop_buy, 5 first_brew, 6 first_discovery, 7 second_session (fire on join when
   Stats.FirstJoin < today). Add LogEconomyEvent on gold sources/sinks.
   Call sites in Garden/Economy/AlchemyService.
Complete files for every touched module. stylua + selene.
Test: wipe a test profile (debug function), run the FTUE start-to-finish on the phone
emulator with a stopwatch — first reward ≤10s, first plant ≤60s, no dead ends if the
player wanders off-script.
Commit: "feat: FTUE + onboarding funnel telemetry"
```

**Studio pass (you — this one can't wait for Phase 10):** spawn sightline — the first frame a new player sees is their glowing plot, shop visible to the right, table to the left; make the GoldenSprout look *special* (gold material, oversized sparkle); signage readable at distance.

**Definition of done:** stopwatch test passes on mobile emulator · wandering off-script never soft-locks · funnel events appear in Creator Hub analytics within ~24h (verify next day).

---

## Phase 9 — Monetization (1–2 days)

**Goal:** an honest ladder, live from day one, light-touch. Deterministic only.

**Setup first (Creator Hub, under the group):** create these and note the IDs —

| Type | Name | Price (R$) | Effect |
|---|---|---|---|
| Pass | 2x Gold | 399 | Doubles sell values |
| Pass | Green Thumb | 249 | +4 slots immediately |
| Pass | Auto-Harvest | 599 | Ready plants auto-harvest every 60s |
| Product | Gold: 5k / 25k / 100k | 99 / 349 / 999 | Direct grant |
| Product | Fertilizer ×5 | 149 | 5 consumables |
| Product | Starter Pack (one-time) | 199 | 2.5k gold + 3 fertilizer + 1 T3 seed |

**Vincent — Claude Code prompt (default model):**

```text
Read CLAUDE.md. Scope: monetization. IDs provided below: [paste IDs].
1. src/server/Services/MonetizationService.luau —
   - Pass ownership: UserOwnsGamePassAsync cached per session; PromptGamePassPurchaseFinished
     updates cache + applies effects immediately (Green Thumb slots idempotent like
     milestone perks). EconomyService/GardenService query HasPass().
   - ProcessReceipt: idempotent via Purchases[receiptId] in the profile BEFORE granting;
     PurchaseGranted only after profile save is confirmed. Starter Pack: one-time flag,
     hide offer after purchase.
   - Auto-Harvest: 60s server sweep for pass holders.
2. Shop UI "Support" tab: passes + gold + fertilizer; Starter Pack surfaces as a one-time
   offer toast AFTER first discovery (the goodwill moment), never as a popup on spawn.
Complete files for every touched module. stylua + selene.
Test in Studio purchase test mode: each product grants exactly once (retry ProcessReceipt
by returning NotProcessedYet first pass), passes apply live mid-session and after rejoin.
Commit: "feat: monetization ladder"
```

**Definition of done:** every purchase grants exactly once, including simulated receipt retries · no purchase prompt appears before first discovery · prices only exist server-side/config.

---

## Phase 10 — Polish & performance (≈1 week — the art week)

**Code track:**
1. **Audio hooks** — harvest pop, plant thunk, water sloosh, brew bubble loop, discovery sting, coin tick, ambient garden loop (day). One `SoundService` module, volumes in GameConfig.
2. **Juice pass** — plant scale-bounce on stage change, coin fly-to-pill on sell, camera nudge on discovery. Cheap TweenService work, disproportionate feel.
3. **Performance audit** — MicroProfiler on lowest graphics: target 30 fps on low-end; heartbeat scripts <8 ms. Verify: 8 mesh families actually instance-shared (same MeshId), no per-frame remotes, StateSync ≤1/s, StreamingEnabled on, part count sane. F9 memory tab: join/leave 10× in Studio → no climbing LuaHeap (connection leaks — every service must clean per-player state in PlayerRemoving).
4. **Loading** — no loading screen if we can help it; if needed, one branded frame, never >3 s of nothing.

**Art track (all the batched asset passes land here):**
1. Mesh families 2–5 (mushroom, vine, bulb/bell, crystal) × 4 stages — primitives/unions or free Creator Store meshes; recolors in PlantConfig cover all 46 species. Final models for alchemy table, shop stall, quest board, reward chest.
2. Environment pass — lighting, terrain paint, decorations, skybox, plaza benches/fountain; the "garden vista" screenshot should look shippable.
3. SFX/music selection from Creator Store audio (check licensing — use Roblox-provided/free-license audio only).
4. **Icon (512×512)** — one glowing plant in a pot, high contrast, readable at 64 px; 2 variants. Build it from an in-Studio cinematic screenshot + a free editor (Photopea/GIMP) — zero drawing required.
5. **Thumbnails (1920×1080, 3), same screenshot technique:** ① discovery moment — big reaction energy, "NEW!?" ② garden vista at golden hour ③ recipe tease: two plants + "? + ? = ✨". ≤3 words of text each, mobile-readable.

**Playtest:** 3–5 testers from friends/Discord, real phones included. Join the server with them and watch in-game — say nothing. Note where each person stalls in the first 3 minutes. Fix the top two stalls. Re-run.

**Definition of done:** 30 fps on the worst real phone you can borrow · no memory climb across 10 join/leaves · playtesters reach first discovery unaided · store art exported.

---

## Phase 11 — Publish & launch (2–3 days + launch week)

### 11.1 Pre-publish checklist (Creator Hub, in order)

1. Experience owned by the **group** ✅ (done Phase 0)
2. **Name:** pick from — "Alchemy Garden 🌿", "Grow an Alchemy Garden", "Alchemy Garden: Grow & Crossbreed". Verb-led names pattern-match the genre; my call: **"Grow an Alchemy Garden 🌿"** (searchable "grow", unique "alchemy").
3. **Description** (keywords early, changelog forever):
   ```
   🌱 Plant magical seeds, grow your garden, and CROSSBREED plants to discover 45 secret
   species! 🧪 Brew combos at the Alchemy Table — nobody knows all the recipes yet.
   🤝 Garden with friends: +25% gold together, water each other's plants!
   📖 Fill your Grimoire to unlock plots, boosts, and the Alchemist's Rose.
   ⭐ UPDATES every 2 weeks — new species waves!
   ── v1.0 (launch) ──
   ```
4. **Genre:** Simulation (subgenre: farming/incremental if offered).
5. **Devices:** Phone ✅ Tablet ✅ Desktop ✅ Console ❌ (v1.1, after gamepad UI pass). Max players 6.
6. **Age questionnaire** — complete it (required); our content is all-ages.
7. Monetization items live; test-purchase one product on a real account.
8. Icon + 3 thumbnails uploaded.
9. Fresh-account test: brand-new account, real phone, full FTUE. Fix anything weird. 

### 11.2 Launch sequence

- **Wednesday:** flip public *quietly*. Discord + personal invites only (~10–20 players). Watch the funnel analytics and bounce rate live; hotfix.
- **Friday afternoon (peak traffic):** the real push — this is our shot at the *Up & Coming* sort, which weighs growth velocity.
  - Discord @everyone with a discovery challenge ("first to find the Legendary recipe gets it named after them in the credits").
  - **1 short-form clip/day for 7 days (2 on weekend days)** — TikTok + Shorts + Roblox Moments if available. Rotate: ① first Mythic discovery reaction ② 24-h garden timelapse ③ "this combo makes WHAT?" recipe tease ④ friend-watering wholesome clip. Capture with OBS or Roblox's built-in recorder; batch-record Sunday, post daily. Sustainable beats impressive.
  - Ask every friend to co-play in pairs during launch weekend (feeds the co-play signal *and* fills 6-player servers so gardens look alive).
- **Do not run paid ads until D1 ≥ 20%** (our research gate). Then, small icon A/B test budget first.

### 11.3 Launch-week playbook — metric → response

| Signal | Threshold | Response |
|---|---|---|
| Bounce rate | >35% | Spawn sightline / first-10s problem. Fix FTUE step 1. |
| Funnel: spawn→first harvest | <70% | Prompt visibility issue — bigger, brighter, closer. |
| D1 | <20% | Stop promoting. Interview 3 churned playtesters. Fix loop, relaunch push next Friday. |
| D1 ≥20%, D7 <8% | — | Retention layer too weak: raise streak value, add 5-species wave early. |
| Session <8 min | — | Mid-loop dead spot — check gold curve between T2→T3. |
| Spike then cliff | — | Thumbnail overpromises. Honest thumbnail beats a viral one that bounces. |

---

## Post-launch playbook (first 6 weeks)

- **Cadence:** weekly patch (fixes + balance), **species wave every 2 weeks** (5 species + 5 recipes = one config edit + one 30-minute recolor batch — deliberately cheap), event framework later. Every update = changelog line + Discord post + one clip.
- **v1.1 (wk 3–4): Transmutation** — rebirth: reset gold/plants (keep Grimoire), gain permanent +25% growth speed per rank. Adds the long-game D8–28 hook.
- **v1.2 (wk 6+, only if D7 ≥ 10%): Trading** — the big retention unlock, and the big scam-surface. Confirm-twice UI, trade log, value warnings. Don't rush it.
- **Community:** recipe-hunting channel stays unspoiled by us; seed hints only. If someone starts a wiki, feature them.
- **Sundays:** 30-min solo metrics ritual — D1/D7, funnel, top drop-off, decide the week's ONE priority, then post a one-paragraph devlog in Discord. Public momentum is the solo dev's accountability partner. Update `PROJECT.md`.

## Risks & guardrails

- **Scope creep** → §2.6 is law. New ideas go to PROJECT.md's Parking Lot, not the sprint.
- **Content treadmill** → species waves are config-only by design; AI generates the tables, you recolor in one short Studio session. If updates ever need >2 days, we've over-designed.
- **Clones** (this genre gets cloned fast) → our moat is the hidden-recipe meta + polish, not the idea. Ship waves faster than a cloner can copy.
- **Data wipes** → schema changes require Version bump + migration function. No exceptions. Test migrations on a copy.
- **Burnout / solo drift** → phases are sized to finish; ship something visible every week and post it in Discord. If a phase runs 2× its estimate, cut its scope, don't extend it. When motivation dips, do an asset pass — visual progress is the cheapest morale.

---

## Appendix A — PlayerData (full Luau type)

```lua
export type PlotSlot = {
	SeedId: string?,
	PlantedAt: number?,     -- os.time()
	GrowDuration: number?,  -- seconds (base, pre-multipliers)
	WateredUntil: number?,  -- os.time(); 1.25x growth while now < this
}

export type QuestEntry = { Id: string, Progress: number, Goal: number, Claimed: boolean }

export type PlayerData = {
	Version: number,
	Gold: number,
	ResearchNotes: number,
	Slots: { PlotSlot },                -- index = SlotIndex (1..24)
	UnlockedSlots: number,              -- starts 6
	Seeds: { [string]: number },
	Plants: { [string]: number },
	Grimoire: { [string]: { DiscoveredAt: number, Harvested: number } },
	Hints: { [string]: boolean },       -- recipe keys revealed by Research Notes
	Brew: { PlantA: string, PlantB: string, ReadyAt: number }?,
	Streak: { Count: number, LastClaimDate: string },   -- "YYYY-MM-DD" UTC
	Quests: { DateKey: string, List: { QuestEntry } },
	FTUE: { Step: number, Done: boolean },
	Purchases: { [string]: boolean },   -- receipt ids + one-time flags
	Stats: { TotalHarvests: number, TotalBrews: number, Discovered: number,
	         FirstJoin: number, LastSeen: number },
}
```

## Appendix B — Content: curves, name bank, samples

**Curves (Tier t):** SeedCost = 25·4^(t−1) · Sell ≈ 1.8×cost (shop seeds) · Grow = 60s / 5m / 20m / 1h / 4h / 12h · Hybrid sell = same-tier shop sell ×1.2 per-hour-equivalent.

**Name bank (46):**
- **T1 Common (8, shop):** Sunbud, Dewroot, Glowcap, Mooncress, Emberlily, Frostfern, Thornrose, Sparkvine
- **T2 Uncommon (10; 4 shop-milestone, 6 hybrid):** Honeybell, Puffshroom, Tanglevine, Duskpetal, Twinshine, Coppercress, Bramblewick, Palefrond, Cinderpuff, Mistleaf
- **T3 Rare (10, hybrid; 2 shop-milestone):** Mistrose, Gloomcap, Sablethorn, Prismbud, Wispvine, Marrowroot, Suncrown, Tidebloom, Ashfern, Chimebell
- **T4 Epic (8):** Eclipsebell, Stormbriar, Ironbloom, Starcress, Voidpetal, Frostlily, Crystalcap, Dreamvine
- **T5 Legendary (6):** Aurora Fern, Phoenixbud, Moonwell Rose, Leviathan Kelp, Sylvan Heart, Comet Orchid
- **T6 Mythic (3):** Worldtree Sapling, Genesis Bloom, Alchemist's Rose *(45-milestone exclusive)*
- **Filler:** Sproutling (dud brew result; counts as a freebie Grimoire entry)

**Sample recipes (style guide for the full 40):**
`Emberlily+Frostfern → Mistrose` · `Glowcap+Glowcap → Twinshine` · `Sunbud+Mooncress → Eclipsebell` · `Thornrose+Sparkvine → Stormbriar` · `Eclipsebell+Stormbriar → Aurora Fern`
Rules: T5/T6 require hybrid parents (chains 3+ deep); self-pairs allowed for 3–4 recipes; thematic logic (fire+ice, sun+moon) so guessing feels smart.

## Appendix C — Mesh families (v1.0 build list)

v1.0 families: Flower, Mushroom, Vine, Bulb/Bell, Crystal — ×4 stages each = 20 models (Studio primitives/unions or free Creator Store meshes are fine). Species map to a family + Color3 recolor in PlantConfig. Golden Sprout (FTUE) = Flower family, gold material, extra sparkle. Fern, Tree-sapling and Aquatic families ship with post-launch species waves.

## Appendix D — CLAUDE.md (copy this whole block into the new repo root)

```markdown
# CLAUDE.md — Alchemy Garden

Roblox incremental garden game. Luau. Solo dev: Vincent — you write the code; he also does the Studio and art passes himself.
Design + phase plan: BUILD_GUIDE.md. Status: PROJECT.md. Read the relevant phase before coding.

## Rojo mapping
src/server → ServerScriptService.Server · src/shared → ReplicatedStorage.Shared ·
src/client → StarterPlayer.StarterPlayerScripts.Client. Workspace/map is Studio-owned — never
generate map geometry in code unless asked.

## Conventions
- Luau, --!strict where practical. PascalCase modules/Services, camelCase locals.
- task.wait()/task.spawn() only — never wait() or spawn(). No deprecated APIs.
- Timestamps: os.time() (UTC seconds). Date keys: os.date("!%Y-%m-%d").
- All remotes created/fetched ONLY via src/shared/Remotes.luau.
- Services (server) and Controllers (client) are singletons required by init scripts.
- All tunables in GameConfig / PlantConfig / RecipeConfig / QuestConfig / RewardConfig —
  no magic numbers in logic files.

## Security (hard rules)
- Server-authoritative everything: prices, timers, rewards, inventory. Client only requests.
- Validate type/range/ownership on every remote arg. Rate-limit every C→S remote.
- ProcessReceipt idempotent via profile.Purchases. Never trust client-sent IDs for pricing.

## Output format (hard rules)
- COMPLETE FILES ONLY on any change — never diffs, snippets, or "replace lines X–Y".
- Say the exact file path for everything you write.
- Between prompts, report outcomes only — no unsolicited code dumps.
- Keep changes minimal and in-scope; do not refactor unrelated code. If a linter warning
  is pre-existing and unrelated, note it and move on — do not chase it.
- Run stylua and selene before declaring done. Small commits; use the commit message
  given in the phase prompt.

## Asset contract
Plants: ReplicatedStorage/Assets/Plants/<SpeciesId>/Stage1..Stage4 — fallback to default
sprout if missing. Tags: GardenPlot(+PlotIndex attr), SoilSlot(+SlotIndex attr), SeedShop,
AlchemyTable, QuestBoard. FX: ReplicatedStorage/Assets/FX/<Name>, skip if absent.
```

---

*End of guide. Next stop: Phase 0.* 🌱
