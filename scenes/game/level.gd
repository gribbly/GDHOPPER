extends Node3D

## The dimensions of the level to generate (in meters)
@export var level_dimensions: Vector2
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene

var level_csg_instance: Node3D

func _ready() -> void:
	RH.print("🪨 level.gd | ready()", 1)

	RH.print("🪨 level.gd | 📐 debug_visuals.instantiate")
	var inst: Node3D = debug_visuals.instantiate()
	add_child(inst)

	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	inst = level_light.instantiate()
	add_child(inst)

	RH.print("🪨 level.gd | 📸  level_camera.instantiate")
	inst = level_camera.instantiate()
	add_child(inst)

	RH.print("🪨 level.gd | 🔪 level_csg.instantiate")
	level_csg_instance = level_csg.instantiate()
	add_child(level_csg_instance)

	SignalBus.emit_signal("level_setup_complete", level_dimensions)
