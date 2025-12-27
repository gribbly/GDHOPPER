## Owns the CSG-based "carve the rock" terrain generation in `LevelCSG.tscn`.
## - `level.gd` instantiates this scene, then calls the small API below:
##   - `get_base_rock_size()` and `cavern_template_half_size_xy()` (sizing for procgen)
##   - `carve_cavern()` / `carve_tunnel_segment()` (instantiate subtraction shapes)
##   - `convert_to_mesh()` (optional bake for runtime performance)
## - Delegates cavern/tunnel carving details to `LevelCSGCaverns` / `LevelCSGTunnels`.
## - Placement/routing decisions live in the `level_gen_*.gd` files (pure logic).
class_name LevelCSG
extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Exports
@export var base_rock_material: StandardMaterial3D

# Helpers
var csg_caverns: LevelCSGCaverns = LevelCSGCaverns.new()
var csg_tunnels: LevelCSGTunnels = LevelCSGTunnels.new()
var csg_mesh: LevelCSGMesh = LevelCSGMesh.new()

# Internal
var csg: CSGCombiner3D = null # This is the combiner for the procgen CSG shapes
var base_rock_size: Vector2 = Vector2.ZERO
var _cavern_template: CSGMesh3D = null
var _tunnel_template: CSGMesh3D = null


func _ready() -> void:	
	# Find required nodes
	csg = %LevelCsgCombiner
	_cavern_template = %CavernCarve01
	_tunnel_template = %TunnelCarve01

	# Report error if we didn't find carve templates
	if _cavern_template == null or _cavern_template.mesh == null:
		push_error("🔪 level_csg.gd | ❌ Didn't find %CavernCarve01")
	if _tunnel_template == null or _tunnel_template.mesh == null:
		push_error("🔪 level_csg.gd | ❌ Didn't find %TunnelCarve01")

	csg_caverns.configure(csg, _cavern_template)
	csg_tunnels.configure(csg, _tunnel_template)

	var _base_rock_top_right_corner: Node3D = %BaseRockTopRightCorner
	if _base_rock_top_right_corner == null:
		push_error("🔪 level_csg.gd | ❌ Didn't find %BaseRockTopRightCorner")
	base_rock_size.x = _base_rock_top_right_corner.global_position.x
	base_rock_size.y = _base_rock_top_right_corner.global_position.y
	RH.print("🔪 level_csg.gd | ready() - with base_rock_size %s" % base_rock_size, 2)


func _exit_tree() -> void:
	RH.print("🔪 level_csg.gd | _exit_tree()", 4)


func get_base_rock_size() -> Vector2:
	return base_rock_size


func cavern_template_half_size_xy() -> Vector2:
	if _cavern_template == null or _cavern_template.mesh == null:
		return Vector2.ZERO
	var aabb := _cavern_template.mesh.get_aabb()
	return Vector2(aabb.size.x * 0.5, aabb.size.y * 0.5)


func carve_cavern(id: int, pos: Vector3, scale_xy: float) -> void:
	csg_caverns.carve_cavern(id, pos, scale_xy)


func carve_tunnel_segment(
	start: Vector3,
	end: Vector3,
	step_distance: float,
	base_scale_xy: float,
	size_variation: float,
	rotation_range_radians: float
) -> void:
	csg_tunnels.carve_segment(start, end, step_distance, base_scale_xy, size_variation, rotation_range_radians)


func convert_to_mesh() -> void:
	# CSG meshes are often not ready until the next frame.
	await get_tree().process_frame

	# Do the conversion
	csg_mesh.convert(csg, base_rock_material)

	# Remove CSG
	csg.queue_free()

	# Remove "carve objects"
	_cavern_template.queue_free()
	_tunnel_template.queue_free()
