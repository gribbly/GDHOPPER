# /autoload/App.gd
extends Node

enum MainState { TITLE, PLAYING }
var state: MainState = MainState.TITLE

@onready var main_layer: Node = get_tree().current_scene.get_node("MainLayer")
@onready var overlay_layer: CanvasLayer = get_tree().current_scene.get_node("OverlayLayer")

const TITLE_SCN := preload("res://scenes/ui/TitleScreen.tscn")
const LEVEL_SCN := preload("res://scenes/game/Level.tscn")
const PAUSE_SCN := preload("res://scenes/ui/PauseOverlay.tscn")

var _current_main: Node = null
var _pause_overlay: Control = null
var _level: Node = null

func _ready() -> void:
	print("🌏 App.gd | Hello worlds...")
	print("🌏 App.gd | Welcome to ROCKHOPPER")
	show_title()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()	

func show_title() -> void:
	print("🌏 App.gd | show_title()")
	state = MainState.TITLE
	_swap_main(TITLE_SCN.instantiate())
	_clear_overlay()
	get_tree().paused = false

func start_game() -> void:
	print("🌏 App.gd | start_game()")
	state = MainState.PLAYING
	_load_fresh_level()

func regenerate_level() -> void:
	print("🌏 App.gd | regenerate_level()")
	_load_fresh_level() # note: _swap_main will tear down and replace the existing level

func _load_fresh_level() -> void:
	print("🌏 App.gd | _load_fresh_level()")
	var next := LEVEL_SCN.instantiate()
	_swap_main(next)
	_level = next

func pause_game() -> void:
	print("🌏 App.gd | pause_game()")
	if state != MainState.PLAYING: return
	if _pause_overlay: return
	_pause_overlay = PAUSE_SCN.instantiate()
	overlay_layer.add_child(_pause_overlay)
	get_tree().paused = true  # freeze gameplay
	# ensure overlay still processes while paused:
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS 

func resume_game() -> void:
	print("🌏 App.gd | resume_game()")
	get_tree().paused = false
	_clear_overlay()

func quit_to_title() -> void:
	print("🌏 App.gd | quit_to_title()")
	show_title()

func _swap_main(new_root: Node) -> void:
	if _current_main:
		print("🌏 App.gd | freeing _current_main")
		_current_main.queue_free()
		await _current_main.tree_exited
	_current_main = new_root
	print("🌏 App.gd | adding new_root")
	main_layer.add_child(new_root)

func _clear_overlay() -> void:
	if _pause_overlay:
		_pause_overlay.queue_free()
		await _pause_overlay.tree_exited
		_pause_overlay = null
