extends Node3D

@export var level_light: PackedScene
@export var level_camera: PackedScene

func _ready() -> void:
	RH.print("🪨 level.gd | ready()", 1)

	# Instantiate the basics...
	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	var inst: Node3D = level_light.instantiate()
	add_child(inst)

	RH.print("🪨 level.gd | 🎥 level_camera.instantiate")
	inst = level_camera.instantiate()
	add_child(inst)
