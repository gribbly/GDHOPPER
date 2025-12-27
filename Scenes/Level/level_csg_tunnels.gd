## CSG tunnel carving step (scene graph / geometry).
## - Used by `LevelCSG` to instantiate repeated subtraction shapes along a tunnel segment.
## - This file does NOT decide tunnel routes; routing logic lives in `level_gen_tunnel_paths.gd`.
class_name LevelCSGTunnels
extends RefCounted

# Internals
var level_csg_combiner: CSGCombiner3D = null
var tunnel_template: CSGMesh3D = null

func configure(combiner: CSGCombiner3D, p_tunnel_template: CSGMesh3D) -> void:
	level_csg_combiner = combiner
	tunnel_template = p_tunnel_template

func carve_segment(
	start: Vector3,
	end: Vector3,
	step_distance: float,
	base_scale_xy: float,
	size_variation: float,
	rotation_range_radians: float
) -> void:
	RH.print("🪏 level_csg_tunnels.gd | carve_segment()", 4)
	if level_csg_combiner == null or tunnel_template == null:
		push_error("🪏 level_csg_tunnels.gd | ⚠️ missing combiner/template; cannot carve tunnel")
		return

	var delta := end - start
	var dist := delta.length()

	if dist <= 0.1:
		RH.print("🪏 level_csg_tunnels.gd | ⚠️ carve_segment() early out. Distance between start and end is too short", 2)
		return
	
	var direction := delta/dist
	var actual_step_distance := maxf(step_distance, 0.1)
	var steps := int(floor(dist / actual_step_distance))

	for i in range(steps + 1):
		var p := start + direction * (i * actual_step_distance)

		var carve_mesh := tunnel_template.duplicate() as CSGMesh3D
		carve_mesh.unique_name_in_owner = false
		var variation := clampf(size_variation, 0.0, 1.0)
		var scale_xy := base_scale_xy * (1.0 + RH.get_random_float(-variation, variation))
		carve_mesh.scale = Vector3(scale_xy, scale_xy, RH.CSG_THICKNESS)
		carve_mesh.position = p
		carve_mesh.rotate_z(RH.get_random_float(0.0, rotation_range_radians))
		carve_mesh.operation = CSGShape3D.OPERATION_SUBTRACTION
		level_csg_combiner.add_child(carve_mesh)
