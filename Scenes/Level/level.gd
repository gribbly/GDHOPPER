extends Node3D

@export var level_dimensions: Vector3 #meters
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene
@export var test_ship: PackedScene

# Tuneables
const GRID_ROWS := 8
const GRID_COLS := 16

@export var bake_csg_to_mesh := false

@export var debug_draw_grid := false
@export var debug_draw_connections := true
@export var debug_draw_tunnel_paths := false

@export var caverns_large_count := 2
@export var caverns_medium_count := 2
@export var caverns_small_count := 2
@export var cavern_medium_scale_xy := 0.7 # relative to large = 1.0
@export var cavern_small_scale_xy := 0.5 # relative to large = 1.0
@export var cavern_padding_cells := 1
@export var cavern_attempts_per_cavern := 40
@export var cavern_best_of_k := 8
@export var cavern_avoid_borders := true
@export var cavern_border_margin_cells := 1

@export var extra_connection_probability := 0.0

@export var tunnel_max_extra_bends := 2
@export var tunnel_carve_step_distance := 6.0
@export var tunnel_carve_scale_xy := 1.0
@export var tunnel_carve_size_variation := 0.0
@export var tunnel_cells_before_first_turn := 2

@export var entrance_tunnel_enabled := true
@export var entrance_tunnel_extra_height := 32.0 # extend above surface so the opening is carved

var level_csg_instance: LevelCSG
var level_camera_instance: LevelCamera
var level_light_instance: Node3D
var test_ship_instance: Node3D
var level_grid: LevelGrid

const LevelGenCavernsScript := preload("res://Scenes/Level/level_gen_caverns.gd")
const LevelGenGraphScript := preload("res://Scenes/Level/level_gen_graph.gd")
const LevelGenTunnelPathsScript := preload("res://Scenes/Level/level_gen_tunnel_paths.gd")


func _ready() -> void:
	RH.print("🪨 level.gd | _ready()", 1)

	SignalBus.connect("ship_spawn_point", Callable(self, "_spawn_ship"))

	RH.print("🪨 level.gd | 📐 debug_visuals.instantiate")
	add_child(debug_visuals.instantiate())

	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	level_light_instance = level_light.instantiate() as Node3D
	add_child(level_light_instance)

	RH.print("🪨 level.gd | 📸  level_camera.instantiate")
	level_camera_instance = level_camera.instantiate() as LevelCamera
	add_child(level_camera_instance)
	level_camera_instance.toggle_level_gen_mode() # DEBUG: immediately enter level gen mode for easy viewing of procgen. Press L to exit.

	if RH.show_debug_visuals == true:
		RH.print("🪨 level.gd | marking level origin")
		RH.debug_visuals.rh_debug_x_with_label(position, "origin", Color.WHITE)

	# create and carve "the rock"
	RH.print("🪨 level.gd | 🔪 level_csg.instantiate")
	level_csg_instance = level_csg.instantiate() as LevelCSG
	add_child(level_csg_instance)

	# Ensure LevelCSG has run _ready() and computed base rock bounds.
	await get_tree().process_frame
	var rock_size: Vector2 = level_csg_instance.get_base_rock_size()

	RH.print("🪨 level.gd | 🌐 setting level_dimensions in globals.gd")
	RH.level_dimensions = Vector3(rock_size.x, rock_size.y, level_dimensions.z)

	# Create the 2D "level grid" (we'll use this as the master template for caverns and tunnels)
	level_grid = LevelGrid.new(GRID_ROWS, GRID_COLS, _calculate_grid_cell_size(GRID_ROWS, GRID_COLS))

	# Debug draw the level grid
	if RH.show_debug_visuals == true and debug_draw_grid:
		level_grid.for_each_cell(func(r: int, c: int, _v):
			var p2 := level_grid.cell_center(r, c)
			var p3 := Vector3(p2.x, p2.y, 0.0)
			var color := Color.WHITE
			if c == 0 and r == 0:
				color = Color.GREEN # Mark first cell in green
			RH.debug_visuals.rh_debug_x(p3, color)
		)

	_run_procgen()

	if bake_csg_to_mesh:
		RH.print("🪨 level.gd | 🔪 converting CSG to mesh...")
		await level_csg_instance.convert_to_mesh()

	RH.print("🪨 level.gd | moving camera to level midpoint...")
	level_camera_instance.move_camera(rock_size.x / 2.0, rock_size.y / 2.0)

	var spawn_point := Vector3(rock_size.x / 2.0, rock_size.y + 16.0, 0.0)
	SignalBus.emit_signal("ship_spawn_point", spawn_point)


func _exit_tree() -> void:
	RH.print("🪨 level.gd | _exit_tree()")
	SignalBus.disconnect("ship_spawn_point", Callable(self, "_spawn_ship"))


func _spawn_ship(spawn_point: Vector3) -> void:
	RH.print("🪨 level.gd | spawning ship...")
	test_ship_instance = test_ship.instantiate() as Node3D
	test_ship_instance.position = Vector3(spawn_point)
	if RH.show_debug_visuals == true:
		RH.print("🪨 level.gd | marking ship spawn")
		RH.debug_visuals.rh_debug_x_with_label(spawn_point, "ship", Color.GREEN)
	add_child(test_ship_instance)

	level_camera_instance.follow_target = test_ship_instance

