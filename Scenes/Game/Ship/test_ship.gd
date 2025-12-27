extends RigidBody3D

@export var thrust_main := 20.0
@export var thrust_left := 20.0
@export var thrust_right := 20.0
@export var ship_hull_collision_main: CollisionShape3D = null
@export var ship_hull_collision_left: CollisionShape3D = null
@export var ship_hull_collision_right: CollisionShape3D = null
@export var ship_info_panel: PackedScene = null

const Explosion01Scene := preload("res://Scenes/Game/Effects/Explosion01.tscn")

# Simple state machine.
enum ShipState { FLYING, CRASHED }

# Tuneables
const THRUST_LIGHT_ENERGY := 32.0
const FLICKER_ARRAY_LENGTH := 32
const FLICKER_TICK := 10

# Internal
var _base_mass := 0.0
var _inventory: ShipInventory = ShipInventory.new()
var _state: ShipState = ShipState.FLYING
var thrust_side := 0.0
var reset_requested := false
@onready var thrust_particles_left: GPUParticles3D = %ThrustParticles_left
@onready var thrust_particles_right: GPUParticles3D = %ThrustParticles_right
@onready var thrust_light_left: SpotLight3D = %ThrustLight_left
@onready var thrust_light_right: SpotLight3D = %ThrustLight_right
@onready var pickup_area: Area3D = %PickupArea
var flicker_array = []
var flicker_index := 0
var flicker_tick := 0
var _ship_info_panel: Control = null

func _ready() -> void:
	RH.print("🚀 test_ship.gd | ready()", 2)
	add_to_group("ship")

	_base_mass = mass

	# Enable collision callbacks for the ship. (RigidBody3D doesn't emit body/area signals unless monitoring is enabled.)
	contact_monitor = true
	max_contacts_reported = 1
	body_shape_entered.connect(_on_ship_body_shape_entered)

	var hull_colliders := _get_ship_hull_colliders()
	if hull_colliders.is_empty():
		push_error("🚀 test_ship.gd | ❌ ERROR: No ship_hull_collision_* assigned; ship collision filtering may be wrong")
	elif hull_colliders.size() < 3:
		push_warning("🚀 test_ship.gd | ⚠️ Only %d ship_hull_collision_* assigned; others will be ignored" % hull_colliders.size())

	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)

	RH.print("🚀 test_ship.gd | generating thrust_light_* flicker arrays", 4)
	for i in range(0, FLICKER_ARRAY_LENGTH):
		flicker_array.append(RH.get_random_float(0.0, THRUST_LIGHT_ENERGY))

	RH.print("🚀 test_ship.gd | creating ship info panel", 2)
	_ship_info_panel = ship_info_panel.instantiate()
	_ship_info_panel.set_ship(self)
	RH.get_overlay_layer().add_child(_ship_info_panel)
	
	reset()

func _exit_tree() -> void:
	RH.print("🚀 test_ship.gd | removing ship info panel", 2)
	_ship_info_panel.queue_free()

func reset() -> void:
	RH.print("🚀 test_ship.gd | reset", 3)
	_set_state(ShipState.FLYING)
	position.z = 0.0
	transform.basis = Basis.IDENTITY
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	thrust_light_left.visible = false
	thrust_light_right.visible = false
	flicker_tick = 0
	flicker_index = 0
	reset_requested = false


func _unhandled_input(event: InputEvent) -> void:
	if _state != ShipState.FLYING:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_S:
				reset_requested = true
			KEY_I:
				drop_last_cargo()


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body == self:
		return
	var cargo := body as CargoPickup
	if cargo == null or not cargo.pickup_enabled:
		return

	var scene_path := cargo.get_respawn_scene_path()
	if scene_path.is_empty():
		RH.print("🚀 test_ship.gd | ⚠️ cargo has no scene_file_path; cannot add to inventory", 1)
		return

	_inventory.add_item(scene_path, cargo.get_pickup_mass(), cargo.name)
	cargo.queue_free()
	_update_mass_from_inventory()


