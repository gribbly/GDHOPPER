## Simple level lighting setup.
## - Instanced by `Scenes/Level/level.gd` via `LevelLight.tscn`.
## - Keeps lighting configuration out of `level.gd` so the Level script stays focused on procgen.
extends Node3D

func _ready() -> void:
	RH.print("🪨 level_light.gd | ☀️ ready()")

	rotation_degrees = Vector3(-32.0, -45.0, 0.0)
