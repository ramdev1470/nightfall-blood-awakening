# Nightfall: Blood Awakening — Chapter One: The Hollow

A playable ~15–20 minute vertical slice built in Godot 4.4+. No external
assets are required — the entire town, player model, enemy, NPC, VFX and
audio are generated procedurally at runtime.

## Run

1. Open this folder as a project in **Godot 4.4 or newer** (Forward+ renderer).
2. Press **F5**.
3. Title screen → **Enter The Hollow** → play.

## Controls

| Action | Key |
|---|---|
| Move | WASD |
| Look | Mouse |
| Sprint | Shift |
| Jump | Space |
| Dodge | Ctrl |
| Attack | Left Mouse Button |
| Interact / Talk | E |
| Pause | Esc |
| Save / Load | F5 / F8 (in-game, via Pause menu too) |

## What happens in Chapter One

Fade in on the forest road outside The Hollow → walk in past an abandoned
carriage and a blood trail → the church bell tolls on its own → enter the
town square → glimpse something moving between the buildings → reach the
church and speak with Father Aldric (branching dialogue) → a werewolf
ambushes you near the graveyard → fight it → mid-fight, the protagonist's
Blood Surge manifests (speed/damage buff, screen VFX, NPC fear reaction) →
defeat the werewolf → cliffhanger ending screen.

## Project structure

- `scripts/world/world_builder.gd` — procedurally builds the whole connected
  map (forest road, gate, square, church, graveyard, forest edge, catacomb
  entrance) from CSG primitives and materials.
- `scripts/world/main.gd` — drives the scripted story beats.
- `scripts/player/player.gd` — movement, procedural humanoid model + walk
  animation, melee combat, Blood Surge power.
- `scripts/enemies/` — enemy AI base class + werewolf.
- `scripts/npc/` — interactable NPC base class + Father Aldric.
- `scripts/combat/` — Hitbox/Hurtbox damage components.
- `scripts/ui/` — title screen, HUD (autoload), dialogue box, pause menu, end screen.
- `scripts/autoload/` — GameManager, PlayerManager, QuestManager,
  DialogueManager, SaveManager, AudioManager (procedural sound synthesis),
  ScreenEffects (Blood Surge vignette).
- `shaders/` — ground mist, pulsing rune glow, screen vignette.

## Known limitations

- All audio is synthesized at runtime (tones/noise envelopes) rather than
  recorded sound — functional and non-silent, but not final-quality SFX.
- The catacomb entrance is visible but locked/non-functional — an intentional
  hook for a future chapter, per the design brief.
- No baked lightmaps/navmesh; enemy movement is direct steering, not
  NavigationAgent-based, which is fine for the single open encounter here.
