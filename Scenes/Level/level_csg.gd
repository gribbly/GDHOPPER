extends Node3D

# Assumes that LevelCSG.tscn has %LevelCsgCombiner

# Helpers
const LevelCSGCaverns := preload("res://Scenes/Level/level_csg_caverns.gd")
var csg_caverns = LevelCSGCaverns.new()
const LevelCSGTunnels := preload("res://Scenes/Level/level_csg_tunnels.gd")
var csg_tunnels = LevelCSGTunnels.new()
const LevelCSGMesh := preload("res://Scenes/Level/level_csg_mesh.gd")
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
	SignalBus.emit_signal("ship_spawn_point", Vector3(60.0, 150.0, 0.0))

func convert_to_mesh() -> void:
	# CSG meshes are often not ready until the next frame.
	await get_tree().process_frame

	# Do the conversion
	csg_mesh.convert(csg)

	# remove CSG
	csg.queue_free()
