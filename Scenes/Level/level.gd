extends Node3D

# Exports 
# Scene connections
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene
@export var test_ship: PackedScene
@export var test_cargo: PackedScene
@export var test_launcher: PackedScene
@export_range(0.0, 1.0, 0.05) var test_launcher_probability := 0.5
@export_range(0.0, 8.0, 0.1) var test_launcher_extra_depth := 0.5

# Bake step toggle
@export var bake_csg_to_mesh := true

# Debug draw toggles
@export var debug_draw_grid := false
@export var debug_draw_connections := false
@export var debug_draw_tunnel_paths := false

# Debug step control
@export_range(1, 4, 1) var do_procgen_steps := 4

# Level gen tuning
# Cavern count a nd scale
@export var caverns_large_count := 3
@export var caverns_medium_count := 3
@export var caverns_small_count := 3
@export var cavern_medium_scale_xy := 0.75 # relative to large = 1.0
@export var cavern_small_scale_xy := 0.5 # relative to large = 1.0
@export var cavern_scale_variation := 0.10 # +/- percentage applied per cavern

# Cavern generation parameters
@export var cavern_padding_cells := 1
@export var cavern_attempts_per_cavern := 40
@export var cavern_best_of_k := 8
@export var cavern_avoid_borders := true
@export var cavern_border_margin_cells := 1
@export var extra_connection_probability := 0.0

# Tunnel generation parameters
@export var tunnel_max_extra_bends := 0
@export var tunnel_carve_step_distance := 6.0
@export var tunnel_carve_scale_xy := 1.0
@export var tunnel_carve_size_variation := 0.0
@export var tunnel_cells_before_first_turn := 2

# Tunnel to surface parameters
@export var entrance_tunnel_enabled := true
@export var entrance_tunnel_extra_height := 32.0 # extend above surface so the opening is carved

# Set grid size for procgen
const GRID_ROWS := 16
const GRID_COLS := 32

# Specific scripts for procgen steps
const LevelGenCavernsScript := preload("res://Scenes/Level/level_gen_caverns.gd")
const LevelGenGraphScript := preload("res://Scenes/Level/level_gen_graph.gd")
const LevelGenTunnelPathsScript := preload("res://Scenes/Level/level_gen_tunnel_paths.gd")
const LevelEnemyPlacerScript := preload("res://Scenes/Level/level_enemy_placer.gd")

# Internals
var level_csg_instance: LevelCSG
var level_camera_instance: LevelCamera
var level_light_instance: Node3D
var test_ship_instance: Node3D
var level_grid: LevelGrid
var _generated_caverns: Array[LevelGenCavern] = []
var _cavern_template_half_size_xy := Vector2.ZERO


func _ready() -> void:
	RH.print("🪨 level.gd | _ready()", 1)
	SignalBus.connect("ship_spawn_point", Callable(self, "_spawn_ship"))
	RH.set_level_node(self)

	# Start instantiating level components
	add_child(debug_visuals.instantiate())
	level_light_instance = level_light.instantiate() as Node3D
	add_child(level_light_instance)
	level_camera_instance = level_camera.instantiate() as LevelCamera
	add_child(level_camera_instance)
	level_camera_instance.toggle_level_gen_mode() # DEBUG: immediately enter level gen mode for easy viewing of procgen. Press L to exit.

	# Instantiate CSG scene, which sets us up for level gen, and set global level_dimensions
	level_csg_instance = level_csg.instantiate() as LevelCSG
	add_child(level_csg_instance)
	# Ensure LevelCSG has run _ready() and computed base rock bounds.
	await get_tree().process_frame
	var rock_size: Vector2 = level_csg_instance.get_base_rock_size()
	RH.level_dimensions = Vector3(rock_size.x, rock_size.y, RH.CSG_THICKNESS)

	# Kick off actual level gen
	_run_procgen()

	# If we rely on CSG collision (no baking), give the engine a frame to update.
	await get_tree().process_frame

	# Bake generated CSG to mesh
	if bake_csg_to_mesh:
		RH.print("🪨 level.gd | 🔪 converting CSG to mesh...")
		await level_csg_instance.convert_to_mesh()

	_place_test_launchers()

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
	add_child(test_ship_instance)
	level_camera_instance.follow_target = test_ship_instance


