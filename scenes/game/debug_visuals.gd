extends Node3D
class_name DebugVisuals

# Tuneables
const DEFAULT_COLOR := Color.YELLOW
const DEBUG_CROSS_SIZE := 4
const LABEL_Y_SPACING_MULTIPLIER := 3.0

@onready var debug_immediate_mesh : MeshInstance3D = %DebugImmediateMesh

func _enter_tree() -> void:
	RH.register_debug_visuals(self)

func _exit_tree() -> void:
	RH.unregister_debug_visuals(self)

func _ready() -> void:
	RH.print("📐 debug_visuals.gd | ready()", 1)

	if debug_immediate_mesh:
		RH.print("📐 debug_visuals.gd | found %DebugImmediateMesh", 3)
		debug_immediate_mesh.clear() # Ensure there are no residual vertices from previous activity (e.g., we're restarting a level)
	else:
		RH.print("📐 debug_visuals.gd | ⚠️ WARNING - didn't fimd %DebugImmediateMesh", 1)

func rh_debug_line(start: Vector3, end: Vector3, col: Color = DEFAULT_COLOR):
	if RH.show_debug_visuals == true:
		RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
		debug_immediate_mesh.line(start, end, col)

# Draw a debug "X" (cross shape) to mark a point in space
func rh_debug_x(pos: Vector3, col: Color = DEFAULT_COLOR):
	if RH.show_debug_visuals == true:
		RH.print("📐 debug_visuals.gd | rh_debug_x", 5)
		var top_left = Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, pos.z)
		var bottom_right = Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, pos.z)
		var bottom_left = Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, pos.z)
		var top_right = Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, pos.z)
		rh_debug_line(top_left, bottom_right, col)
		rh_debug_line(bottom_left, top_right, col)

# Draw a debug "X" (cross shape) to mark a point in space
# With a label above it!
func rh_debug_x_with_label(pos: Vector3, msg: String = "rh_debug", col: Color = DEFAULT_COLOR):
	if RH.show_debug_visuals == true:
		RH.print("📐 debug_visuals.gd | rh_debug_x_with_label", 5)
		rh_debug_x(pos, col)
		var label_pos := Vector3(pos.x, pos.y + (DEBUG_CROSS_SIZE * LABEL_Y_SPACING_MULTIPLIER), pos.z)
		debug_immediate_mesh.label(label_pos, msg, col)

func clear():
	RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
	debug_immediate_mesh.clear()
