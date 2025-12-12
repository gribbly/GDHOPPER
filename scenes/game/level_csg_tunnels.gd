extends RefCounted

# Implements "tunneling functions" for level_csg.gd

func init() -> void:
    RH.print("level_csg_tunnels | init()", 1)

    var x = RH.get_random_float(0.0, 100.0)
    var y = RH.get_random_float(0.0, 100.0)
    RH.debug_visuals.rh_debug_x_with_label(Vector3(x, y, 0.0), "level_csg_tunnels")