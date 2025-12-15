extends Node3D

# Note: Assumes that LevelCamera.tscn has %LevelCamera3D

# External
var follow_target: Node3D = null

# Tuneables
const Z_DISTANCE = 64.0
const DEFAULT_SIZE = 32.0
const COSMETIC_CAMERA_TILT = -0.02 # For real
#const COSMETIC_CAMERA_TILT = 0.0 # For testing

func _ready() -> void:
	RH.print("📸 level_camera.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_adjust_size"))

func _exit_tree() -> void:
	RH.print("📸 level_camera.gd | _exit_tree()", 5)
	SignalBus.disconnect("level_setup_complete", Callable(self, "_adjust_size"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_1:
				_adjust_size(DEFAULT_SIZE)
			KEY_2:
				_adjust_size(DEFAULT_SIZE * 8.0)
			KEY_3:
				_adjust_size(DEFAULT_SIZE * 16.0)
			KEY_4:
				_adjust_size(DEFAULT_SIZE * 0.5)

func _process(_delta: float) -> void:
	if follow_target == null:
		return
	global_position = follow_target.global_position
	global_position.z = Z_DISTANCE

func move_camera(x: float, y: float):
	global_position = Vector3(x, y, Z_DISTANCE)
	global_rotate(Vector3(1, 0, 0), COSMETIC_CAMERA_TILT)

func _adjust_size(new_size: float = DEFAULT_SIZE) -> void:
	RH.print("📸 level_camera.gd | _adjust_size()", 5)
	%LevelCamera3D.size = new_size
	RH.print("📸 level_camera.gd | new size is %.2f" % new_size, 3)

