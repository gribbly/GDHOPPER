extends Node3D

# Tuneables
const DEFAULT_COLOR := Color.YELLOW
const DEBUG_CROSS_SIZE := 4
const STANDARD_Z_DEPTH := 48.0
const LABEL_Y_SPACING_MULTIPLIER := 3.0

@onready var debug_immediate_mesh : MeshInstance3D = %DebugImmediateMesh

func _ready() -> void:
	RH.print("📐 debug_visuals.gd | ready()", 1)

	if debug_immediate_mesh:
		RH.print("📐 debug_visuals.gd | found %DebugImmediateMesh", 3)
		debug_immediate_mesh.clear() # ensure there are no residual vertices from previous activity (e.g., we're restarting a level)
		#_test_line_drawing()
	else:
		RH.print("📐 debug_visuals.gd | ⚠️ WARNING - didn't fimd %DebugImmediateMesh", 1)

func _test_line_drawing() -> void:
	for i in 64:
		var x := i * 2.0
		debug_immediate_mesh.line(Vector3(0.0, 0.0, 30.0), Vector3(x, -100.0, 30.0))

func rh_debug_line(start: Vector3, end: Vector3, col: Color = DEFAULT_COLOR):
	RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
	debug_immediate_mesh.line(start, end, col)

# Draw a debug "X" (cross shape) to mark a point in space
# Note: discards passed in z and forces a z-depth that is visible over "the rock"
func rh_debug_x(pos: Vector3, col: Color = DEFAULT_COLOR):
	RH.print("📐 debug_visuals.gd | rh_debug_x", 5)
	var top_left = Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, STANDARD_Z_DEPTH)
	var bottom_right = Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, STANDARD_Z_DEPTH)
	var bottom_left = Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, STANDARD_Z_DEPTH)
	var top_right = Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, STANDARD_Z_DEPTH)
	rh_debug_line(top_left, bottom_right, col)
	rh_debug_line(bottom_left, top_right, col)

# Draw a debug "X" (cross shape) to mark a point in space
# With a label above it!
# Note: discards passed in z and forces a z-depth that is visible over "the rock"
func rh_debug_x_with_label(pos: Vector3, msg: String = "rh_debug", col: Color = DEFAULT_COLOR):
	RH.print("📐 debug_visuals.gd | rh_debug_x_with_label", 5)
	rh_debug_x(pos, col)
	var label_pos := Vector3(pos.x, pos.y + (DEBUG_CROSS_SIZE * LABEL_Y_SPACING_MULTIPLIER), STANDARD_Z_DEPTH)
	debug_immediate_mesh.label(label_pos, msg, col)

func clear():
	RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
	debug_immediate_mesh.clear()
