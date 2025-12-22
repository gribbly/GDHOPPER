extends MeshInstance3D

# Requirements:
#	MeshInstance3D has an ImmediateMesh	
# 	ImmediateMesh has a StandardMaterial with Vertex Color > Use as Albedo = true

var _labels: Array[Label3D] = []
var _debug_material: StandardMaterial3D

const DEBUG_RENDER_PRIORITY := 127

func _ready() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | ready()", 1)
	_configure_render_on_top()

func _configure_render_on_top() -> void:
	_debug_material = StandardMaterial3D.new()
	_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_material.vertex_color_use_as_albedo = true
	_debug_material.no_depth_test = true
	_debug_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_debug_material.render_priority = DEBUG_RENDER_PRIORITY
	material_override = _debug_material

func line(start: Vector3, end: Vector3, col: Color = Color.YELLOW) -> void:
	RH.print("🔺 debug_immediate_mesh.gd | line()", 5)
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_set_color(col)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(end)
	mesh.surface_end()

# Draw a 3D label in world space at `pos`.
# Uses billboarding so text faces the camera.
func label(pos: Vector3, msg: String, col: Color = Color.YELLOW) -> void:
	RH.print("🔺 debug_immediate_mesh.gd | label()", 5)
	var the_label := Label3D.new()
	the_label.text = msg
	the_label.font_size = 64
	the_label.pixel_size = 0.1
	the_label.modulate = col
	the_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	the_label.set(&"render_priority", DEBUG_RENDER_PRIORITY)
	the_label.set(&"no_depth_test", true)
	the_label.position = pos
	add_child(the_label)
	_labels.append(the_label)

func _has_property(obj: Object, property_name: StringName) -> bool:
	for property_dict in obj.get_property_list():
		if property_dict.get("name") == property_name:
			return true
	return false

func clear() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | clear()", 5)
	mesh.clear_surfaces()
	for label_node in _labels:
		if is_instance_valid(label_node):
			label_node.queue_free()
	_labels.clear()
