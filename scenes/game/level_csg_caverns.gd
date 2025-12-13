extends RefCounted

# Implements "cavern functions" for level_csg.gd

# Tuneables
var csg_thickness := 32.0
var num_caverns = 5

# Internals
var level_csg_combiner: Node3D = null
var level_dimensions: Vector2
var caverns: Dictionary[int, CavernData] = {} # Dictionary of caverns by index
var cavern_x := 0.0
var cavern_y := 0.0

func set_combiner(combiner: Node3D) -> void:
	level_csg_combiner = combiner

func set_level_dimensions(dimensions: Vector2) -> void:
	level_dimensions = dimensions

func create_caverns() -> void:
	RH.print("🔪 level_csg_caverns.gd | create_caverns()")
	
	# Add caverns to the dictionary
	for i in range(num_caverns):
		cavern_x = RH.get_random_float(0.0, level_dimensions.x)
		cavern_y = RH.get_random_float(0.0, level_dimensions.y)
		var cavern_size_x = RH.get_random_float(8.0, 16.0)
		var cavern_size_y = RH.get_random_float(8.0, 16.0)
		caverns[i] = CavernData.new(i, Vector2(cavern_x, cavern_y), "cavern %d" % i, Vector2(cavern_size_x, cavern_size_y))

	# Create all the caverns in the dictionary
	for i in range(caverns.size()):
		_create_cavern(caverns[i].pos, caverns[i].size, caverns[i].name)

func _create_cavern(pos: Vector2, size: Vector2, cavern_name: String = "cavern") -> void:
	RH.print("🔪 level_csg_caverns.gd | creating a cavern...")
	var cavern := CSGBox3D.new()
	var pos_x = pos.x
	var pos_y = pos.y
	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_x_with_label(Vector3(pos_x, pos_y, 0.0), cavern_name, Color.WHITE)
	cavern.position = Vector3(pos_x, pos_y, 0.0)
	var size_x = size.x
	var size_y = size.y
	cavern.size = Vector3(size_x, size_y, csg_thickness)
	cavern.operation = CSGShape3D.OPERATION_SUBTRACTION
	level_csg_combiner.add_child(cavern)