extends Control

@onready var resume_btn: Button = %Resume
@onready var restart_btn: Button = %Restart
@onready var quit_btn: Button = %Quit

func _ready() -> void:
	resume_btn.pressed.connect(func(): App.resume_game())
	restart_btn.pressed.connect(func():
		App.resume_game()
		App.regenerate_level()
	)
	quit_btn.pressed.connect(func():
		App.resume_game()
		App.quit_to_title()
	)
