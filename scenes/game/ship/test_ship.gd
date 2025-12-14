extends RigidBody3D

@export var thrust_main := 20.0
@export var thrust_left := 20.0
@export var thrust_right := 20.0

# Internal
var thrust_side := 0.0

func _ready() -> void:
	RH.print("🚀 test_ship.gd | ready")
	pass # Replace with function body.

func reset() -> void:
	RH.print("🚀 test_ship.gd | reset")
	position.z = 0.0
	transform.basis = Basis.IDENTITY

func _physics_process(delta):

	# Debug reset
	if Input.is_physical_key_pressed(KEY_S):
		reset()
	
	# Rotate (Z axis into the screen)
	var rot_input := 0.0
	if Input.is_action_pressed("thrust_left"):
		rot_input += 1.0
		thrust_side = thrust_left
	if Input.is_action_pressed("thrust_right"):
		rot_input -= 1.0
		thrust_side = thrust_right
	if rot_input != 0.0:
		apply_torque(Vector3(0, 0, rot_input * thrust_side * delta))

	# Thrust (along local up)
	var thrusting := Input.is_action_pressed("thrust_main")
	if thrusting:
		var up_dir := transform.basis.y
		apply_central_force(up_dir * thrust_main)
