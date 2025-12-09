extends Node3D

## The dimensions of the level to generate (in meters)
@export var level_dimensions: Vector2
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene

var debug_visuals_instance: Node3D
var level_csg_instance: Node3D

#temp - just while implementing/test debug_visuals
var debug_line_count := 0

func _ready() -> void:
	RH.print("🪨 level.gd | _ready()", 1)

	RH.print("🪨 level.gd | 📐 debug_visuals.instantiate")
	debug_visuals_instance = debug_visuals.instantiate()
	add_child(debug_visuals_instance)

	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	add_child(level_light.instantiate())

	RH.print("🪨 level.gd | 📸  level_camera.instantiate")
	add_child(level_camera.instantiate())

	RH.print("🪨 level.gd | 🔪 level_csg.instantiate")
	level_csg_instance = level_csg.instantiate()
	add_child(level_csg_instance)

	RH.print("🪨 level.gd | 📐 drawing level bounds - %s" % level_dimensions)
	var level_bounds_start:=Vector3(0.0, 0.0, 34.0)
	var level_bounds_endx:=Vector3(level_dimensions.x, 0.0, 34.0)
	var level_bounds_endy:=Vector3(0.0, level_dimensions.y, 34.0)
	debug_visuals_instance.rh_debug_line(level_bounds_start, level_bounds_endx, Color.RED)
	debug_visuals_instance.rh_debug_line(level_bounds_start, level_bounds_endy, Color.GREEN)

	SignalBus.emit_signal("level_setup_complete", level_dimensions)
