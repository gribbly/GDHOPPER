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

	SignalBus.emit_signal("level_setup_complete", level_dimensions)
	
	#temp - just while implementing/test debug_visuals
	var timer := Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_tick)

func _on_tick() -> void:
	_draw_debug_line()
	debug_line_count += 1
	if debug_line_count > 100:
		debug_visuals_instance.clear()
		debug_line_count = 0

func _draw_debug_line() -> void:
	var start = Vector3(0.0, 0.0, 30.0)

	var x = RH.get_random_float(-200, 200)
	var y = RH.get_random_float(-200, 200)
	var end = Vector3(x, y, 30.0)

	var colors := [
		Color.RED,
		Color.GREEN,
		Color.BLUE,
		Color.YELLOW,
		Color.ORANGE,
		Color.PURPLE
	]

	debug_visuals_instance.rh_debug_line(start, end, colors.pick_random())
