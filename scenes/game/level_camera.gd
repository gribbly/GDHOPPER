extends Node3D

# Note: Assumes that LevelCamera.tscn has %LevelCamera3D

# Tuneables
var use_debug_size := true
var debug_camera_size := 150

# Internal
var start_z := 64.0

func _ready() -> void:
	RH.print("📸 level_camera.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_adjust_size"))
	start_z = global_position.z

func _exit_tree() -> void:
	RH.print("📸 level_camera.gd | _exit_tree()", 3)
	SignalBus.disconnect("level_setup_complete", Callable(self, "_adjust_size"))

func move_camera(x: float, y: float):
	global_position = Vector3(x, y, start_z)

func _adjust_size(level_dims: Vector3) -> void:
	RH.print("📸 level_camera.gd | _adjust_size()", 3)
	var new_size = level_dims.y / 2.0
	if use_debug_size: 
		RH.print("📸 level_camera.gd | DEBUG - forcing size to %s" % debug_camera_size, 3)
		new_size = debug_camera_size
	%LevelCamera3D.size = new_size
	RH.print("📸 level_camera.gd | new size is %.2f" % new_size, 3)

