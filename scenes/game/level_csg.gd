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

	# Carve som test caverns out of the_rock
	for i in 5:
		_test_cavern(64.0, 24.0) 

func _test_cavern(p : float = 32, s : float = 32.0) -> void:
	RH.print("🔪 level_csg.gd | carving test cavern...", 3)
	var test_cavern := CSGBox3D.new()
	var px = RH.get_random_float(-p, p)
	var py = RH.get_random_float(-p, p)
	test_cavern.position = Vector3(px, py, 0.0)
	var sx = RH.get_random_float(-s, s)
	var sy = RH.get_random_float(-s, s)
	test_cavern.size = Vector3(sx, sy, csg_thickness * 2)
	test_cavern.operation = CSGShape3D.OPERATION_SUBTRACTION
	%LevelCsgCombiner.add_child(test_cavern)
