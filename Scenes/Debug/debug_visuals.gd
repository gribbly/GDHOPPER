class_name DebugVisuals
extends Node3D

# Tuneables
const DEFAULT_COLOR := Color.YELLOW
const DEBUG_CROSS_SIZE := 4
const LABEL_Y_SPACING_MULTIPLIER := 3.0

@onready var debug_immediate_mesh := %DebugImmediateMesh

var _static_cmds: Array[Dictionary] = []
var _dynamic_cmds: Array[Dictionary] = []
var _frame_cmds: Array[Dictionary] = []

var _static_cached_lines: Array[Dictionary] = []
var _static_cached_labels: Array[Dictionary] = []
var _static_dirty := true

var _next_handle := 1
var _needs_render := true

func _enter_tree() -> void:
	RH.register_debug_visuals(self)

func _exit_tree() -> void:
	RH.unregister_debug_visuals(self)

func _ready() -> void:
	RH.print("📐 debug_visuals.gd | ready()", 2)

	if debug_immediate_mesh:
		RH.print("📐 debug_visuals.gd | found %DebugImmediateMesh", 4)
		clear() # Ensure there are no residual vertices/commands from previous activity (e.g., we're restarting a level)
	else:
		push_warning("📐 debug_visuals.gd | ⚠️ WARNING - didn't find %DebugImmediateMesh")

func _process(_delta: float) -> void:
	if debug_immediate_mesh:
		debug_immediate_mesh.visible = RH.show_debug_visuals

	if RH.show_debug_visuals != true:
		return

	if not debug_immediate_mesh:
		return

	var should_render := _needs_render or _static_dirty or (not _frame_cmds.is_empty()) or (not _dynamic_cmds.is_empty())
	if not should_render:
		return

	if _static_dirty:
		_rebuild_static_cache()

	var lines: Array[Dictionary] = []
	var labels: Array[Dictionary] = []
	lines.append_array(_static_cached_lines)
	labels.append_array(_static_cached_labels)

	_expand_cmds(_frame_cmds, lines, labels)
	_expand_dynamic_cmds(lines, labels)

	debug_immediate_mesh.render(lines, labels)
	_frame_cmds.clear()
	_needs_render = false

func _alloc_handle() -> int:
	var handle := _next_handle
	_next_handle += 1
	return handle

func _rebuild_static_cache() -> void:
	_static_cached_lines.clear()
	_static_cached_labels.clear()
	_expand_cmds(_static_cmds, _static_cached_lines, _static_cached_labels)
	_static_dirty = false

func _append_x_lines(pos: Vector3, col: Color, lines_out: Array[Dictionary]) -> void:
	var top_left := Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, pos.z)
	var bottom_right := Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, pos.z)
	var bottom_left := Vector3(pos.x - DEBUG_CROSS_SIZE, pos.y - DEBUG_CROSS_SIZE, pos.z)
	var top_right := Vector3(pos.x + DEBUG_CROSS_SIZE, pos.y + DEBUG_CROSS_SIZE, pos.z)
	lines_out.append({ "start": top_left, "end": bottom_right, "col": col })
	lines_out.append({ "start": bottom_left, "end": top_right, "col": col })

func _expand_cmds(cmds: Array[Dictionary], lines_out: Array[Dictionary], labels_out: Array[Dictionary]) -> void:
	for cmd in cmds:
		var kind: String = cmd.get("kind", "")
		match kind:
			"line":
				lines_out.append({
					"start": cmd.get("start", Vector3.ZERO),
					"end": cmd.get("end", Vector3.ZERO),
					"col": cmd.get("col", DEFAULT_COLOR),
				})
			"x":
				_append_x_lines(cmd.get("pos", Vector3.ZERO), cmd.get("col", DEFAULT_COLOR), lines_out)
			"label":
				labels_out.append({
					"pos": cmd.get("pos", Vector3.ZERO),
					"msg": cmd.get("msg", ""),
					"col": cmd.get("col", DEFAULT_COLOR),
				})
			_:
				pass

