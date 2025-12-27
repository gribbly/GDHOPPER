extends MeshInstance3D

# Requirements:
#	MeshInstance3D has an ImmediateMesh	
# 	ImmediateMesh has a StandardMaterial with Vertex Color > Use as Albedo = true

var _label_pool: Array[Label3D] = []
var _active_label_count := 0
var _debug_material: StandardMaterial3D
var _legacy_lines: Array[Dictionary] = []
var _legacy_labels: Array[Dictionary] = []

const DEBUG_RENDER_PRIORITY := 127

func _ready() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | ready()", 2)
	_configure_render_on_top()

func _configure_render_on_top() -> void:
	_debug_material = StandardMaterial3D.new()
	_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_material.vertex_color_use_as_albedo = true
	_debug_material.no_depth_test = true
	_debug_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_debug_material.render_priority = DEBUG_RENDER_PRIORITY
	material_override = _debug_material

func _ensure_immediate_mesh() -> void:
	if mesh == null or not (mesh is ImmediateMesh):
		mesh = ImmediateMesh.new()

func _acquire_label() -> Label3D:
	if _active_label_count < _label_pool.size():
		return _label_pool[_active_label_count]

	var new_label := Label3D.new()
	new_label.font_size = 64
	new_label.pixel_size = 0.1
	new_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	new_label.set(&"render_priority", DEBUG_RENDER_PRIORITY)
	new_label.set(&"no_depth_test", true)
	add_child(new_label)
	_label_pool.append(new_label)
	return new_label

# Render the provided debug primitives into a single ImmediateMesh surface.
# `lines` items: { "start": Vector3, "end": Vector3, "col": Color }
# `labels` items: { "pos": Vector3, "msg": String, "col": Color }
func render(lines: Array[Dictionary], labels: Array[Dictionary]) -> void:
	_ensure_immediate_mesh()
	mesh.clear_surfaces()

	if not lines.is_empty():
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, _debug_material)
		for cmd in lines:
			var col: Color = cmd.get("col", Color.YELLOW)
			mesh.surface_set_color(col)
			mesh.surface_add_vertex(cmd.get("start", Vector3.ZERO))
			mesh.surface_add_vertex(cmd.get("end", Vector3.ZERO))
		mesh.surface_end()

	_active_label_count = 0
	for cmd in labels:
		var label_node := _acquire_label()
		label_node.visible = true
		label_node.text = cmd.get("msg", "")
		label_node.modulate = cmd.get("col", Color.YELLOW)
		label_node.position = cmd.get("pos", Vector3.ZERO)
		_active_label_count += 1

	for i in range(_active_label_count, _label_pool.size()):
		_label_pool[i].visible = false


# Legacy convenience API (kept for compatibility). These rebuild the mesh each call.
func line(start: Vector3, end: Vector3, col: Color = Color.YELLOW) -> void:
	_legacy_lines.append({ "start": start, "end": end, "col": col })
	render(_legacy_lines, _legacy_labels)

func label(pos: Vector3, msg: String, col: Color = Color.YELLOW) -> void:
	_legacy_labels.append({ "pos": pos, "msg": msg, "col": col })
	render(_legacy_lines, _legacy_labels)

func _has_property(obj: Object, property_name: StringName) -> bool:
	for property_dict in obj.get_property_list():
		if property_dict.get("name") == property_name:
			return true
	return false

func clear() -> void:
	RH.print("🔺 debug_immediate_mesh.gd | clear()", 5)
	_ensure_immediate_mesh()
	mesh.clear_surfaces()
	_legacy_lines.clear()
	_legacy_labels.clear()
	for label_node in _label_pool:
		if is_instance_valid(label_node):
			label_node.queue_free()
	_label_pool.clear()
	_active_label_count = 0
