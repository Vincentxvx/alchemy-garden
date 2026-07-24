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

## UI style (locked, Phase 4)
- Font: `Enum.Font.FredokaOne` everywhere - one font, no mixing. Rounded/playful, fits the
  cozy-magical-garden tone.
- Palette (exactly 3 - do not add more without updating this file first):
  - Primary/Gold `Color3.fromRGB(255, 176, 59)` - primary CTAs (Buy, Brew, Harvest prompts),
    the HUD gold pill, key highlights.
  - Secondary/Leaf `Color3.fromRGB(94, 186, 88)` - positive/secondary actions (Sell, Water,
    success states).
  - Surface/Parchment `Color3.fromRGB(255, 248, 231)` - panel and card backgrounds (warm
    cream, not stark white/grey - reads like a Grimoire page).
  - Utility neutrals (not part of the 3-color quota, just typography): ink text
    `Color3.fromRGB(59, 41, 28)` on Parchment surfaces, white text on Primary/Secondary
    buttons.
- Corner radius: one `UICorner` value everywhere, `UDim.new(0, 16)` - panels, buttons, cards.
  No pills, no per-element radii.
- Touch targets: buttons >=44px effective size; scale-based sizing only, zero pixel-offset
  layout (BUILD_GUIDE Phase 4 ground rules).

## MCP tools (Studio bridge)
The robloxstudio MCP tools can read and write the live Studio DOM directly (Workspace
included) and can also read/edit scripts - this bypasses Rojo/git entirely.
- Default stays hand-building in Studio for map/world work (Phase 1 plots, Phase 10
  environment pass, etc.) - MCP is not a general-purpose way to build out the map.
- Only use MCP tools for a specific placement or edit when explicitly asked for it in
  that session's prompt.
- NEVER use MCP tools to edit src/server, src/client, or src/shared files or their
  live Studio copies. All logic/script changes go through the normal file-writing flow
  (edit the file, let Rojo sync it) so they stay visible in git history. Editing a
  synced script's live copy directly in Studio gets overwritten by Rojo anyway and
  creates confusing drift between git and the running place.
