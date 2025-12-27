## Simple level lighting setup.
## - Instanced by `Scenes/Level/level.gd` via `LevelLight.tscn`.
## - Keeps lighting configuration out of `level.gd` so the Level script stays focused on procgen.
extends Node3D

func _ready() -> void:
	var _sun_rotation = Vector3(-32.0, -45.0, 0.0)
	rotation_degrees = _sun_rotation

	RH.print("☀️ level_light.gd | ready() - set sun rotation to %s" % _sun_rotation, 2)