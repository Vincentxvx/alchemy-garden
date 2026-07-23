# PROMPTS.md — Alchemy Garden Claude Code prompts (solo edition)

Every copy-paste prompt from BUILD_GUIDE.md v1.1 in one plain file, now with the exact
model per phase. Keep this in the repo root next to CLAUDE.md and copy from here
(VS Code), not from the PDF.

Model strategy (set up once):
- Run `/model sonnet` in your first session — it saves as the default for new sessions
  (Claude Code v2.1.153+), so you only switch when a phase header below says so.
- Phases 2 and 5 use `/model opusplan` (Opus plans, Sonnet writes the code) with
  `/effort xhigh`. Drop back with `/model sonnet` once the Definition of Done passes.
- Everywhere else, escalate only for a bug that survives two Sonnet attempts — then
  straight back down. Fable 5 stays in the back pocket for a bug Opus can't crack.

How to use:
- One prompt = one Claude Code session, run from the repo root, in phase order.
- Before running: read the phase's design notes + asset pass + Definition of Done in
  BUILD_GUIDE.md — the prompt assumes you have.
- Phase 9 needs the game-pass / dev-product IDs pasted in before running, and is
  followed by the Opus review pass at the bottom of this file.
- Phases 0, 10, 11 have no prompt — they're manual checklists in the guide.
- After each phase: test the Definition of Done, commit, update PROJECT.md.

---

## Phase 1 — Data foundation & plots  ·  `/model sonnet`

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

---

## Phase 2 — Planting, growth & offline progress  ·  `/model opusplan` + `/effort xhigh`

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

---

## Phase 3 — Economy: shop, selling & full content table  ·  `/model sonnet`

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

---

## Phase 4, session A — UI foundation + HUD/Shop/Inventory  ·  `/model sonnet`

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

---

## Phase 4, session B — Grimoire, Alchemy, notification UI  ·  `/model sonnet`

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

---

## Phase 5 — Alchemy & Grimoire logic  ·  `/model opusplan` + `/effort xhigh`

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

---

## Phase 6 — Retention: streaks, quests, welcome-back  ·  `/model sonnet`

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

---

## Phase 7 — Social layer: co-play  ·  `/model sonnet`

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

---

## Phase 8 — Onboarding & telemetry  ·  `/model sonnet`

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

---

## Phase 9 — Monetization  ·  `/model sonnet` — run the review pass below afterwards

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

---

## Phase 9 review pass — MonetizationService audit  ·  `/model opus` + `/effort xhigh`

Run this as a fresh session AFTER Phase 9's Definition of Done passes. Money code gets
a second opinion.

```text
Read CLAUDE.md. This is a REVIEW-ONLY pass — change nothing unless you find a real
defect. Scope: src/server/Services/MonetizationService.luau and its call sites
(Shop UI Support tab, EconomyService/GardenService pass checks).

Audit for:
- ProcessReceipt idempotency: receipt granted exactly once across retries AND rejoins;
  Purchases[receiptId] written to the profile BEFORE granting; PurchaseGranted returned
  only after the profile write is confirmed.
- Pass cache correctness: updated by PromptGamePassPurchaseFinished, survives rejoin,
  effects (Green Thumb slots) applied idempotently.
- Starter Pack one-time flag cannot be bypassed or double-granted.
- Any path where a client-supplied value could influence price, product id, or grant
  amount.

Report findings as a numbered list with severity (critical/minor/nitpick). If a fix is
needed, output the COMPLETE corrected file — never a diff. If everything is correct,
say so explicitly and explain why each risk above is covered.
Commit (only if something changed): "fix: monetization review pass"
```
