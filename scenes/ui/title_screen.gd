extends Control

@onready var start_btn: Button = %StartButton
func _ready() -> void:
	start_btn.pressed.connect(_on_start)

func _on_start() -> void:
	App.start_game()
