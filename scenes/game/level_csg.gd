extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

@export var show_debug_visuals: bool
@export var debug_visuals: PackedScene

# Tuneables
var csg_thickness := 32.0
var min_cavern_size := 16.0
var cavern_xmargin := 16.0
const CAVERN_POS_MULTIPLIER_MIN := 0.9
const CAVERN_POS_MULTIPLIER_MAX := 1.1
const CAVERN_SIZE_MULTIPLIER_MIN := 0.8
const CAVERN_SIZE_MULTIPLIER_MAX := 1.8

# Internal
var level_dimensions: Vector2
var shallow_y := 0.0
var deep_y := 0.0
var debug_visuals_instance: Node3D

func _ready() -> void:
	RH.print("🔪 level_csg.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_generate"))
	RH.print("🔪 level_csg.gd | 📐 debug_visuals.instantiate")
	debug_visuals_instance = debug_visuals.instantiate()
	add_child(debug_visuals_instance)

func _exit_tree() -> void:
	RH.print("🔪 level_csg.gd | _exit_tree()")
	SignalBus.disconnect("level_setup_complete", Callable(self, "_generate"))
	
func _generate(level_dims: Vector2) -> void:
	RH.print("🔪 level_csg.gd | _generate()", 1)
	level_dimensions = level_dims
	RH.print("🔪 level_csg.gd | level_dimensions = %s" % level_dimensions, 3)

	# Add first "rock" CSG... we'll carve everything else out of this
	RH.print("🔪 level_csg.gd | adding \"the rock\"...")
	var the_rock := CSGBox3D.new()
	var rock_position = Vector3.ZERO
	rock_position.x += level_dimensions.x / 2.0
	rock_position.y += level_dimensions.y / 2.0
	the_rock.position = rock_position

	the_rock.size = Vector3(level_dimensions.x, level_dimensions.y, csg_thickness)
	%LevelCsgCombiner.add_child(the_rock)

	#we're going to do two horizontal passes:
		#shallow - three caverns
		#deep - two caverns

	shallow_y = level_dimensions.y - (level_dimensions.y * 0.25)
	deep_y = level_dimensions.y - (level_dimensions.y * 0.75)

	#generate x positions for shallow caverns
	var shallow_xtick_1 = level_dimensions.x / 3.0
	var shallow_xtick_2 = level_dimensions.x / 2.0

	var shallow_xpos_1 = RH.get_random_float(0.0 + cavern_xmargin, shallow_xtick_1 - cavern_xmargin)
	RH.print("🔪 level_csg.gd | shallow_xpos_1 = %s" % shallow_xpos_1)
	var shallow_xpos_2 = RH.get_random_float(shallow_xtick_1+ cavern_xmargin, shallow_xtick_2 - cavern_xmargin)
	RH.print("🔪 level_csg.gd | shallow_xpos_2 = %s" % shallow_xpos_2)
	var shallow_xpos_3 = RH.get_random_float(shallow_xtick_2 + cavern_xmargin, level_dimensions.x) - cavern_xmargin
	RH.print("🔪 level_csg.gd | shallow_xpos_3 = %s" % shallow_xpos_3)

	#generate y positions for deep caverns
	var deep_xtick = level_dimensions.x / 2.0
	var deep_xpos_1 = RH.get_random_float(0.0 + cavern_xmargin, deep_xtick - cavern_xmargin)
	RH.print("🔪 level_csg.gd | deep_xpos_1 = %s" % deep_xpos_1)
	var deep_xpos_2 = RH.get_random_float(deep_xtick + cavern_xmargin, level_dimensions.x - cavern_xmargin)
	RH.print("🔪 level_csg.gd | deep_xpos_2 = %s" % deep_xpos_2)

	#carve the caverns
	var cavern_size:=Vector2(16.0, 16.0)
	var cavern_pos:=Vector2(shallow_xpos_1, shallow_y)
	_create_cavern(cavern_pos, cavern_size, "cavern 1")
	cavern_pos.x = shallow_xpos_2
	_create_cavern(cavern_pos, cavern_size, "cavern 2")
	cavern_pos.x = shallow_xpos_3
	_create_cavern(cavern_pos, cavern_size, "cavern 3")
	cavern_pos.x = deep_xpos_1
	cavern_pos.y = deep_y
	_create_cavern(cavern_pos, cavern_size, "cavern 4")
	cavern_pos.x = deep_xpos_2
	_create_cavern(cavern_pos, cavern_size, "cavern 5")

func _create_cavern(pos: Vector2, size: Vector2, cavern_name: String = "cavern") -> void:
	RH.print("🔪 level_csg.gd | creating a cavern...")
	var cavern := CSGBox3D.new()
	var pos_x = pos.x
	var pos_y = pos.y * RH.get_random_float(CAVERN_POS_MULTIPLIER_MIN, CAVERN_POS_MULTIPLIER_MAX)
	if show_debug_visuals == true:
		debug_visuals_instance.rh_debug_x_with_label(Vector3(pos_x, pos_y, 0.0), cavern_name, Color.WHITE)
	cavern.position = Vector3(pos_x, pos_y, 0.0)
	var size_x = size.x * RH.get_random_float(CAVERN_SIZE_MULTIPLIER_MIN, CAVERN_SIZE_MULTIPLIER_MAX)
	var size_y = size.y * RH.get_random_float(CAVERN_SIZE_MULTIPLIER_MIN, CAVERN_SIZE_MULTIPLIER_MAX)
	cavern.size = Vector3(size_x, size_y, csg_thickness)
	cavern.operation = CSGShape3D.OPERATION_SUBTRACTION
	%LevelCsgCombiner.add_child(cavern)