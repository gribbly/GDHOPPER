extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Internal
var level_dimensions: Vector2
var csg_thickness := 32.0

func _ready() -> void:
	RH.print("🔪 level_csg.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_generate"))
	
func _generate(level_dims: Vector2) -> void:
	RH.print("🔪 level_csg.gd | _generate()", 1)
	level_dimensions = level_dims
	RH.print("🔪 level_csg.gd | level_dimensions = %s" % level_dimensions, 3)

	# Add first "rock" CSG... we'll carve everything else out of this
	RH.print("🔪 level_csg.gd | adding \"the rock\"...", 3)
	var the_rock := CSGBox3D.new()
	the_rock.position = Vector3.ZERO
	the_rock.size = Vector3(level_dimensions.x, level_dimensions.y, csg_thickness)
	%LevelCsgCombiner.add_child(the_rock)

	# Carve a test cavern out of the_rock
	RH.print("🔪 level_csg.gd | carving test cavern...", 3)
	var test_cavern := CSGBox3D.new()
	var px = RH.get_random_float(-50.0, 50.0)
	var py = RH.get_random_float(-50.0, 50.0)
	test_cavern.position = Vector3(px, py, 0.0)
	var sx = RH.get_random_float(25.0, 75.0)
	var sy = RH.get_random_float(25.0, 75.0)
	test_cavern.size = Vector3(sx, sy, csg_thickness * 2)
	test_cavern.operation = CSGShape3D.OPERATION_SUBTRACTION
	%LevelCsgCombiner.add_child(test_cavern)
