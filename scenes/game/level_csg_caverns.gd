extends RefCounted

# Implements "cavern functions" for level_csg.gd

var caverns: Dictionary[String, CavernData] = {} # Dictionary of caverns by name

# Tuneables
const CAVERN_SIZE_SMALL := 8.0
const CAVERN_SIZE_MEDIUM := 16.0
const CAVERN_SIZE_LARGE := 24.0

# Internals
var level_csg_combiner: Node3D = null
var level_dimensions: Vector3
var _index := 0

func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

func set_level_dimensions(dimensions: Vector3) -> void:
	level_dimensions = dimensions

# 'cav_size_class' is an int. 1 = small, 2 = medium, 3 = large
func create_cavern(cav_name: String, cav_size_class: int, cav_pos: Vector3) -> void:
	RH.print("🔪 level_csg_caverns.gd | create_cavern()")

	if cav_name == "": cav_name = "cavern" # Default name if none supplied
	var cav_size = Vector3.ZERO

	match cav_size_class:
		1:
			cav_size = Vector3(CAVERN_SIZE_SMALL, CAVERN_SIZE_SMALL, RH.CSG_THICKNESS)
		2:
			cav_size = Vector3(CAVERN_SIZE_MEDIUM, CAVERN_SIZE_MEDIUM, RH.CSG_THICKNESS)
		3:
			cav_size = Vector3(CAVERN_SIZE_LARGE, CAVERN_SIZE_LARGE, RH.CSG_THICKNESS)

	caverns[cav_name] = CavernData.new(_index, cav_size, cav_pos)
	_index += 1

	_carve_cavern(cav_name, cav_size, cav_pos)

func _carve_cavern(cav_name: String, cav_size: Vector3, cav_pos: Vector3) -> void:
	RH.print("🔪 level_csg_caverns.gd | creating a cavern...")
	var cavern := CSGBox3D.new()
	var pos_x = cav_pos.x
	var pos_y = cav_pos.y
	cavern.position = Vector3(pos_x, pos_y, 0.0)

	var size_x = cav_size.x
	var size_y = cav_size.y
	cavern.size = Vector3(size_x, size_y, RH.CSG_THICKNESS)

	cavern.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(cavern)

	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_x_with_label(Vector3(pos_x, pos_y, 0.0), cav_name, Color.WHITE)