func _run_procgen() -> void:
	# STEP 1 - Create the initial 2D "level grid"
	# We'll use this as the master template for caverns and tunnels
	if do_procgen_steps < 1: return # DEBUG: Stop before grid

	level_grid = LevelGrid.new(GRID_ROWS, GRID_COLS, _calculate_grid_cell_size(GRID_ROWS, GRID_COLS))

	# Debug draw the level grid
	if RH.show_debug_visuals == true and debug_draw_grid:
		level_grid.for_each_cell(func(r: int, c: int, _v):
			var p2 := level_grid.cell_center(r, c)
			var p3 := Vector3(p2.x, p2.y, 0.0)
			var color := Color.BLACK
			if c == 0 and r == 0:
				color = Color.GREEN # Mark first cell in green
			RH.debug_visuals.rh_debug_x(p3, color)
		)
	
	# STEP 2 - place and carve caverns
	if do_procgen_steps < 2: return # DEBUG: Stop after grid generation/before caverns

	var gen_caverns := LevelGenCavernsScript.new()
	gen_caverns.init_grid_unblocked(level_grid)

	var cavern_template_half_size_xy: Vector2 = level_csg_instance.cavern_template_half_size_xy()
	_cavern_template_half_size_xy = cavern_template_half_size_xy

	# 'distance_weight' is a tuning knob passed into cavern placement scoring. It controls how strongly the placer prefers candidate cells that are farther from already-placed caverns.
	# There's no fixed range, but 0.0 means “don’t prefer far-from-others” (spacing comes only from the footprint blocking).
	# > 0.0 increasingly biases toward more separated caverns.
	# Negative values would do the opposite (prefer being near other caverns), but probably isn’t desirable.
	# 0.0 to 1.0 is a reasonable tuning range, but can go higher if desired.
	var requests: Array[Dictionary] = [
		{"count": caverns_large_count, "scale_xy": 1.0, "size_class": LevelGenCavern.SizeClass.LARGE, "distance_weight": 1.0},
		{"count": caverns_medium_count, "scale_xy": cavern_medium_scale_xy, "size_class": LevelGenCavern.SizeClass.MEDIUM, "distance_weight": 0.8},
		{"count": caverns_small_count, "scale_xy": cavern_small_scale_xy, "size_class": LevelGenCavern.SizeClass.SMALL, "distance_weight": 0.8},
	]

	var caverns := gen_caverns.place_caverns(
		level_grid,
		cavern_template_half_size_xy,
		requests,
		cavern_avoid_borders,
		cavern_border_margin_cells,
		cavern_scale_variation,
		cavern_padding_cells,
		cavern_attempts_per_cavern,
		cavern_best_of_k
	)

	RH.print("🪨 level.gd | procgen: caverns=%s" % caverns.size(), 2)
	_generated_caverns = caverns
	for cav in caverns:
		level_csg_instance.carve_cavern(cav.id, cav.center_3d, cav.scale_xy)

	# STEP 3 - connection graph
	if do_procgen_steps < 3: return # DEBUG: Stop after caverns/before connection graph

	var graph := LevelGenGraphScript.new()
	var edges := graph.build_mst_edges(caverns)
	edges = graph.add_extra_edges_nearest_nonconnected(caverns, edges, extra_connection_probability)

	RH.print("🪨 level.gd | procgen: connections=%s" % edges.size(), 2)

	if RH.show_debug_visuals == true:
		if debug_draw_connections:
			for e in edges:
				if e.x < 0 or e.x >= caverns.size() or e.y < 0 or e.y >= caverns.size():
					continue
				RH.debug_visuals.rh_debug_line(caverns[e.x].center_3d, caverns[e.y].center_3d, Color.NAVY_BLUE)

	# STEP 4 - carve tunnels
	if do_procgen_steps < 4: return # DEBUG: Stop after connection graph/before tunnels

	# Create the tunnel/path generator helper. This is purely "planning" (returns points); it doesn't modify the scene.
	var path_builder := LevelGenTunnelPathsScript.new()
	# Gameplay/design rule: tunnels may NOT enter/exit a cavern via its bottom edge.
	# Concretely: we only allow cavern connections via TOP/LEFT/RIGHT edges.
	path_builder.forbid_start_exit_bottom = true
	path_builder.forbid_end_entry_bottom = true

	# We want tunnels to go straight for at least N grid-cells before making the first turn.
	# Convert that "N cells" tuning knob into world-space distances (in X/Y).
	var min_turn_world_xy := level_grid.cell_size * float(tunnel_cells_before_first_turn)

	# Configure the path builder to snap waypoints to level-grid cell centers (origin at world (0,0)).
	path_builder.grid_cell_size = level_grid.cell_size

	# Each edge connects two caverns by index. For each connection, build an L-shaped path (with optional extra bends),
	# then carve the resulting tunnel segments into the CSG rock.
	for e in edges:
		# Resolve the endpoints of this connection from cavern indices -> actual cavern objects.
		var a := caverns[e.x]
		var b := caverns[e.y]

		# Clearance boxes around each cavern in world-space (X/Y).
		# This keeps the first tunnel turn far enough away from the cavern walls:
		# - start with the cavern template's half-size (world units)
		# - scale it by the cavern's per-instance scale
		# - add the "minimum straight distance before turning"
		var a_clearance := Vector2(
			(cavern_template_half_size_xy.x * a.scale_xy) + min_turn_world_xy.x,
			(cavern_template_half_size_xy.y * a.scale_xy) + min_turn_world_xy.y
		)
		var b_clearance := Vector2(
			(cavern_template_half_size_xy.x * b.scale_xy) + min_turn_world_xy.x,
			(cavern_template_half_size_xy.y * b.scale_xy) + min_turn_world_xy.y
		)

		# Ask the path builder for a polyline (array of 3D points) that connects cavern A to cavern B.
		# The builder uses the clearances to decide where bends are allowed so turns don't clip into caverns.
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
	_spawn_one_test_cargo_in_cavern(caverns, cavern_template_half_size_xy)


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


