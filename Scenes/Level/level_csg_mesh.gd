## CSG-to-mesh baking step (performance).
## - Converts a `CSGCombiner3D` result into regular `MeshInstance3D` nodes with material + collision.
## - Called by `LevelCSG.convert_to_mesh()` when `Level` enables baking.
class_name LevelCSGMesh
extends RefCounted

const MATERIAL_TILING = 0.048
var albedo_tex := load("res://Assets/JunkDrawer/Textures/noise_256.webp") as Texture2D
var normal_tex := load("res://Assets/JunkDrawer/Textures/noise_256_norm.webp") as Texture2D
var rough_tex := load("res://Assets/JunkDrawer/Textures/rock_weathered_15b_spec.webp") as Texture2D

func convert(csg: CSGCombiner3D, _mat: StandardMaterial3D = null) -> Node3D:
	RH.print("🫖 level_csg_mesh.gd | convert()")

	var meshes = csg.get_meshes() # [Transform3D, Mesh, Transform3D, Mesh, ...]
	if meshes.size() < 2 or meshes[1] == null:
		push_error("CSG bake failed: no mesh generated yet.")
		return null

	var root := Node3D.new()
	root.name = "%s_Baked" % csg.name

	for i in range(0, meshes.size(), 2):
		var local_xform: Transform3D = meshes[i]
		var mesh: Mesh = meshes[i + 1]
		if mesh == null:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.transform = local_xform
		root.add_child(mi)

		# Material handling
		var mat := StandardMaterial3D.new()

		if _mat == null:
			mat.albedo_texture = albedo_tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			
			mat.normal_enabled = true
			mat.normal_texture = normal_tex
			mat.normal_scale = 0.5
		else:
			mat = _mat

		# “Projected” look (no UVs needed)
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3(MATERIAL_TILING, MATERIAL_TILING, MATERIAL_TILING) # tiling amount; tweak

		# Apply material
		mi.material_override = mat

		# Collision
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_trimesh_shape() # concave: good for static level geo
		body.add_child(shape)
		mi.add_child(body)

	# Put baked result where the CSG was in the world
	root.global_transform = csg.global_transform
	csg.get_parent().add_child(root)

	return root
