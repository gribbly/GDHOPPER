class_name Missile01
extends RigidBody3D

const TIMEOUT := 10.0 # seconds

@export var fuse_time: float = 0.5
@export var turn_rate: float = 180.0
@export var thrust_amount: float = 40.0
@export var debug_logs := true
@export var impact_arm_delay: float = 0.10
@export var arm_requires_separation := true

var _dying := false
var _target: Node3D = null
var _fuse_left := 0.0
var _printed_fuse_done := false
var _printed_missing_target := false
var _impact_armed := false
var _impact_arm_left := 0.0
var _ignored_contact_ids: Dictionary = {}


func set_target(target: Node3D) -> void:
	_target = target
	if debug_logs:
		RH.print("🚀 missile_01.gd | set_target=%s (%s)" % [_node_label(target), _node_class(target)], 1)


func _ready() -> void:
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | _ready pos=%s layer=%s mask=%s" % [global_position, collision_layer, collision_mask],
			1
		)

	# Enable collision callbacks for the missile. (RigidBody3D doesn't emit body/area signals unless monitoring is enabled.)
	contact_monitor = true
	max_contacts_reported = 1

	body_entered.connect(_on_body_entered)
	body_shape_entered.connect(_on_body_shape_entered)

	_fuse_left = maxf(fuse_time, 0.0)
	_impact_arm_left = maxf(impact_arm_delay, 0.0)
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | fuse_time=%s arm_delay=%s require_separation=%s TIMEOUT=%s" % [
				fuse_time,
				impact_arm_delay,
				arm_requires_separation,
				TIMEOUT
			],
			1
		)
	get_tree().create_timer(TIMEOUT).timeout.connect(_on_timeout)


func _on_timeout() -> void:
	_die("timeout")


func _on_body_entered(body: Node) -> void:
	if body == self:
		return
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | body_entered body=%s (%s) fuse_left=%s" % [_node_label(body), _node_class(body), _fuse_left],
			1
		)
	_try_die_on_impact("body_entered", body)


func _on_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, _local_shape_index: int) -> void:
	if body == self:
		return
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | body_shape_entered body=%s (%s) fuse_left=%s" % [_node_label(body), _node_class(body), _fuse_left],
			1
		)
	_try_die_on_impact("body_shape_entered", body)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _dying:
		return

	var step := state.step
	_update_impact_arming(state, step)
	_check_new_body_contacts_for_impact(state)

	if _fuse_left > 0.0:
		_fuse_left -= step
		return
	elif debug_logs and not _printed_fuse_done:
		_printed_fuse_done = true
		RH.print("🚀 missile_01.gd | fuse done; starting homing", 1)

	if _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		if debug_logs and not _printed_missing_target:
			_printed_missing_target = true
			RH.print("🚀 missile_01.gd | no valid target: %s (%s)" % [_node_label(_target), _node_class(_target)], 1)
		return

	var origin := state.transform.origin
	var to := _target.global_position - origin
	to.z = 0.0
	if to.length_squared() < 0.0001:
		return

	var desired_z := atan2(to.y, to.x) - (PI * 0.5)

	var forward := state.transform.basis.y.normalized()
	forward.z = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.UP
	var current_z := atan2(forward.y, forward.x) - (PI * 0.5)

	var max_step := deg_to_rad(maxf(turn_rate, 0.0)) * step
	var next_z := _move_toward_angle(current_z, desired_z, max_step)

	var xform := state.transform
	xform.origin.z = 0.0
	xform.basis = Basis(Vector3(0.0, 0.0, 1.0), next_z)
	state.transform = xform

	var thrust_dir := xform.basis.y.normalized()
	thrust_dir.z = 0.0
	state.apply_central_force(thrust_dir * maxf(thrust_amount, 0.0))


func _move_toward_angle(current: float, target: float, max_delta: float) -> float:
	var diff := wrapf(target - current, -PI, PI)
	if absf(diff) <= max_delta:
		return target
	return current + signf(diff) * max_delta


func _update_impact_arming(state: PhysicsDirectBodyState3D, step: float) -> void:
	if _impact_armed:
		return

	if _impact_arm_left > 0.0:
		_impact_arm_left -= step
		return

	var contacts := _get_current_contact_ids(state)
	if arm_requires_separation and not contacts.is_empty():
		return

	_impact_armed = true
	_ignored_contact_ids = {}
	for id in contacts:
		_ignored_contact_ids[id] = true

	if debug_logs:
		RH.print("🚀 missile_01.gd | impact ARMED; ignoring=%s" % [_ignored_contact_ids.size()], 1)


func _check_new_body_contacts_for_impact(state: PhysicsDirectBodyState3D) -> void:
	if not _impact_armed:
		return

	var contact_count := state.get_contact_count()
	for i in range(contact_count):
		var obj := state.get_contact_collider_object(i)
		if obj == null:
			continue
		if obj is Object and not is_instance_valid(obj):
			continue

		var id := (obj as Object).get_instance_id()
		if _ignored_contact_ids.has(id):
			continue

		_die("impact_contact", obj as Node)
		return


func _get_current_contact_ids(state: PhysicsDirectBodyState3D) -> Array[int]:
	var ids: Array[int] = []
	var contact_count := state.get_contact_count()
	for i in range(contact_count):
		var obj := state.get_contact_collider_object(i)
		if obj == null:
			continue
		if obj is Object and not is_instance_valid(obj):
			continue
		ids.append((obj as Object).get_instance_id())
	return ids


func _try_die_on_impact(reason: String, other: Node) -> void:
	if not _impact_armed:
		return
	if other != null and is_instance_valid(other):
		var id := other.get_instance_id()
		if _ignored_contact_ids.has(id):
			return
	_die(reason, other)

func _die(reason: String, other: Node = null) -> void:
	if _dying:
		return
	_dying = true
	if debug_logs:
		RH.print(
			"🚀 missile_01.gd | DIE reason=%s other=%s (%s) pos=%s vel=%s" % [
				reason,
				_node_label(other),
				_node_class(other),
				global_position,
				linear_velocity
			],
			1
		)
	call_deferred("queue_free")


func _node_label(node: Node) -> String:
	if node == null:
		return "<null>"
	if not is_instance_valid(node):
		return "<invalid>"
	if node.is_inside_tree():
		return str(node.get_path())
	return str(node.name)


func _node_class(node: Variant) -> String:
	if node == null:
		return "<null>"
	if node is Object and not is_instance_valid(node):
		return "<invalid>"
	if node is Object:
		return (node as Object).get_class()
	return str(typeof(node))
