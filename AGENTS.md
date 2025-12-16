# ROCKHOPPER

## Project status

* Early! We are still setting up the basic framework. Most of the game is not implemented.
* Project author (Cam) is still learning Godot. So we're going slow and steady.
  * Cam is experienced with Unity, so explaining things by comparing to Unity concepts can be useful (but don't overdo it)
* When helping, don't "race ahead". Go step-by-step and be patient.

## Technical details

* Built with Godot 4.5.1
  * Godot project name: GDHOPPER
* Using GDScript
* Default resolution is 1280x800 (primary target = Steam Deck)
* The game is "2D in 3D". Meaning that the gameplay is primarily 2D/ortho cam. But "under the hood" everything is using Node3D, Vector3, etc. This is for two reasons: (1) We want to sometimes take advantage of depth (example, "throw debris at the camera"), and (2) in the future there will be a 3D sequel, I'd like the underlying systems to be as 3D-ready as possible so it's less of a rewrite.

### Technical goals

* Never drop below 60FPS during gameplay, on Steam Deck
* Minimal dependencies
* Clean, maintainable code, separated into focused units
* Prefer readable and simple over "clever"
* Only optimize when profiler says its necessary

#### Ballpark technical budgets

Note: Godot's monitor numbers can be inflated by Editor gizmos/UI. Do real checking in a release build!

* Steam Deck games are usually CPU-limited by draw calls first, then GPU by shading/overdraw
* Draw Calls (RENDER_TOTAL_DRAW_CALLS_IN_FRAME) < 500
* Objects Drawn (RENDER_TOTAL_OBJECTS_IN_FRAME) < 3000
* Primitives Drawn (RENDER_TOTAL_PRIMITIVES_IN_FRAME) < 1M
* Active 3D Physics Objects < 500
* Nodes < 10K
  * A few thousand nodes is considered normal for a game targeted at Steam Deck (but depends what they're doing)

### Details and gotchas

* When using SignalBus.connect in '_ready', you probably need to do SignalBus.disconnect in '_exit_tree'. See /scenes/game/level_csg.gd for an example.
* Use Vector3 for everything, even though it's 2D gameplay. I many places we just ignore or zero out the z component.

## Game design

See README.md
