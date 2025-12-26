class_name Missile01
extends RigidBody3D

const TIMEOUT := 10.0 # seconds

@export var fuse_time: float = 0.5
@export var thrust_amount: float = 40.0
@export var debug_logs := true
@export var impact_arm_delay: float = 0.10
@export var explosion: PackedScene
@export var impact_push_multiplier: float = 1.0
@export var max_impact_impulse: float = 200.0

@onready var missile_visuals: Node3D = %MissileVisuals

# Internals
var _dying := false
var _target: Node3D = null
var _fuse_left := 0.0
var _printed_fuse_done := false
var _impact_armed := false
var _impact_arm_left := 0.0

func set_target(target: Node3D) -> void:
	_target = target
	if debug_logs:
		RH.print("🚀 missile_01.gd | set_target=%s" % _target, 1)


func _ready() -> void:
	if debug_logs:
		RH.print( "🚀 missile_01.gd | _ready pos=%s layer=%s mask=%s" % [global_position, collision_layer, collision_mask], 1)
		if missile_visuals == null:
			RH.print( "🚀 missile_01.gd | ❌ ERROR - %MissileVisuals is null", 1)
		if explosion == null:
			RH.print( "🚀 missile_01.gd | ⚠️ WARNING - explosion is null", 1)

	# Enable collision callbacks for the missile. (RigidBody3D doesn't emit body/area signals unless monitoring is enabled.)
	contact_monitor = true
	max_contacts_reported = 1

	body_entered.connect(_on_body_entered)

	_fuse_left = fuse_time
	_impact_arm_left = impact_arm_delay
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | fuse_time=%s arm_delay=%s TIMEOUT=%s" % [
				fuse_time,
				impact_arm_delay,
				TIMEOUT
			],
			1
		)
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)


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
	elif debug_logs and not _printed_fuse_done:
		_printed_fuse_done = true
		RH.print("🚀 missile_01.gd | fuse done; starting homing", 1)

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
	if debug_logs:
		if explosion:
			RH.print("🚀 _spawn_explosion | explosion = %s " % explosion, 1)
		else:
			RH.print("🚀 _spawn_explosion | early out because explosion is null", 1)

	var explosion_instance := explosion.instantiate() as Node3D
	explosion_instance.prime()
	explosion_instance.position = global_position

	RH.get_level_node().add_child(explosion_instance)


func _apply_physics_push(other: Node) -> void:
	var body := other as RigidBody3D
	if body == null:
		return

	var rel_vel := linear_velocity - body.linear_velocity
	rel_vel.z = 0.0
	if rel_vel.length_squared() < 0.0001:
		return

	var impulse := rel_vel * mass * impact_push_multiplier
	var max_impulse := maxf(max_impact_impulse, 0.0)
	if max_impulse > 0.0:
		impulse = impulse.limit_length(max_impulse)

	# Apply at contact point when possible (adds some torque for "realism").
	#body.apply_impulse(impulse, body.to_local(hit_pos))
	body.apply_central_impulse(impulse)
