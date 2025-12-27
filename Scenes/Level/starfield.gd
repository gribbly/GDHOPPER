extends Node3D
class_name StarfieldParallax3D

@export var parallax_axes := Vector2i(1, 0) # (X, Y) as 0/1 toggles

# Each layer config: which node, its tile size (the single-quad size), and its parallax factor.
# Tile size MUST match the QuadMesh size you used when building the 2x2 grid.
#
# If your layer root is offset in the scene, that's fine; the script preserves that via _base_layer_pos.
@export_group("Layer: stars_near")
@export var stars_near_path: NodePath
@export var stars_near_tile_size := Vector2(400.0, 200.0)
@export var stars_near_factor := 0.6

@export_group("Layer: stars_mid")
@export var stars_mid_path: NodePath
@export var stars_mid_tile_size := Vector2(500.0, 250.0)
@export var stars_mid_factor := 0.3

@export_group("Layer: stars_far")
@export var stars_far_path: NodePath
@export var stars_far_tile_size := Vector2(600.0, 300.0)
@export var stars_far_factor := 0.12

@export_group("Layer: nebular_far")
@export var nebular_far_path: NodePath
@export var nebular_far_tile_size := Vector2(800.0, 400.0)
@export var nebular_far_factor := 0.06

# ---- Internal state ----
var _cam: Node3D = null
var _base_cam_pos := Vector3.ZERO

const _TILE_SIZE_EPSILON := 0.01
const _SWAP_HYSTERESIS_TILES := 0.02

# We store each layer and its "base" position (where it was placed in the editor),
# so we can add parallax on top without destroying your authored offsets (like Z depth).
class LayerState:
	var node: Node3D
	var base_pos: Vector3
	var offset_xy: Vector2
	var wrap_x: int
	var wrap_y: int
	var tile_size: Vector2
	var factor: float

var _layers: Array[LayerState] = []

func _ready() -> void:
	# We depend on reading the camera's position each frame. Ensure we run AFTER the camera node
	# so we don't get a 1-frame lag at tile-swap boundaries.
	process_priority = 10

	# Collect/validate layers
	_layers.clear()
	_add_layer("stars_near", stars_near_path, stars_near_tile_size, stars_near_factor)
	_add_layer("stars_mid", stars_mid_path, stars_mid_tile_size, stars_mid_factor)
	_add_layer("stars_far", stars_far_path, stars_far_tile_size, stars_far_factor)
	_add_layer("nebular_far", nebular_far_path, nebular_far_tile_size, nebular_far_factor)

	# Optional sanity warnings
	for ls in _layers:
		if ls.tile_size.x <= 0.0 or ls.tile_size.y <= 0.0:
			push_warning("%s: tile_size should match your QuadMesh size and must be > 0." % ls.node.name)
			continue

		var quad_size := _find_first_quad_mesh_size(ls.node)
		if quad_size.x <= 0.0 or quad_size.y <= 0.0:
			push_warning("%s: couldn't find a QuadMesh under this layer; tile_size validation skipped." % ls.node.name)
		elif abs(quad_size.x - ls.tile_size.x) > _TILE_SIZE_EPSILON or abs(quad_size.y - ls.tile_size.y) > _TILE_SIZE_EPSILON:
			push_warning(
				"%s: tile_size %s doesn't match QuadMesh size %s; page swapping will pop/tear if these differ."
				% [ls.node.name, str(ls.tile_size), str(quad_size)]
			)

	# If the camera was already assigned (common when this scene is instantiated from code),
	# compute per-layer offsets now.
	if _cam != null:
		recenter_to_camera()

	RH.print("✨ starfield.gd | _ready()", 2)

func _process(_dt: float) -> void:
	if _cam == null:
		return

	var cam_pos := _cam.global_position

	for ls in _layers:
		var out_x := ls.base_pos.x
		var out_y := ls.base_pos.y

		if parallax_axes.x == 1:
			var desired_x := (cam_pos.x * ls.factor) + ls.offset_xy.x
			out_x = _wrap_axis(desired_x, cam_pos.x, ls.tile_size.x, true, ls)

		if parallax_axes.y == 1:
			var desired_y := (cam_pos.y * ls.factor) + ls.offset_xy.y
			out_y = _wrap_axis(desired_y, cam_pos.y, ls.tile_size.y, false, ls)

		# Apply to the layer root, preserving your authored Z depth and any base offsets.
		ls.node.global_position = Vector3(
			out_x,
			out_y,
			ls.base_pos.z
		)

