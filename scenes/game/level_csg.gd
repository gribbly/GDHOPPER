extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Helpers
const LevelCSGCaverns := preload("res://scenes/game/level_csg_caverns.gd")
var csg_caverns = LevelCSGCaverns.new()
const LevelCSGTunnels := preload("res://scenes/game/level_csg_tunnels.gd")
var csg_tunnels = LevelCSGTunnels.new()

# Internal
var level_csg_combiner: Node3D = null;
var level_dimensions: Vector3
var level_helper: LevelHelper = null

func _ready() -> void:
	RH.print("🔪 level_csg.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_generate"))
	level_csg_combiner = %LevelCsgCombiner
	csg_caverns.set_combiner(level_csg_combiner)
	csg_tunnels.set_combiner(level_csg_combiner)

	level_helper = LevelHelper.new()

func _exit_tree() -> void:
	RH.print("🔪 level_csg.gd | _exit_tree()")
	SignalBus.disconnect("level_setup_complete", Callable(self, "_generate"))
	
func _generate(level_dims: Vector3) -> void:
	RH.print("🔪 level_csg.gd | _generate()", 1)
	level_dimensions = level_dims
	RH.print("🔪 level_csg.gd | level_dimensions = %s" % level_dimensions, 3)
	level_helper.set_level_dimensions(level_dimensions)
	csg_caverns.set_level_dimensions(level_dimensions)

	# Add first "rock" CSG... we'll carve everything else out of this
	RH.print("🔪 level_csg.gd | adding \"the rock\"...")
	var the_rock := CSGBox3D.new()
	var rock_position = Vector3.ZERO
	rock_position.x += level_dimensions.x / 2.0
	rock_position.y += level_dimensions.y / 2.0
	the_rock.position = rock_position
	#RH.debug_visuals.rh_debug_x_with_label(the_rock.position, "the_rock", Color.LIGHT_GRAY)

	the_rock.size = Vector3(level_dimensions.x, level_dimensions.y, RH.CSG_THICKNESS)
	level_csg_combiner.add_child(the_rock)

	# Caverns and tunnels
	## Create a large cavern top left
	var spawn_point = level_helper.get_point("left", "shallow")
	csg_caverns.create_cavern("welcome", 3, spawn_point)

	## Create a tunnel to the surface
	var start_pos = csg_caverns.caverns["welcome"].pos
	var end_pos = level_helper.get_relative_point(start_pos, "surface", "fuzzed")
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Create a medium cavern to the right of "welcome"
	spawn_point = level_helper.get_point("right", "shallow")
	csg_caverns.create_cavern("c2", 2, spawn_point)

	## Connect those two caverns with a tunnel
	start_pos = csg_caverns.caverns["welcome"].pos
	end_pos = csg_caverns.caverns["c2"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Create a small cavern below c2
	spawn_point = level_helper.get_relative_point(end_pos, "below", "strictish")
	csg_caverns.create_cavern("c3", 1, spawn_point)

	## Create a narrow tunnel connecting c2 and c3
	start_pos = csg_caverns.caverns["c2"].pos
	end_pos = csg_caverns.caverns["c3"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos, 5.5)

	## Create a medium deep cavern kinda in the middle
	spawn_point = level_helper.get_point("center", "deep")
	csg_caverns.create_cavern("c4", 2, spawn_point)

	## Create a tunnel connecting c3 and c4
	start_pos = csg_caverns.caverns["c3"].pos
	end_pos = csg_caverns.caverns["c4"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)