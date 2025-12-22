extends RefCounted

# Implements tunneling functions for level_csg.gd

# Tuneables
var carve_mesh_scene := load("res://Assets/JunkDrawer/Models/TunnelCarve1.glb") as PackedScene
const STEP_DISTANCE := 4.0
const DEFAULT_SIZE := 2.0

# Internals
var level_csg_combiner: Node3D = null

func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

func create_tunnel(start: Vector3, end: Vector3, scale: float = 1.0) -> void:
	RH.print("🪏 level_csg_tunnels | create_tunnel()", 3)
	var delta := end - start
	var dist := delta.length()

	if dist <= 0.1:
		RH.print("🪏 level_csg_tunnels | abort... distance between start and end is too short", 3)
		return
	
	var direction := delta/dist
	var steps := int(floor(dist / STEP_DISTANCE))

	# Retrieve the actual Blender mesh for tunnel carving
	var root = carve_mesh_scene.instantiate()
	var node := root.find_child("TunnelCarve", true, false) # recursive, exact name
	var mi := node as MeshInstance3D

	if mi == null:
		RH.print("🪏 level_csg_tunnels | ⚠️ WARNING: MeshInstance3D is null!", 1)

	for i in range(steps + 1):
		var p := start + direction * (i * STEP_DISTANCE)

		var carve_mesh := CSGMesh3D.new()
		carve_mesh.mesh = mi.mesh

		if carve_mesh.mesh == null:
			RH.print("🪏 level_csg_tunnels | ⚠️ WARNING: CSGMesh3D is null!", 1)

		var carve_mesh_scale = DEFAULT_SIZE * scale * RH.get_random_float(0.8, 1.2)
		carve_mesh.scale = Vector3(carve_mesh_scale, carve_mesh_scale, RH.CSG_THICKNESS)
		carve_mesh.position = p
		carve_mesh.rotate_z(RH.get_random_float(0.0, 1.0))
		carve_mesh.operation = CSGShape3D.OPERATION_SUBTRACTION
		level_csg_combiner.add_child(carve_mesh)