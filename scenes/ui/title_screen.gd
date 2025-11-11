extends Control

@onready var start_btn: Button = %StartButton
@onready var exit_btn: Button = %ExitButton

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	exit_btn.pressed.connect(_on_exit)
	start_btn.grab_focus.call_deferred()

func _on_start() -> void:
	App.start_game()

func _on_exit() -> void:
	App.exit_game()
