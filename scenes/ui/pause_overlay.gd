extends Control

@onready var resume_btn: Button = %Resume
@onready var restart_btn: Button = %Restart
@onready var debug_btn: Button = %Debug
@onready var abandon_btn: Button = %Abandon

func _ready() -> void:
	RH.print("📺 pause_overlay.gd | _ready()", 1)

	# Button signals:
	resume_btn.pressed.connect(func(): 
		App.resume_game()
	)
	restart_btn.pressed.connect(func():
		App.resume_game()
		App.regenerate_level()
	)
	debug_btn.pressed.connect(func(): 
		App.debug_pause_game()
	)
	abandon_btn.pressed.connect(func():
		App.resume_game()
		App.quit_to_title()
	)

	resume_btn.grab_focus.call_deferred()
