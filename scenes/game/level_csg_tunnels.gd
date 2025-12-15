extends RefCounted

# Implements tunneling functions for level_csg.gd

var cavern_mesh_scene := load("res://assets/models/CavernShape1.glb") as PackedScene

# Tuneables
const STEP_DISTANCE := 4.0
const DEFAULT_SIZE := 6.0

# Internals
var level_csg_combiner: Node3D = null

func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

func create_tunnel(start: Vector3, end: Vector3, size: float = DEFAULT_SIZE) -> void:
	RH.print("🪏 level_csg_tunnels | create_tunnel()", 3)
	var delta := end - start
	var dist := delta.length()

	if dist <= 0.1:
		RH.print("🪏 level_csg_tunnels | abort... distance between start and end is too short", 3)
		return
	
	var direction := delta/dist
	var steps := int(floor(dist / STEP_DISTANCE))

	# Retrieve the actual Blender mesh for tunnel carving
	var root = cavern_mesh_scene.instantiate()
	var node := root.find_child("CavernShape", true, false) # recursive, exact name
	var mi := node as MeshInstance3D

	if mi == null:
		RH.print("🪏 level_csg_tunnels | ⚠️ WARNING: mi is null!", 1)

	for i in range(steps + 1):
		var p := start + direction * (i * STEP_DISTANCE)
		
		#var box := CSGBox3D.new()
		var box := CSGMesh3D.new()
		box.mesh = mi.mesh

		if box.mesh == null:
			RH.print("🪏 level_csg_tunnels | ⚠️ WARNING: Box mesh is null!", 1)

		#var size_randomized = RH.get_random_float(size * 0.8, size * 1.2)
		#box.size = Vector3(size_randomized, size_randomized, RH.CSG_THICKNESS)
		box.scale = Vector3(DEFAULT_SIZE, DEFAULT_SIZE, RH.CSG_THICKNESS)
		box.position = p
		box.rotate_z(RH.get_random_float(0.0, 1.0))
		box.operation = CSGShape3D.OPERATION_SUBTRACTION
		level_csg_combiner.add_child(box)