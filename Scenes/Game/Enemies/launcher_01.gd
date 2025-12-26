extends Node3D

@export var missile: PackedScene
@export var sensing_range: float = 5.0
@export var fire_rate: float = 3.0
@export var missile_impulse: float = 240.0
@export var missile_spawn_offset: Vector3 = Vector3(0.0, 2.0, 0.0)

const _SHIP_GROUP := "ship"

var _ship: Node3D = null
var _ship_in_range := false
var _fire_timer: Timer = null


func _ready() -> void:
	_fire_timer = Timer.new()
	_fire_timer.one_shot = false
	_fire_timer.autostart = false
	_fire_timer.wait_time = maxf(fire_rate, 0.05)
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_on_fire_timer_timeout)


func _physics_process(_delta: float) -> void:
	if _fire_timer == null:
		return

	_fire_timer.wait_time = maxf(fire_rate, 0.05)
	_ship = _get_ship_if_needed()

	var ship_sensed := _is_ship_sensed(_ship)
	if ship_sensed and not _ship_in_range:
		_ship_in_range = true
		_fire_timer.start()
		_fire_once()
	elif not ship_sensed and _ship_in_range:
		_ship_in_range = false
		_fire_timer.stop()


func _get_ship_if_needed() -> Node3D:
	if is_instance_valid(_ship) and _ship.is_inside_tree():
		return _ship
	return get_tree().get_first_node_in_group(_SHIP_GROUP) as Node3D


func _is_ship_sensed(ship: Node3D) -> bool:
	if ship == null:
		return false
	if not is_instance_valid(ship) or not ship.is_inside_tree():
		return false
	if sensing_range <= 0.0:
		return false

	var a := global_position
	var b := ship.global_position
	a.z = 0.0
	b.z = 0.0
	return a.distance_squared_to(b) <= sensing_range * sensing_range


func _on_fire_timer_timeout() -> void:
	_ship = _get_ship_if_needed()
	if not _is_ship_sensed(_ship):
		_ship_in_range = false
		if _fire_timer != null:
			_fire_timer.stop()
		return
	_fire_once()


func _fire_once() -> void:
	if missile == null:
		RH.print("🚀 launcher_01.gd | ⚠️ no missile PackedScene set", 1)
		return
	if _ship == null:
		return

	var parent := get_parent()
	if parent == null:
		return

	var missile_instance := missile.instantiate() as Node3D
	if missile_instance == null:
		RH.print("🚀 launcher_01.gd | ⚠️ missile did not instantiate as Node3D", 1)
		return

	parent.add_child(missile_instance)
	missile_instance.global_position = global_position + missile_spawn_offset
	missile_instance.global_position.z = 0.0

	# Avoid hard dependency on a global `class_name` (Godot may not have it cached yet).
	if missile_instance.has_method("set_target"):
		missile_instance.call("set_target", _ship)

	var missile_rb := missile_instance as RigidBody3D
	if missile_rb == null:
		RH.print("🚀 launcher_01.gd | ⚠️ missile is not a RigidBody3D", 1)
		return

	var impulse := Vector3.UP.normalized() * missile_impulse
	impulse += Vector3(
		RH.get_random_float(-20.0, 20.0),
		RH.get_random_float(-20.0, 20.0),
		0.0
	)
	missile_rb.apply_central_impulse(impulse)