func _on_pickup_area_body_exited(body: Node3D) -> void:
	var cargo := body as CargoPickup
	if cargo == null:
		return
	cargo.pickup_enabled = true


func drop_last_cargo() -> void:
	var item := _inventory.pop_last()
	if item == null:
		return

	_update_mass_from_inventory()

	var packed := load(item.scene_path) as PackedScene
	if packed == null:
		push_warning("🚀 test_ship.gd | ⚠️ could not load cargo scene: %s" % item.scene_path)
		return

	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("🚀 test_ship.gd | ⚠️ cargo scene did not instantiate as Node3D: %s" % item.scene_path)
		return

	var parent := get_parent()
	if parent == null:
		instance.queue_free()
		return

	parent.add_child(instance)
	var up_dir := transform.basis.y.normalized()
	var right_dir := transform.basis.x.normalized()
	var side_sign := -1.0 if RH.get_random_float(0.0, 1.0) < 0.5 else 1.0

	var spawn_offset := up_dir * 6.0 + right_dir * side_sign * 4.0
	spawn_offset += up_dir * RH.get_random_float(-0.5, 0.5)
	spawn_offset += right_dir * RH.get_random_float(-0.75, 0.75)

	instance.global_position = global_position + spawn_offset
	instance.global_position.z = 0.0

	var cargo_rb := instance as RigidBody3D
	if cargo_rb != null:
		cargo_rb.linear_velocity = linear_velocity
		cargo_rb.angular_velocity = Vector3.ZERO

		var throw_impulse := up_dir * RH.get_random_float(200.0, 320.0)
		throw_impulse += right_dir * side_sign * RH.get_random_float(160.0, 260.0)
		throw_impulse += Vector3(RH.get_random_float(-40.0, 40.0), RH.get_random_float(-40.0, 40.0), 0.0)
		cargo_rb.apply_central_impulse(throw_impulse)
		cargo_rb.apply_torque_impulse(Vector3(0.0, 0.0, RH.get_random_float(-40.0, 40.0)))

	var cargo := instance as CargoPickup
	if cargo != null:
		# Prevent immediate re-pickup; cargo must leave the pickup area first.
		cargo.pickup_enabled = false


func _update_mass_from_inventory() -> void:
	mass = _base_mass + _inventory.total_mass()


func _physics_process(delta):
	if _state != ShipState.FLYING:
		return

	# Handle reset request
	if reset_requested:
		reset()

	# DEBUG - mark ship position every frame
	# RH.debug_visuals.rh_debug_x_with_label_frame(position, "SHIP", Color.PINK)
	
	# Side thrust - rotate around Z axis
	var rot_input := 0.0
	if Input.is_action_pressed("thrust_left"):
		rot_input += 1.0
		thrust_side = thrust_left
		_start_left_thrust_VFX()
	if Input.is_action_pressed("thrust_right"):
		rot_input -= 1.0
		thrust_side = thrust_right
		_start_right_thrust_VFX()
	if rot_input != 0.0:
		apply_torque(Vector3(0, 0, rot_input * thrust_side * delta))

	# Main thrust (along local up)
	var thrusting := Input.is_action_pressed("thrust_main")
	if thrusting:
		var up_dir := transform.basis.y
		apply_central_force(up_dir * thrust_main)

		if thrusting:
			_start_left_thrust_VFX()
			_start_right_thrust_VFX()

		# ...with flickering
		flicker_tick += 1
		if flicker_tick > FLICKER_TICK:
			var a = flicker_index % (FLICKER_ARRAY_LENGTH - 1)
			var b = (flicker_index + 1) % (FLICKER_ARRAY_LENGTH - 1)
			thrust_light_left.light_energy = flicker_array[a]
			thrust_light_right.light_energy = flicker_array[b]
			flicker_index += 1
			flicker_tick = 0
			
			# Defensive: Zero flicker_index when it gets too large
			if flicker_index > FLICKER_TICK * 100:
				flicker_index = 0
	else:
		if rot_input < 0.0:
			_stop_left_thrust_VFX()
		if rot_input > 0.0:
			_stop_right_thrust_VFX()
		if rot_input == 0.0:
			_stop_left_thrust_VFX()
			_stop_right_thrust_VFX()

