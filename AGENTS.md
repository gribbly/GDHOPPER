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

### Technical goals

* Never drop below 60FPS during gameplay, on Steam Deck
* Minimal dependencies
* Clean, maintainable code, separated into focused units
* Prefer readable and simple over "clever"
* Only optimize when profiler says its necessary

### Details and gotchas

* When using SignalBus.connect in '_ready', you probably need to do SignalBus.disconnect in '_exit_tree'. See /scenes/game/level_csg.gd for an example.

## Game design

See README.md
