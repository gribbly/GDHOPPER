extends Node

const CSG_THICKNESS := 32.0

var rhprint_verbosity_level: int = 3 #lower verbosity level means you'll see less output. "1" is really clean. "3" is "typical development"
var rng := RandomNumberGenerator.new()
var debug_visuals: DebugVisuals = null
var show_debug_info_panel := false:
	get:
		return show_debug_info_panel
	set(value):
		show_debug_info_panel = value
var show_debug_visuals := false:
	get:
		return show_debug_visuals
	set(value):
		show_debug_visuals = value

func _ready() -> void:
	rng.randomize()

func register_debug_visuals(instance: DebugVisuals) -> void:
	RH.print("🌐 Globals.gd | register_debug_visuals", 5)
	if debug_visuals != null:
		RH.print("🌐 Globals.gd | ⚠️ WARNING - re-registering debug_visuals. This won't break but shouldn't happen!")
	debug_visuals = instance

func unregister_debug_visuals(instance: DebugVisuals) -> void:
	RH.print("🌐 Globals.gd | unregister_debug_visuals", 5)
	if debug_visuals == instance:
		debug_visuals = null

func get_random_float(low: float, high: float) -> float:
	return rng.randf_range(low, high)

func set_rhprint_verbosity_level(p: int) -> void:
	rhprint_verbosity_level = p

func print(msg: String, pri: int = 3) -> void:
	if pri <= rhprint_verbosity_level:
		print(msg)