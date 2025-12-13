extends Node3D

@export var level_dimensions: Vector3 #meters
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene

var level_csg_instance: Node3D
var level_camera_instance: Node3D

#temp - just while implementing/test debug_visuals
var debug_line_count := 0

func _ready() -> void:
	RH.print("🪨 level.gd | _ready()", 1)

	RH.print("🪨 level.gd | 🌐 setting level_dimensions in globals.gd")
	RH.level_dimensions = level_dimensions

	RH.print("🪨 level.gd | 📐 debug_visuals.instantiate")
	add_child(debug_visuals.instantiate())

	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	add_child(level_light.instantiate())

	RH.print("🪨 level.gd | 📸  level_camera.instantiate")
	level_camera_instance = level_camera.instantiate()
	add_child(level_camera_instance)

	RH.print("🪨 level.gd | 🔪 level_csg.instantiate")
	level_csg_instance = level_csg.instantiate()
	add_child(level_csg_instance)

	if RH.show_debug_visuals == true:
		RH.print("🪨 level.gd | marking level origin")
		RH.debug_visuals.rh_debug_x_with_label(position, "origin", Color.WHITE)

	RH.print("🪨 level.gd | moving camera to level midpoint...")
	level_camera_instance.move_camera(level_dimensions.x / 2.0, level_dimensions.y / 2.0)

	SignalBus.emit_signal("level_setup_complete")