func _add_layer(debug_name: String, path: NodePath, tile_size: Vector2, factor: float) -> void:
	if path.is_empty():
		push_warning("StarfieldParallax3D: %s_path is empty; that layer will be ignored." % debug_name)
		return

	var n := get_node_or_null(path)
	if n == null or not (n is Node3D):
		push_error("StarfieldParallax3D: %s_path is invalid or not a Node3D: %s" % [debug_name, String(path)])
		return

	var ls := LayerState.new()
	ls.node = n as Node3D
	ls.base_pos = ls.node.global_position
	ls.offset_xy = Vector2(ls.base_pos.x, ls.base_pos.y)
	ls.wrap_x = 0
	ls.wrap_y = 0
	ls.tile_size = tile_size
	ls.factor = factor
	_layers.append(ls)

func _wrap_axis(desired: float, camera: float, tile: float, is_x: bool, ls: LayerState) -> float:
	# Wrap/snap `desired` by integer tile steps so the result stays close to `camera`.
	# This keeps the 2x2 tiled quad grid centered near the camera, while still having the
	# parallax pattern move at `factor` speed.
	if tile == 0.0:
		return desired

	# diff_tiles tells us "how many tiles away" the desired point is from the camera.
	var diff_tiles := (camera - desired) / tile

	if is_x:
		ls.wrap_x = _update_wrap_step(diff_tiles, ls.wrap_x)
		return desired + float(ls.wrap_x) * tile

	ls.wrap_y = _update_wrap_step(diff_tiles, ls.wrap_y)
	return desired + float(ls.wrap_y) * tile

func _update_wrap_step(diff_tiles: float, current_step: int) -> int:
	# Hysteresis prevents one-frame ping-pong when diff_tiles hovers around +/-0.5.
	var delta := diff_tiles - float(current_step)

	# Handle teleports/large jumps in one go.
	if abs(delta) > 1.5:
		return int(round(diff_tiles))

	if delta > 0.5 + _SWAP_HYSTERESIS_TILES:
		return current_step + 1
	if delta < -0.5 - _SWAP_HYSTERESIS_TILES:
		return current_step - 1
	return current_step

func _find_first_quad_mesh_size(root: Node) -> Vector2:
	for child in root.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.mesh is QuadMesh:
				return (mi.mesh as QuadMesh).size
		var size := _find_first_quad_mesh_size(child)
		if size.x > 0.0 and size.y > 0.0:
			return size
	return Vector2(-1.0, -1.0)

func set_camera(cam: Node3D):
	RH.print("✨ starfield.gd | set_camera()", 4)
	_cam = cam

	# If the camera node has a custom priority, make sure we stay after it.
	process_priority = max(process_priority, _cam.process_priority + 1)

	recenter_to_camera()

func recenter_to_camera() -> void:
	# Recompute the "anchor" camera position and per-layer offsets.
	# This is useful if the camera is teleported (e.g. you move it to the ship spawn)
	# and you want the background to stay centered without a visible pop.
	if _cam == null:
		return
	_base_cam_pos = _cam.global_position
	var base_cam_xy := Vector2(_base_cam_pos.x, _base_cam_pos.y)
	for ls in _layers:
		# Solve: layer_pos = cam_pos * factor + offset  (before wrapping).
		# At the anchor moment, we want cam_pos=_base_cam_pos to produce the authored base_pos.
		ls.offset_xy = Vector2(ls.base_pos.x, ls.base_pos.y) - (base_cam_xy * ls.factor)

		# Pick initial wrap steps so the layer's 2x2 tile grid is centered near the camera immediately.
		if ls.tile_size.x != 0.0:
			ls.wrap_x = int(round((_base_cam_pos.x - ls.base_pos.x) / ls.tile_size.x))
		else:
			ls.wrap_x = 0
		if ls.tile_size.y != 0.0:
			ls.wrap_y = int(round((_base_cam_pos.y - ls.base_pos.y) / ls.tile_size.y))
		else:
			ls.wrap_y = 0

		# Apply immediately so a camera teleport doesn't show a 1-frame incorrect placement.
		var out_x := ls.base_pos.x
		var out_y := ls.base_pos.y
		if parallax_axes.x == 1 and ls.tile_size.x != 0.0:
			var desired_x := (_base_cam_pos.x * ls.factor) + ls.offset_xy.x
			out_x = desired_x + float(ls.wrap_x) * ls.tile_size.x
		if parallax_axes.y == 1 and ls.tile_size.y != 0.0:
			var desired_y := (_base_cam_pos.y * ls.factor) + ls.offset_xy.y
			out_y = desired_y + float(ls.wrap_y) * ls.tile_size.y
		ls.node.global_position = Vector3(out_x, out_y, ls.base_pos.z)
