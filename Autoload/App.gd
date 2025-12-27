# /Autoload/App.gd
extends Node

# TUNEABLES
var debug_autostart := true
var force_debug_info_panel_on = true
var force_debug_visuals_on = true
const SLOW_MOTION_TIMESCALE = 0.25

enum MainState { TITLE, PLAYING }
var state: MainState = MainState.TITLE

@onready var main_layer: Node = get_tree().current_scene.get_node("MainLayer")
@onready var overlay_layer: CanvasLayer = get_tree().current_scene.get_node("OverlayLayer")

const TITLE_SCENE := preload("res://Scenes/UI/TitleScreen.tscn")
const LEVEL_SCENE := preload("res://Scenes/Level/Level.tscn")
const PAUSE_SCENE := preload("res://Scenes/UI/PauseOverlay.tscn")
const DEBUG_OVERLAY_SCENE := preload("res://Scenes/UI/DebugOverlay.tscn")
const DEBUG_INFO_PANEL_SCENE := preload("res://Scenes/UI/DebugInfoPanel.tscn")
const DEBUG_CAMERA_SCENE := preload("res://Scenes/Debug/DebugCamera.tscn")

# Internals
var _current_main: Node = null
var _pause_overlay: Control = null
var _debug_overlay: Control = null
var _debug_info_panel: Control = null
var _debug_camera: Camera3D = null
var _previous_camera: Camera3D = null
var _using_debug_camera: bool = false
var _slow_motion_activated: bool = false
var _level: Node = null

func _ready() -> void:
	print("🌏 App.gd | Hello worlds...")
	print("🌏 App.gd | Welcome to ROCKHOPPER")

	RH.set_overlay_layer(overlay_layer)

	if force_debug_info_panel_on:
		RH.print("🌏 App.gd | 🛠️ DEBUG - forcing debug info panel on...", 2)
		RH.show_debug_info_panel = true

	if force_debug_visuals_on:
		RH.print("🌏 App.gd | 🛠️ DEBUG - forcing debug visuals on...", 2)
		RH.show_debug_visuals = true

	if debug_autostart:
		RH.print("🌏 App.gd | 🛠️ DEBUG - autostarting game...", 2)
		start_game()
	else:
		show_title()

#func _process(_delta: float) -> void:
	# Debug - artificial slowdown
	#OS.delay_msec(100) # adds ~100ms => ~10 FPS if it hits every frame

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			App.pause_game()

	# Debug keys
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.physical_keycode:
			KEY_G:
				RH.print("🌏 App.gd | 🛠️ DEBUG - regen level...", 2)
				regenerate_level()
			KEY_F:
				_using_debug_camera = !_using_debug_camera
				RH.print("🌏 App.gd | 🛠️ DEBUG - toggle debug camera = %s" % _using_debug_camera, 2)
				switch_to_debug_camera(_using_debug_camera)
			KEY_T:
				_slow_motion_activated = !_slow_motion_activated
				RH.print("🌏 App.gd | 🛠️ DEBUG - toggle slow motion = %s" % _slow_motion_activated, 2)
				if _slow_motion_activated:
					Engine.time_scale = SLOW_MOTION_TIMESCALE
				else:
					Engine.time_scale = 1.0

func show_title() -> void:
	state = MainState.TITLE
	_swap_main(TITLE_SCENE.instantiate())
	_clear_overlays()
	get_tree().paused = false

func start_game() -> void:
	show_debug_info_panel(RH.show_debug_info_panel)
	state = MainState.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_load_fresh_level()

func regenerate_level() -> void:
	_load_fresh_level() # note: _swap_main will tear down and replace the existing level

func _load_fresh_level() -> void:
	var next := LEVEL_SCENE.instantiate()
	_swap_main(next)
	_level = next

func pause_game() -> void:
	RH.print("🌏 App.gd | PAUSE menu", 2)
	if state != MainState.PLAYING: return
	if _pause_overlay: return
	_clear_overlays()
	_pause_overlay = PAUSE_SCENE.instantiate()
	overlay_layer.add_child(_pause_overlay)
	get_tree().paused = true # freeze gameplay
	# Ensure overlay still processes while paused:
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func debug_pause_game() -> void:
	RH.print("🌏 App.gd | DEBUG menu", 2)
	if state != MainState.PLAYING: return
	if _debug_overlay: return
	_clear_overlays()
	_debug_overlay = DEBUG_OVERLAY_SCENE.instantiate()
	overlay_layer.add_child(_debug_overlay)
	get_tree().paused = true # freeze gameplay
	# Ensure overlay still processes while paused:
	_debug_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func resume_game() -> void:
	RH.print("🌏 App.gd | RESUME", 2)
	get_tree().paused = false
	_clear_overlays()

func show_debug_info_panel(show: bool) -> void:
	RH.print("🌏 App.gd | show_debug_info_panel() - %s" % show, 4)
	if show:
		if _debug_info_panel: return
		_debug_info_panel = DEBUG_INFO_PANEL_SCENE.instantiate()
		overlay_layer.add_child(_debug_info_panel)
	else:
		if _debug_info_panel:
			_debug_info_panel.queue_free()
			await _debug_info_panel.tree_exited
			_debug_info_panel = null

func switch_to_debug_camera(switch: bool) -> void:
	if switch:
		_previous_camera = get_viewport().get_camera_3d()
		_debug_camera = DEBUG_CAMERA_SCENE.instantiate()
		main_layer.add_child(_debug_camera)
		_debug_camera.global_transform = _previous_camera.global_transform
		_debug_camera.make_current()
		
	else:
		if _debug_camera:
			_debug_camera.queue_free()
			await _debug_camera.tree_exited
			_debug_camera = null
		
		if is_instance_valid(_previous_camera):
				_previous_camera.make_current()

func quit_to_title() -> void:
	RH.print("🌏 App.gd | QUIT", 2)
	show_debug_info_panel(false) # hide debug_info_panel in title screen, but don't touch global setting
	show_title()

func exit_game() -> void:
	RH.print("🌏 App.gd | exit_game()")
	get_tree().quit()

func _swap_main(new_root: Node) -> void:
	if _current_main:
		RH.print("🌏 App.gd | freeing _current_main", 4)
		_current_main.queue_free()
		await _current_main.tree_exited
	_current_main = new_root
	RH.print("🌏 App.gd | adding %s" % new_root)
	main_layer.add_child(new_root)

func _clear_overlays() -> void:
	RH.print("🌏 App.gd | _clear_overlays()", 4)
	var overlays := [
		_pause_overlay,
		_debug_overlay
	]

	for overlay in overlays:
		if overlay:
			RH.print("🌏 App.gd | freeing overlay %s" % overlay, 5)
			overlay.queue_free()
			await overlay.tree_exited
			overlay = null
