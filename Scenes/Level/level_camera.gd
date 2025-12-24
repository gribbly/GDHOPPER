## Level camera controller.
## - Instanced by `Scenes/Level/level.gd` via `LevelCamera.tscn`.
## - Provides a simple "follow target" camera and a helper to center on the level.
## - Gameplay is 2D-in-3D: camera uses `Vector3` but we mostly keep `z` as distance.
class_name LevelCamera
extends Node3D

# Note: Assumes that LevelCamera.tscn has %LevelCamera3D

# External
var follow_target: Node3D = null

# Tuneables
const Z_DISTANCE = 64.0
const DEFAULT_SIZE = 32.0 # 32.0 is closer to actual default size
const COSMETIC_CAMERA_TILT = -0.04 # -0.02 is an interesting option, not sure yet!

# Internals
var in_level_gen_mode: bool = false

func _ready() -> void:
	RH.print("📸 level_camera.gd | ready()", 1)
	#_adjust_size(DEFAULT_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_1:
				_adjust_size(32.0)
			KEY_2:
				_adjust_size(64.0)
			KEY_3:
				_adjust_size(256.0)
			KEY_4:
				_adjust_size(384.0)
			KEY_C:
				_adjust_size(DEFAULT_SIZE)
			KEY_L:
				toggle_level_gen_mode()

func _process(_delta: float) -> void:
	if follow_target == null or in_level_gen_mode:
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

func toggle_level_gen_mode() -> void:
	in_level_gen_mode = !in_level_gen_mode
	if in_level_gen_mode == true:
		_adjust_size(350.0)
		global_position = Vector3(256.0, 128.0, Z_DISTANCE)
		global_rotation = Vector3.ZERO
