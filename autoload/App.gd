# /autoload/App.gd
extends Node

# TUNEABLES
var debug_autostart := true
var rh_print_verbosity_level = 3 # only RH.prints below this level will be output. Set this to 1 for minimal chatter.

enum MainState { TITLE, PLAYING }
var state: MainState = MainState.TITLE

@onready var main_layer: Node = get_tree().current_scene.get_node("MainLayer")
@onready var overlay_layer: CanvasLayer = get_tree().current_scene.get_node("OverlayLayer")

const TITLE_SCN := preload("res://scenes/ui/TitleScreen.tscn")
const LEVEL_SCN := preload("res://scenes/game/Level.tscn")
const PAUSE_SCN := preload("res://scenes/ui/PauseOverlay.tscn")
const DEBUG_SCN := preload("res://scenes/ui/DebugOverlay.tscn")

var _current_main: Node = null
var _pause_overlay: Control = null
var _debug_overlay: Control = null
var _level: Node = null

func _ready() -> void:
	print("🌏 App.gd | Hello worlds...")
	print("🌏 App.gd | Welcome to ROCKHOPPER")

	RH.set_rhprint_verbosity_level(rh_print_verbosity_level) # RH is an alias for Globals.gd, which is set up as an autoload in Project Settings
	
	if debug_autostart:
		RH.print("🌏 App.gd | 🛠️ DEBUG - autostarting game...")
		start_game()
	else:
		show_title()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			App.pause_game()

func show_title() -> void:
	RH.print("🌏 App.gd | show_title()")
	state = MainState.TITLE
	_swap_main(TITLE_SCN.instantiate())
	_clear_overlays()
	get_tree().paused = false

func start_game() -> void:
	RH.print("🌏 App.gd | start_game()")
	state = MainState.PLAYING
	_load_fresh_level()

func regenerate_level() -> void:
	RH.print("🌏 App.gd | regenerate_level()")
	_load_fresh_level() # note: _swap_main will tear down and replace the existing level

func _load_fresh_level() -> void:
	RH.print("🌏 App.gd | _load_fresh_level()")
	var next := LEVEL_SCN.instantiate()
	_swap_main(next)
	_level = next

func pause_game() -> void:
	RH.print("🌏 App.gd | pause_game()", 1)
	if state != MainState.PLAYING: return
	if _pause_overlay: return
	_clear_overlays()
	_pause_overlay = PAUSE_SCN.instantiate()
	overlay_layer.add_child(_pause_overlay)
	get_tree().paused = true # freeze gameplay
	# Ensure overlay still processes while paused:
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func debug_pause_game() -> void:
	RH.print("🌏 App.gd | debug_pause_game()", 1)
	if state != MainState.PLAYING: return
	if _debug_overlay: return
	_clear_overlays()
	_debug_overlay = DEBUG_SCN.instantiate()
	overlay_layer.add_child(_debug_overlay)
	get_tree().paused = true # freeze gameplay
	# Ensure overlay still processes while paused:
	_debug_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func resume_game() -> void:
	RH.print("🌏 App.gd | resume_game()", 1)
	get_tree().paused = false
	_clear_overlays()

func quit_to_title() -> void:
	RH.print("🌏 App.gd | quit_to_title()")
	show_title()

func exit_game() -> void:
	RH.print("🌏 App.gd | exit_game()")
	get_tree().quit()

func _swap_main(new_root: Node) -> void:
	if _current_main:
		RH.print("🌏 App.gd | freeing _current_main")
		_current_main.queue_free()
		await _current_main.tree_exited
	_current_main = new_root
	RH.print("🌏 App.gd | adding new_root")
	main_layer.add_child(new_root)

func _clear_overlays() -> void:
	RH.print("🌏 App.gd | _clear_overlays()", 3)
	var overlays := [
		_pause_overlay,
		_debug_overlay
	]

	for overlay in overlays:
		if overlay:
			RH.print("🌏 App.gd | freeing overlay %s" % overlay, 3)
			overlay.queue_free()
			await overlay.tree_exited
			overlay = null

	# if _pause_overlay:
	# 	_pause_overlay.queue_free()
	# 	await _pause_overlay.tree_exited
	# 	_pause_overlay = null
