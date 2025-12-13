extends Node

# Globals
const CSG_THICKNESS := 64.0
const RHPRINT_VERBOSITY := 5 #lower verbosity level means you'll see less output. "1" is really clean. "3" is "typical development"
var level_dimensions := Vector3.ZERO

# Debug
var debug_visuals: DebugVisuals = null
var show_debug_info_panel := false
var show_debug_visuals := false

# Internal
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

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
	return _rng.randf_range(low, high)

func print(msg: String, pri: int = 3) -> void:
	if pri <= RHPRINT_VERBOSITY:
		print(msg)