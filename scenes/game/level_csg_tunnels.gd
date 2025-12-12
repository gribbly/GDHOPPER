extends RefCounted

# Implements "tunneling functions" for level_csg.gd

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
	tunnel.size = Vector3(32, 32, 64)
	tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(tunnel)
