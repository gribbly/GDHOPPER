extends RefCounted

# Implements cavern creation functions for level_csg.gd

var caverns: Dictionary[String, CavernData] = {} # Dictionary of caverns by name

# Tuneables
var carve_mesh_scene := load("res://Assets/JunkDrawer/Models/TunnelCarve1.glb") as PackedScene
const CAVERN_SIZE_SMALL := 2.0
const CAVERN_SIZE_MEDIUM := 4.0
const CAVERN_SIZE_LARGE := 8.0

# Internals
var level_csg_combiner: Node3D = null
var _index := 0
var cav_scale := 0.0
var mi: MeshInstance3D


func _init() -> void:
	# Retrieve the actual Blender mesh for cavern carving
	var root = carve_mesh_scene.instantiate()
	var node := root.find_child("TunnelCarve", true, false) # recursive, exact name
	mi = node as MeshInstance3D

func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

# 'cav_scale_class' is an int. 1 = small, 2 = medium, 3 = large
func create_cavern(cav_name: String, cav_scale_class: int, cav_pos: Vector3) -> void:
	RH.print("🔪 level_csg_caverns.gd | create_cavern()")

	if cav_name == "": cav_name = "cavern" # Default name if none supplied

	match cav_scale_class:
		1:
			cav_scale = CAVERN_SIZE_SMALL
		2:
			cav_scale = CAVERN_SIZE_MEDIUM
		3:
			cav_scale = CAVERN_SIZE_LARGE

	caverns[cav_name] = CavernData.new(_index, cav_scale, cav_pos)
	_index += 1

	_carve_cavern(cav_name, cav_pos)

func _carve_cavern(cav_name: String, cav_pos: Vector3) -> void:
	RH.print("🔪 level_csg_caverns.gd | creating acarve_meshn...")

	if mi == null:
		RH.print("🪏 level_csg_tunnels | ⚠️ WARNING: MeshInstance3D is null!", 1)
	
	#var cavern := CSGBox3D.new()
	var carve_mesh := CSGMesh3D.new()
	carve_mesh.mesh = mi.mesh

	var pos_x = cav_pos.x
	var pos_y = cav_pos.y
	carve_mesh.position = Vector3(pos_x, pos_y, 0.0)
	carve_mesh.scale = Vector3(cav_scale, cav_scale, RH.CSG_THICKNESS)

	carve_mesh.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(carve_mesh)

	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_x_with_label(Vector3(pos_x, pos_y, 0.0), cav_name, Color.WHITE)
