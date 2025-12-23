extends Node3D

@export var level_dimensions: Vector3 #meters
@export var debug_visuals: PackedScene
@export var level_light: PackedScene
@export var level_camera: PackedScene
@export var level_csg: PackedScene
@export var test_ship: PackedScene

var level_csg_instance: Node3D
var level_camera_instance: Node3D
var level_light_instance: Node3D
var test_ship_instance: Node3D
var level_grid: LevelGrid

func _ready() -> void:
	RH.print("🪨 level.gd | _ready()", 1)

	SignalBus.connect("ship_spawn_point", Callable(self, "_spawn_ship"))

	RH.print("🪨 level.gd | 🌐 setting level_dimensions in globals.gd")
	RH.level_dimensions = level_dimensions

	RH.print("🪨 level.gd | 📐 debug_visuals.instantiate")
	add_child(debug_visuals.instantiate())

	RH.print("🪨 level.gd | ☀️ level_light.instantiate")
	level_light_instance = level_light.instantiate()
	add_child(level_light_instance)

	RH.print("🪨 level.gd | 📸  level_camera.instantiate")
	level_camera_instance = level_camera.instantiate()
	add_child(level_camera_instance)

	if RH.show_debug_visuals == true:
		RH.print("🪨 level.gd | marking level origin")
		RH.debug_visuals.rh_debug_x_with_label(position, "origin", Color.WHITE)

	# Create the 2D "level grid" (we'll use this as the master template for caverns and tunnels)
	level_grid = LevelGrid.new(8, 16, Vector2(32,32))

	# Debug draw the level grid
	if RH.show_debug_visuals == true:
		level_grid.for_each_cell(func(r: int, c: int, _v):
			var p2 := level_grid.cell_center(r, c)
			var p3 := Vector3(p2.x, p2.y, 0.0)
			var color := Color.WHITE
			if c == 0:
				if r == 0:
					color = Color.GREEN # Mark first cell in green
				else:
					color = Color.BLUE
			RH.debug_visuals.rh_debug_x(p3, color)
		)

	# create and carve "the rock"
	RH.print("🪨 level.gd | 🔪 level_csg.instantiate")
	level_csg_instance = level_csg.instantiate()
	add_child(level_csg_instance)

	# convert the carved rock to mesh (from CSG)
	#RH.print("🪨 level.gd | 🔪 converting CSG to mesh...")
	#level_csg_instance.convert_to_mesh()

	RH.print("🪨 level.gd | moving camera to level midpoint...")
	level_camera_instance.move_camera(level_dimensions.x / 2.0, level_dimensions.y / 2.0)

	SignalBus.emit_signal("level_setup_complete")

func _exit_tree() -> void:
	RH.print("🪨 level.gd | _exit_tree()")
	SignalBus.disconnect("ship_spawn_point", Callable(self, "_spawn_ship"))

func _spawn_ship(spawn_point: Vector3) -> void:
	RH.print("🪨 level.gd | spawning ship...")
	test_ship_instance = test_ship.instantiate()
	test_ship_instance.position = Vector3(spawn_point)
	if RH.show_debug_visuals == true:
		RH.print("🪨 level.gd | marking ship spawn")
		RH.debug_visuals.rh_debug_x_with_label(spawn_point, "ship", Color.GREEN)
	add_child(test_ship_instance)

	level_camera_instance.follow_target = test_ship_instance
