extends Control

@onready var debug_info_toggle: Button = %DebugInfoToggle
@onready var back_btn: Button = %Back

func _ready() -> void:
	RH.print("👾 debug_overlay.gd | _ready()", 1)
	debug_info_toggle.button_pressed = RH.show_debug_info_panel # make button state match global state

	# Button signals
	debug_info_toggle.toggled.connect(_on_debug_info_toggle_toggled)
	back_btn.pressed.connect(func(): 
		App.pause_game()
	)

	back_btn.grab_focus.call_deferred()

func _on_debug_info_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		RH.show_debug_info_panel = true
	else:
		RH.show_debug_info_panel = false
	App.show_debug_info_panel(RH.show_debug_info_panel)
