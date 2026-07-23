# CLAUDE.md - Alchemy Garden

Roblox incremental garden game. Luau. Solo dev: Vincent - you write the code; he also does the Studio and art passes himself.
Design + phase plan: BUILD_GUIDE.md. Status: PROJECT.md. Read the relevant phase before coding.

## Rojo mapping
src/server -> ServerScriptService.Server , src/shared -> ReplicatedStorage.Shared ,
src/client -> StarterPlayer.StarterPlayerScripts.Client. Workspace/map is Studio-owned - never
generate map geometry in code unless asked.

## Conventions
- Luau, --!strict where practical. PascalCase modules/Services, camelCase locals.
- task.wait()/task.spawn() only - never wait() or spawn(). No deprecated APIs.
- Timestamps: os.time() (UTC seconds). Date keys: os.date("!%Y-%m-%d").
- All remotes created/fetched ONLY via src/shared/Remotes.luau.
- Services (server) and Controllers (client) are singletons required by init scripts.
- All tunables in GameConfig / PlantConfig / RecipeConfig / QuestConfig / RewardConfig -
  no magic numbers in logic files.

## Security (hard rules)
- Server-authoritative everything: prices, timers, rewards, inventory. Client only requests.
- Validate type/range/ownership on every remote arg. Rate-limit every C->S remote.
- ProcessReceipt idempotent via profile.Purchases. Never trust client-sent IDs for pricing.

## Output format (hard rules)
- COMPLETE FILES ONLY on any change - never diffs, snippets, or "replace lines X-Y".
- Say the exact file path for everything you write.
- Between prompts, report outcomes only - no unsolicited code dumps.
- Keep changes minimal and in-scope; do not refactor unrelated code. If a linter warning
  is pre-existing and unrelated, note it and move on - do not chase it.
- Run stylua and selene before declaring done. Small commits; use the commit message
  given in the phase prompt.

## Asset contract
Plants: ReplicatedStorage/Assets/Plants/<SpeciesId>/Stage1..Stage4 - fallback to default
sprout if missing. Tags: GardenPlot(+PlotIndex attr), SoilSlot(+SlotIndex attr), SeedShop,
AlchemyTable, QuestBoard. FX: ReplicatedStorage/Assets/FX/<Name>, skip if absent.
