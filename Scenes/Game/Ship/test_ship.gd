extends RigidBody3D

@export var thrust_main := 20.0
@export var thrust_left := 20.0
@export var thrust_right := 20.0

# Tuneables
const THRUST_LIGHT_ENERGY := 32.0
const FLICKER_ARRAY_LENGTH := 32
const FLICKER_TICK := 10

# Internal
var thrust_side := 0.0
var reset_requested := false
@onready var thrust_particles_left: GPUParticles3D = %ThrustParticles_left
@onready var thrust_particles_right: GPUParticles3D = %ThrustParticles_right
@onready var thrust_light_left: SpotLight3D = %ThrustLight_left
@onready var thrust_light_right: SpotLight3D = %ThrustLight_right
var flicker_array = []
var flicker_index := 0
var flicker_tick := 0


func _ready() -> void:
	RH.print("🚀 test_ship.gd | ready")

	RH.print("🚀 test_ship.gd | generating thrust_light_* flicker arrays", 5)
	for i in range(0, FLICKER_ARRAY_LENGTH):
		flicker_array.append(RH.get_random_float(0.0, THRUST_LIGHT_ENERGY))
	
	reset()


func reset() -> void:
	RH.print("🚀 test_ship.gd | reset")
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
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_S:
				reset_requested = true


func _physics_process(delta):
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
