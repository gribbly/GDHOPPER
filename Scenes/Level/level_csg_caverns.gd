## CSG cavern carving step (scene graph / geometry).
## - Used by `LevelCSG` to actually instantiate CSG subtraction shapes for caverns.
## - This file does NOT decide where caverns go; placement logic lives in `level_gen_caverns.gd`.
## - Keeping carving separate from placement makes it easier to swap the geometry technique later.
class_name LevelCSGCaverns
extends RefCounted

# Internals
var level_csg_combiner: CSGCombiner3D = null
var cavern_template: CSGMesh3D = null

func configure(combiner: CSGCombiner3D, p_cavern_template: CSGMesh3D) -> void:
	level_csg_combiner = combiner
	cavern_template = p_cavern_template

func carve_cavern(id: int, pos: Vector3, scale_xy: float) -> void:
	if level_csg_combiner == null or cavern_template == null:
		push_error("🔪 level_csg_caverns.gd | ⚠️ missing combiner/template; cannot carve cavern")
		return

	var carve_mesh := cavern_template.duplicate() as CSGMesh3D
	carve_mesh.unique_name_in_owner = false
	carve_mesh.name = "CavernCarve_%s" % id
	carve_mesh.position = Vector3(pos.x, pos.y, 0.0)
	carve_mesh.scale = Vector3(scale_xy, scale_xy, RH.CSG_THICKNESS)
	carve_mesh.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(carve_mesh)

	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_x_with_label(Vector3(pos.x, pos.y, 0.0), "cav_%s" % id, Color.WHITE)
