## Level camera controller.
## - Instanced by `Scenes/Level/level.gd` via `LevelCamera.tscn`.
## - Provides a simple "follow target" camera and a helper to center on the level.
## - Gameplay is 2D-in-3D: camera uses `Vector3` but we mostly keep `z` as distance.
class_name LevelCamera
extends Node3D

# Note: Assumes that LevelCamera.tscn has %LevelCamera3D

# Externals
var follow_target: Node3D = null

# Tuneables
const Z_DISTANCE = 64.0
const DEFAULT_SIZE = 32.0 # 32.0 is closer to actual default size
const COSMETIC_CAMERA_TILT = 0.0 # -0.04 is an interesting option, not sure yet!

# Internals
var in_level_gen_mode: bool = false

@onready var camera_node = %LevelCamera3D

class _Shake:
	var intensity: float
	var duration: float
	var time_left: float
	var dir2: Vector2

	func _init(intensity_: float, duration_s_: float, direction_: Vector3) -> void:
		intensity = intensity_
		duration = duration_s_
		time_left = duration_s_
		dir2 = Vector2(direction_.x, direction_.y)
		if dir2.length_squared() > 0.000001:
			dir2 = dir2.normalized()

var _camera_base_position: Vector3 = Vector3.ZERO
var _active_shakes: Array[_Shake] = []


func _ready() -> void:
	RH.print("📸 level_camera.gd | ready()", 2)
	SignalBus.connect("explosion", Callable(self, "_on_explosion"))

	#_adjust_size(DEFAULT_SIZE)
	_camera_base_position = camera_node.position


func _exit_tree() -> void:
	SignalBus.disconnect("explosion", Callable(self, "_on_explosion"))


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
			KEY_0:
				camera_shake(1.0, 1000)


func _process(delta: float) -> void:
	if follow_target != null and not in_level_gen_mode:
		global_position = follow_target.global_position
		global_position.z = Z_DISTANCE

	_update_camera_shake(delta)


func move_camera(x: float, y: float):	
	global_position = Vector3(x, y, Z_DISTANCE)
	global_rotate(Vector3(1, 0, 0), COSMETIC_CAMERA_TILT)


func camera_shake(intensity: float, duration_ms: float, direction: Vector3 = Vector3.ZERO) -> void:
	if intensity <= 0.0 or duration_ms <= 0.0:
		return

	var duration_s := duration_ms / 1000.0
	_active_shakes.append(_Shake.new(intensity, duration_s, direction))


func _update_camera_shake(delta: float) -> void:
	if _active_shakes.is_empty():
		camera_node.position = _camera_base_position
		return

	var total_offset := Vector3.ZERO
	for i in range(_active_shakes.size() - 1, -1, -1):
		var shake: _Shake = _active_shakes[i]
		shake.time_left = shake.time_left - delta
		if shake.time_left <= 0.0:
			_active_shakes.remove_at(i)
			continue

		var t := clamp(shake.time_left / shake.duration, 0.0, 1.0) as float
		var dir2: Vector2 = shake.dir2

		var random_dir2 := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		if random_dir2.length_squared() < 0.000001:
			random_dir2 = Vector2.RIGHT
		else:
			random_dir2 = random_dir2.normalized()

		if dir2.length_squared() > 0.000001:
			dir2 = (dir2 * 0.8 + random_dir2 * 0.2).normalized()
		else:
			dir2 = random_dir2

		var magnitude := randf_range(0.0, shake.intensity * t)
		total_offset.x += dir2.x * magnitude
		total_offset.y += dir2.y * magnitude

	camera_node.position = _camera_base_position + total_offset


func _adjust_size(new_size: float = DEFAULT_SIZE) -> void:	
	camera_node.size = new_size
	RH.print("📸 level_camera.gd | new size is %.2f" % new_size, 3)


func toggle_level_gen_mode() -> void:
	in_level_gen_mode = !in_level_gen_mode
	if in_level_gen_mode == true:
		_adjust_size(350.0)
		global_position = Vector3(256.0, 128.0, Z_DISTANCE)
		global_rotation = Vector3.ZERO


func _on_explosion():
	camera_shake(0.5, 400)