func _expand_dynamic_cmds(lines_out: Array[Dictionary], labels_out: Array[Dictionary]) -> void:
	if _dynamic_cmds.is_empty():
		return

	var kept: Array[Dictionary] = []
	for cmd in _dynamic_cmds:
		var kind: String = cmd.get("kind", "")
		var target_ref = cmd.get("target_ref", null) as WeakRef
		var target: Node3D = null
		if target_ref:
			target = target_ref.get_ref() as Node3D
		if target == null:
			continue

		kept.append(cmd)

		var pos: Vector3 = target.global_position + cmd.get("offset", Vector3.ZERO)
		match kind:
			"x_follow":
				_append_x_lines(pos, cmd.get("col", DEFAULT_COLOR), lines_out)
			"label_follow":
				labels_out.append({ "pos": pos, "msg": cmd.get("msg", ""), "col": cmd.get("col", DEFAULT_COLOR) })
			"x_label_follow":
				_append_x_lines(pos, cmd.get("col", DEFAULT_COLOR), lines_out)
				var label_pos := Vector3(pos.x, pos.y + (DEBUG_CROSS_SIZE * LABEL_Y_SPACING_MULTIPLIER), pos.z)
				labels_out.append({ "pos": label_pos, "msg": cmd.get("msg", ""), "col": cmd.get("col", DEFAULT_COLOR) })
			_:
				pass

	_dynamic_cmds = kept

func rh_debug_line(start: Vector3, end: Vector3, col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_static_cmds.append({ "kind": "line", "start": start, "end": end, "col": col })
		_static_dirty = true
		_needs_render = true

# Draw a debug "X" (cross shape) to mark a point in space
func rh_debug_x(pos: Vector3, col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_static_cmds.append({ "kind": "x", "pos": pos, "col": col })
		_static_dirty = true
		_needs_render = true

# Draw a debug "X" (cross shape) to mark a point in space
# With a label above it!
func rh_debug_x_with_label(pos: Vector3, msg: String = "rh_debug", col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_static_cmds.append({ "kind": "x", "pos": pos, "col": col })
		var label_pos := Vector3(pos.x, pos.y + (DEBUG_CROSS_SIZE * LABEL_Y_SPACING_MULTIPLIER), pos.z)
		_static_cmds.append({ "kind": "label", "pos": label_pos, "msg": msg, "col": col })
		_static_dirty = true
		_needs_render = true

func rh_debug_line_frame(start: Vector3, end: Vector3, col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_frame_cmds.append({ "kind": "line", "start": start, "end": end, "col": col })
		_needs_render = true

func rh_debug_x_frame(pos: Vector3, col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_frame_cmds.append({ "kind": "x", "pos": pos, "col": col })
		_needs_render = true

func rh_debug_x_with_label_frame(pos: Vector3, msg: String = "rh_debug", col: Color = DEFAULT_COLOR) -> void:
	if RH.show_debug_visuals == true:
		_frame_cmds.append({ "kind": "x", "pos": pos, "col": col })
		var label_pos := Vector3(pos.x, pos.y + (DEBUG_CROSS_SIZE * LABEL_Y_SPACING_MULTIPLIER), pos.z)
		_frame_cmds.append({ "kind": "label", "pos": label_pos, "msg": msg, "col": col })
		_needs_render = true

func rh_debug_x_follow(target: Node3D, offset: Vector3 = Vector3.ZERO, col: Color = DEFAULT_COLOR) -> int:
	if RH.show_debug_visuals != true:
		return -1
	var handle := _alloc_handle()
	_dynamic_cmds.append({ "id": handle, "kind": "x_follow", "target_ref": weakref(target), "offset": offset, "col": col })
	_needs_render = true
	return handle

func rh_debug_label_follow(target: Node3D, msg: String = "rh_debug", offset: Vector3 = Vector3.ZERO, col: Color = DEFAULT_COLOR) -> int:
	if RH.show_debug_visuals != true:
		return -1
	var handle := _alloc_handle()
	_dynamic_cmds.append({ "id": handle, "kind": "label_follow", "target_ref": weakref(target), "offset": offset, "msg": msg, "col": col })
	_needs_render = true
	return handle

func rh_debug_x_with_label_follow(target: Node3D, msg: String = "rh_debug", offset: Vector3 = Vector3.ZERO, col: Color = DEFAULT_COLOR) -> int:
	if RH.show_debug_visuals != true:
		return -1
	var handle := _alloc_handle()
	_dynamic_cmds.append({ "id": handle, "kind": "x_label_follow", "target_ref": weakref(target), "offset": offset, "msg": msg, "col": col })
	_needs_render = true
	return handle

func rh_debug_remove(handle: int) -> void:
	if handle < 0:
		return
	for i in range(_dynamic_cmds.size() - 1, -1, -1):
		if _dynamic_cmds[i].get("id", -2) == handle:
			_dynamic_cmds.remove_at(i)
			_needs_render = true
			return

func clear():
	RH.print("📐 debug_visuals.gd | clear()", 5)
	_static_cmds.clear()
	_dynamic_cmds.clear()
	_frame_cmds.clear()
	_static_cached_lines.clear()
	_static_cached_labels.clear()
	_static_dirty = true
	_needs_render = true
	if debug_immediate_mesh:
		debug_immediate_mesh.clear()
