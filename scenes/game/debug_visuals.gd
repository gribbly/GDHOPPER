extends Node3D

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

func rh_debug_line(start: Vector3, end: Vector3, col: Color = Color.YELLOW):
	RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
	debug_immediate_mesh.line(start, end, col)

func clear():
	RH.print("📐 debug_visuals.gd | rh_debug_line", 5)
	debug_immediate_mesh.clear()
