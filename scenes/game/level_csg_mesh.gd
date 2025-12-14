extends RefCounted

# Implements meshing functions for level_csg.gd

func convert(csg: CSGCombiner3D) -> Node3D:
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

		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_trimesh_shape() # concave: good for static level geo
		body.add_child(shape)
		mi.add_child(body)

	# Put baked result where the CSG was in the world
	root.global_transform = csg.global_transform
	csg.get_parent().add_child(root)

	return root