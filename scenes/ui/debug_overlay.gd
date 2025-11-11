extends Control

@onready var back_btn: Button = %Back

func _ready() -> void:
	RH.print("👾 debug_overlay.gd | _ready()", 1)
	back_btn.pressed.connect(func(): 
		App.pause_game()
	)
	back_btn.grab_focus.call_deferred()