func _set_state(new_state: ShipState) -> void:
	if _state == new_state:
		return

	_state = new_state
	match _state:
		ShipState.FLYING:
			RH.print("🚀 test_ship.gd | state = Flying", 1)
		ShipState.CRASHED:
			RH.print("🚀 test_ship.gd | state = Crashed", 1)
			reset_requested = false
			_stop_left_thrust_VFX()
			_stop_right_thrust_VFX()
			# apply_torque_impulse(Vector3(0.0, 0.0, RH.get_random_float(-120.0, 120.0)))
			_spawn_crash_explosions(global_position)


func _spawn_crash_explosions(crash_pos: Vector3) -> void:
	var parent := get_parent()
	if parent == null:
		return

	var count := RH.get_random_int(8, 16)
	var max_total_frames := 20
	var frame_offsets: Array[int] = []
	frame_offsets.resize(count)
	frame_offsets[0] = 0 # first explosion immediately
	for i in range(1, count):
		frame_offsets[i] = RH.get_random_int(1, max_total_frames)
	frame_offsets.sort()

	var current_offset := 0
	for frame_offset in frame_offsets:
		var wait_frames := frame_offset - current_offset
		current_offset = frame_offset
		for _f in range(wait_frames):
			await get_tree().process_frame

		var explosion := Explosion01Scene.instantiate() as Node3D
		if explosion == null:
			continue

		explosion.prime() #set up first frame white flash
		parent.add_child(explosion)

		var spread := 4.0
		var offset := Vector3(
			RH.get_random_float(-spread, spread),
			RH.get_random_float(-spread, spread),
			0.0
		)
		explosion.global_position = crash_pos + offset
		explosion.global_position.z = 0.0

		var uniform_scale := RH.get_random_float(0.5, 1.0)
		explosion.scale = Vector3.ONE * uniform_scale
		#explosion.rotation.z = RH.get_random_float(0.0, TAU)


func _crash() -> void:
	if _state == ShipState.CRASHED:
		return
	_set_state(ShipState.CRASHED)

func _get_ship_hull_colliders() -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	if ship_hull_collision_main != null:
		out.append(ship_hull_collision_main)
	if ship_hull_collision_left != null:
		out.append(ship_hull_collision_left)
	if ship_hull_collision_right != null:
		out.append(ship_hull_collision_right)
	return out


func _is_ship_collision_shape(local_shape_index: int) -> bool:
	var hull_colliders := _get_ship_hull_colliders()
	if hull_colliders.is_empty():
		return true

	var owner_id := shape_find_owner(local_shape_index)
	if owner_id == -1:
		return true
	var shape_owner_node := shape_owner_get_owner(owner_id)
	if shape_owner_node == null:
		return true
	return shape_owner_node == self or hull_colliders.has(shape_owner_node)


func _on_ship_body_shape_entered(_body_rid: RID, body: Node, _body_shape_index: int, local_shape_index: int) -> void:
	if _state != ShipState.FLYING:
		return
	if body == self:
		return
	if not _is_ship_collision_shape(local_shape_index):
		return
	_crash()


func _start_left_thrust_VFX() -> void:
	thrust_particles_left.start()
	thrust_light_left.visible = true

func _start_right_thrust_VFX() -> void:
	thrust_particles_right.start()
	thrust_light_right.visible = true

func _stop_left_thrust_VFX() -> void:
	thrust_particles_left.stop()
	thrust_light_left.visible = false

func _stop_right_thrust_VFX() -> void:
	thrust_particles_right.stop()
	thrust_light_right.visible = false
