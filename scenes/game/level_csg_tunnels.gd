extends RefCounted

# Implements "tunneling functions" for level_csg.gd

# Tuneables
var csg_thickness := 32.0
var step_distance := 4.0

# Internals
var level_csg_combiner: Node3D = null


func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

func tunnel_test() -> void:
	RH.print("level_csg_tunnels | tunnel_test()", 3)
	var pos_x = RH.get_random_float(0.0, 100.0)
	var pos_y = RH.get_random_float(0.0, 100.0)
	RH.debug_visuals.rh_debug_x_with_label(Vector3(pos_x, pos_y, 0.0), "tunnel_test")

	var tunnel := CSGBox3D.new()
	tunnel.position = Vector3(pos_x, pos_y, 0.0)
	tunnel.size = Vector3(8, 8, 64)
	tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(tunnel)

func create_tunnel(start: Vector3, end: Vector3, size: float = 8.0) -> void:
	RH.print("level_csg_tunnels | create_tunnel()", 3)
	var delta := end - start
	var dist := delta.length()

	if dist <= 0.1:
		RH.print("level_csg_tunnels | abort... distance between start and end is too short", 3)
		return
	
	var direction := delta/dist
	var steps := int(floor(dist / step_distance))

	for i in range(steps + 1):
		var p := start + direction * (i * step_distance)

		var box := CSGBox3D.new()
		box.size = Vector3(size, size, 64.0)
		box.position = p
		box.operation = CSGShape3D.OPERATION_SUBTRACTION
		level_csg_combiner.add_child(box)