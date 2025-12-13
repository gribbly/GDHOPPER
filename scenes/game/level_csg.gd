extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Helpers
const LevelCSGCaverns := preload("res://scenes/game/level_csg_caverns.gd")
var csg_caverns = LevelCSGCaverns.new()
const LevelCSGTunnels := preload("res://scenes/game/level_csg_tunnels.gd")
var csg_tunnels = LevelCSGTunnels.new()

# Tuneables
var csg_thickness := 32.0

# Internal
var level_csg_combiner: Node3D = null;
var level_dimensions: Vector2

func _ready() -> void:
	RH.print("🔪 level_csg.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_generate"))
	level_csg_combiner = %LevelCsgCombiner
	csg_caverns.set_combiner(level_csg_combiner)
	csg_tunnels.set_combiner(level_csg_combiner)

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
	RH.debug_visuals.rh_debug_x_with_label(the_rock.position, "the_rock", Color.LIGHT_GRAY)

	the_rock.size = Vector3(level_dimensions.x, level_dimensions.y, csg_thickness)
	level_csg_combiner.add_child(the_rock)

	#caverns
	csg_caverns.set_level_dimensions(level_dimensions)
	csg_caverns.create_caverns()

	#tunnels
	csg_tunnels.create_tunnel(the_rock.position, Vector3.ZERO)