func _run_procgen() -> void:
	var gen_caverns := LevelGenCavernsScript.new()
	gen_caverns.init_grid_unblocked(level_grid)

	var cavern_template_half_size_xy: Vector2 = level_csg_instance.cavern_template_half_size_xy()
	if cavern_template_half_size_xy == Vector2.ZERO:
		RH.print("🪨 level.gd | ⚠️ cavern template size is zero; skipping procgen", 1)
		return

	var requests: Array[Dictionary] = [
		{"count": caverns_large_count, "scale_xy": 1.0, "size_class": LevelGenCavern.SizeClass.LARGE, "distance_weight": 1.0},
		{"count": caverns_medium_count, "scale_xy": cavern_medium_scale_xy, "size_class": LevelGenCavern.SizeClass.MEDIUM, "distance_weight": 0.5},
		{"count": caverns_small_count, "scale_xy": cavern_small_scale_xy, "size_class": LevelGenCavern.SizeClass.SMALL, "distance_weight": 0.2},
	]

	var caverns := gen_caverns.place_caverns(
		level_grid,
		cavern_template_half_size_xy,
		requests,
		cavern_avoid_borders,
		cavern_border_margin_cells,
		cavern_padding_cells,
		cavern_attempts_per_cavern,
		cavern_best_of_k
	)

	RH.print("🪨 level.gd | procgen: caverns=%s" % caverns.size(), 2)

	for cav in caverns:
		level_csg_instance.carve_cavern(cav.id, cav.center_3d, cav.scale_xy)

	var graph := LevelGenGraphScript.new()
	var edges := graph.build_mst_edges(caverns)
	edges = graph.add_extra_edges_nearest_nonconnected(caverns, edges, extra_connection_probability)

	RH.print("🪨 level.gd | procgen: connections=%s" % edges.size(), 2)

	if RH.show_debug_visuals == true:
		if debug_draw_connections:
			for e in edges:
				if e.x < 0 or e.x >= caverns.size() or e.y < 0 or e.y >= caverns.size():
					continue
				RH.debug_visuals.rh_debug_line(caverns[e.x].center_3d, caverns[e.y].center_3d, Color(0.7, 0.7, 0.7))

	var path_builder := LevelGenTunnelPathsScript.new()
	var min_turn_world_xy := level_grid.cell_size * float(tunnel_cells_before_first_turn)
	for e in edges:
		var a := caverns[e.x]
		var b := caverns[e.y]
		var a_clearance := Vector2(
			(cavern_template_half_size_xy.x * a.scale_xy) + min_turn_world_xy.x,
			(cavern_template_half_size_xy.y * a.scale_xy) + min_turn_world_xy.y
		)
		var b_clearance := Vector2(
			(cavern_template_half_size_xy.x * b.scale_xy) + min_turn_world_xy.x,
			(cavern_template_half_size_xy.y * b.scale_xy) + min_turn_world_xy.y
		)

		var points := path_builder.build_l_path_with_bends(
			a.center_3d,
			b.center_3d,
			tunnel_max_extra_bends,
			a_clearance,
			b_clearance
		)

		if RH.show_debug_visuals == true and debug_draw_tunnel_paths:
			for i in range(points.size() - 1):
				RH.debug_visuals.rh_debug_line(points[i], points[i + 1], Color(0.4, 0.9, 0.9))

		for i in range(points.size() - 1):
			level_csg_instance.carve_tunnel_segment(
				points[i],
				points[i + 1],
				tunnel_carve_step_distance,
				tunnel_carve_scale_xy,
				tunnel_carve_size_variation,
				TAU
			)

	_carve_entrance_tunnel(caverns)

# This function returns cell size by dividing the size of the rock by the number of requested rows/cols
func _calculate_grid_cell_size(rows: int, cols: int) -> Vector2:
	var rock_size: Vector2 = level_csg_instance.get_base_rock_size()
	var return_x = rock_size.x / cols
	var return_y = rock_size.y / rows
	return Vector2(return_x, return_y)

func _carve_entrance_tunnel(caverns: Array[LevelGenCavern]) -> void:
	if not entrance_tunnel_enabled:
		return
	if caverns.is_empty():
		return

	var topmost := caverns[0]
	for cav in caverns:
		if cav.center_3d.y > topmost.center_3d.y:
			topmost = cav

	var surface_y := level_csg_instance.get_base_rock_size().y
	var end := Vector3(topmost.center_3d.x, surface_y + entrance_tunnel_extra_height, 0.0)

	RH.print("🪨 level.gd | procgen: entrance tunnel from cav_%s to surface" % topmost.id, 2)
	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_line(topmost.center_3d, end, Color(0.9, 0.85, 0.2))

	level_csg_instance.carve_tunnel_segment(
		topmost.center_3d,
		end,
		tunnel_carve_step_distance,
		tunnel_carve_scale_xy,
		tunnel_carve_size_variation,
		TAU
	)
