extends Camera3D

# Exports
@export var move_speed: float = 32.0
@export var sprint_multiplier: float = 4.0
@export var acceleration: float = 12.0
@export var deceleration: float = 16.0
@export var mouse_sensitivity: float = 0.002
@export var look_smoothing: float = 22.0
@export_range(0.0, 89.9, 0.1) var pitch_limit_degrees: float = 85.0

# Internals
var _velocity: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0
var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	print("🤳 debug_camera.gd | _ready()")
	_target_yaw = rotation.y
	_target_pitch = rotation.x
	_yaw = _target_yaw
	_pitch = _target_pitch
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	RH.print("🤳 debug_camera.gd | _exit_tree()", 4)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not current:
		return
	
	_update_mouse_look(delta)

	var direction := _get_move_direction()
	var speed := move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= sprint_multiplier

	var desired_velocity := direction * speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	var t: float = clampf(1.0 - exp(-rate * delta), 0.0, 1.0)
	_velocity = _velocity.lerp(desired_velocity, t)

	global_position += _velocity * delta


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_X:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		_target_yaw -= event.relative.x * mouse_sensitivity
		_target_pitch -= event.relative.y * mouse_sensitivity
		var pitch_limit := deg_to_rad(pitch_limit_degrees)
		_target_pitch = clampf(_target_pitch, -pitch_limit, pitch_limit)


func _update_mouse_look(delta: float) -> void:
	if look_smoothing <= 0.0:
		_yaw = _target_yaw
		_pitch = _target_pitch
	else:
		var t: float = clampf(1.0 - exp(-look_smoothing * delta), 0.0, 1.0)
		_yaw = lerp_angle(_yaw, _target_yaw, t)
		_pitch = lerp_angle(_pitch, _target_pitch, t)

	rotation = Vector3(_pitch, _yaw, 0.0)


func _get_move_direction() -> Vector3:
	var input_x := 0.0
	var input_z := 0.0
	var input_y := 0.0

	if Input.is_key_pressed(KEY_D):
		input_x += 1.0
	if Input.is_key_pressed(KEY_A):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_W):
		input_z += 1.0
	if Input.is_key_pressed(KEY_S):
		input_z -= 1.0

	# Optional vertical movement (still "flying"): E/Space up, Q/Ctrl down.
	if Input.is_key_pressed(KEY_E):
		input_y += 1.0
	if Input.is_key_pressed(KEY_Q):
		input_y -= 1.0

	var input := Vector3(input_x, input_y, input_z)
	if input == Vector3.ZERO:
		return Vector3.ZERO

	var camera_basis := global_transform.basis
	var forward := -camera_basis.z
	var right := camera_basis.x
	var up := Vector3.UP

	var direction := (right * input.x) + (up * input.y) + (forward * input.z)
	return direction.normalized()