func _spawn_one_test_cargo_in_cavern(caverns: Array[LevelGenCavern], cavern_template_half_size_xy: Vector2) -> void:
	if test_cargo == null:
		return
	if caverns.is_empty():
		return
	if cavern_template_half_size_xy == Vector2.ZERO:
		return

	var cav := caverns[RH.get_random_index(caverns.size())]
	var half := cavern_template_half_size_xy * cav.scale_xy

	# Place somewhere safely inside the cavern bounds (and let physics drop it onto the floor).
	var offset := Vector3(
		RH.get_random_float(-half.x * 0.35, half.x * 0.35),
		RH.get_random_float(-half.y * 0.35, half.y * 0.35),
		0.0
	)
	var spawn_pos := cav.center_3d + offset

	var cargo_instance := test_cargo.instantiate() as Node3D
	if cargo_instance == null:
		RH.print("🪨 level.gd | ⚠️ test_cargo scene did not instantiate as Node3D", 1)
		return

	cargo_instance.position = spawn_pos
	add_child(cargo_instance)

	if RH.show_debug_visuals == true:
		RH.debug_visuals.rh_debug_x_with_label(spawn_pos, "cargo", Color(0.9, 0.6, 0.2))


func _place_test_launchers() -> void:
	if test_launcher == null:
		return
	if _generated_caverns.is_empty():
		return
	if _cavern_template_half_size_xy == Vector2.ZERO:
		return

	var placer_obj := LevelEnemyPlacerScript.new()
	var placer := placer_obj as LevelEnemyPlacer
	if placer == null:
		return

	var placed := placer.place_one_test_launcher_per_cavern(
		self,
		_generated_caverns,
		_cavern_template_half_size_xy,
		test_launcher,
		test_launcher_probability,
		test_launcher_extra_depth
	)
	RH.print("🪨 level.gd | procgen: launchers=%s" % placed, 2)
