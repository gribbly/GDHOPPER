class_name Missile01
extends RigidBody3D

const TIMEOUT := 10.0 # seconds

@export var fuse_time: float = 0.5
@export var thrust_amount: float = 40.0
@export var debug_logs := true
@export var impact_arm_delay: float = 0.10
@export var explosion: PackedScene
@export var impact_impulse: float = 1000.0
@export var missile_visuals: Node3D = null
@export var missile_thrust_vfx: GPUParticles3D = null

# Internals
var _dying := false
var _target: Node3D = null
var _fuse_left := 0.0
var _engine_started := false
var _impact_armed := false
var _impact_arm_left := 0.0

func set_target(target: Node3D) -> void:
	_target = target

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	_fuse_left = fuse_time
	_impact_arm_left = impact_arm_delay
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)
	missile_thrust_vfx.emitting = false


func _on_timeout() -> void:
	_die("timeout", null)


func _on_body_entered(body: Node) -> void:
	if debug_logs:
		RH.print( "🚀 missile_01.gd | body_entered body=%s fuse_left=%s" % [body, _fuse_left], 1)
	
	if not _impact_armed:
		RH.print( "🚀 missile_01.gd | body_entered - not _impact_armed. Returning", 1)
		return
	else:
		_die("body_entered", body)


func _physics_process(delta: float) -> void:
	if _dying:
		return

	# Look at (cosmetic only)
	missile_visuals.look_at(_target.global_position)

	_update_impact_arming(delta)

	if _fuse_left > 0.0:
		_fuse_left -= delta
		return
	elif debug_logs and not _engine_started:
		_engine_started = true
		missile_thrust_vfx.emitting = true
		RH.print("🚀 missile_01.gd | fuse done; starting engine!", 1)

	# Homing behavior
	var _target_direction := _target.global_position - transform.origin
	_target_direction.z = 0.0
	if _target_direction.length_squared() < 0.0001:
		return

	apply_central_force(_target_direction * thrust_amount)

func _update_impact_arming(delta: float) -> void:
	if _impact_armed:
		return

	if _impact_arm_left > 0.0:
		_impact_arm_left -= delta
		return

	_impact_armed = true

	if debug_logs:
		RH.print("🚀 missile_01.gd | impact ARMED", 1)


func _die( reason: String, other: Node = null) -> void:
	if _dying:
		return
	_dying = true

	_spawn_explosion()
	_apply_physics_push(other)

	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | DIE reason=%s other=%s pos=%s vel=%s" % [
				reason,
				other,
				global_position,
				linear_velocity
			],
			1
		)
	call_deferred("queue_free")

func _spawn_explosion() -> void:
	if explosion == null: return

	var explosion_instance := explosion.instantiate() as Node3D
	explosion_instance.prime()
	explosion_instance.position = global_position
	RH.get_level_node().add_child(explosion_instance)


func _apply_physics_push(other: Node) -> void:
	var body := other as RigidBody3D
	if body == null:
		return

	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | _apply_physics_push other=%s pos=%s vel=%s" % [
				other,
				global_position,
				linear_velocity
			],
			1
		)

	var _impulse_direction := body.global_position - transform.origin
	_impulse_direction.z = 0.0

	var impulse := _impulse_direction.normalized() * impact_impulse

	body.apply_central_impulse(impulse)
