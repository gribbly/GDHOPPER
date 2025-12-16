extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Helpers
const LevelCSGCaverns := preload("res://scenes/game/level_csg_caverns.gd")
var csg_caverns = LevelCSGCaverns.new()
const LevelCSGTunnels := preload("res://scenes/game/level_csg_tunnels.gd")
var csg_tunnels = LevelCSGTunnels.new()
const LevelCSGMesh := preload("res://scenes/game/level_csg_mesh.gd")
var csg_mesh = LevelCSGMesh.new()

# Internal
var csg: Node3D = null # This is the combiner for the procgen CSG shapes
var lh: LevelHelper = null

func _ready() -> void:
	RH.print("🔪 level_csg.gd | ready()", 1)
	SignalBus.connect("level_setup_complete", Callable(self, "_generate"))
	csg = %LevelCsgCombiner
	csg_caverns.set_combiner(csg)
	csg_tunnels.set_combiner(csg)
	lh = LevelHelper.new()
	lh.init()

func _exit_tree() -> void:
	RH.print("🔪 level_csg.gd | _exit_tree()")
	SignalBus.disconnect("level_setup_complete", Callable(self, "_generate"))
	
func _generate() -> void:
	RH.print("🔪 level_csg.gd | _generate()", 1)

	# Add first "rock" CSG... we'll carve everything else out of this
	RH.print("🔪 level_csg.gd | adding \"the rock\"...")
	var the_rock := CSGBox3D.new()
	var rock_position = Vector3.ZERO
	rock_position.x += RH.level_dimensions.x / 2.0
	rock_position.y += RH.level_dimensions.y / 2.0
	the_rock.position = rock_position
	#RH.debug_visuals.rh_debug_x_with_label(the_rock.position, "the_rock", Color.LIGHT_GRAY)

	the_rock.size = Vector3(RH.level_dimensions.x, RH.level_dimensions.y, RH.CSG_THICKNESS)
	csg.add_child(the_rock)

	# Caverns and tunnels
	## Create a large "welcome" cavern top left
	var spawn_point = lh.get_point(lh.XType.left, lh.YType.shallow)
	csg_caverns.create_cavern("welcome", 3, spawn_point)

	## This is the ship spawn point (for now)
	SignalBus.emit_signal("ship_spawn_point", spawn_point)

	## Create a tunnel to the surface
	var start_pos = csg_caverns.caverns["welcome"].pos
	var end_pos = lh.get_relative_point(start_pos, lh.PlacementType.surface, lh.NoiseType.fuzzed)
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Create a medium cavern to the right of "welcome"
	spawn_point = lh.get_point(lh.XType.center, lh.YType.shallow)
	csg_caverns.create_cavern("c2", 2, spawn_point)

	## Connect those two caverns with a tunnel
	start_pos = csg_caverns.caverns["welcome"].pos
	end_pos = csg_caverns.caverns["c2"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Create another large cavern to the right of "c2"
	spawn_point = lh.get_point(lh.XType.right, lh.YType.shallow)
	csg_caverns.create_cavern("c3", 3, spawn_point)	

	## Tunnel from c2 to c3
	start_pos = csg_caverns.caverns["c2"].pos
	end_pos = csg_caverns.caverns["c3"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Create a small cavern below c3
	spawn_point = lh.get_relative_point(csg_caverns.caverns["c3"].pos, lh.PlacementType.below, lh.NoiseType.strictish)
	csg_caverns.create_cavern("c4", 1, spawn_point)

	## Create a narrow tunnel connecting c3 and c4
	start_pos = csg_caverns.caverns["c3"].pos
	end_pos = csg_caverns.caverns["c4"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos, 0.64)

	## Create a medium deep cavern kinda in the middle
	spawn_point = lh.get_point(lh.XType.center, lh.YType.deep)
	csg_caverns.create_cavern("c5", 2, spawn_point)

	## Create a tunnel connecting c4 and c5
	start_pos = csg_caverns.caverns["c4"].pos
	end_pos = csg_caverns.caverns["c5"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)

	## Tunnel from c2 to c5
	start_pos = csg_caverns.caverns["c2"].pos
	end_pos = csg_caverns.caverns["c5"].pos
	csg_tunnels.create_tunnel(start_pos, end_pos)

func convert_to_mesh() -> void:
	# CSG meshes are often not ready until the next frame.
	await get_tree().process_frame

	# Do the conversion
	csg_mesh.convert(csg)

	# remove CSG
	csg.queue_free()
