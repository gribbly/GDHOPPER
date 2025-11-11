extends MeshInstance3D

# Requirements:
#	MeshInstance3D has an ImmediateMesh	
# 	ImmediateMesh has a StandardMaterial with Vertex Color > Use as Albedo = true

func _ready() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | ready()", 1)

	# test
	# for i in 64:
	#	var x := i * 2.0
	#	line(Vector3(0.0, 0.0, 30.0), Vector3(x, -100.0, 30.0))

func line(start: Vector3, end: Vector3, col: Color = Color.YELLOW) -> void:
	RH.print("🔺 debug_immediate_mesh.gd | rh_debug_line()", 5)
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(col)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()

func clear() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | clear()", 5)
	mesh.clear_surfaces()
