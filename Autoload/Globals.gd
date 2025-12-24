extends Node

# Globals
const CSG_THICKNESS := 16.0
const RHPRINT_VERBOSITY := 1 #lower verbosity level means you'll see less output. "1" is really clean. "3" is "typical development"
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

func get_random_int(low_inclusive: int, high_inclusive: int) -> int:
	return _rng.randi_range(low_inclusive, high_inclusive)

func get_random_bool(probability: float) -> bool:
	return _rng.randf() < clampf(probability, 0.0, 1.0)

func get_random_index(size: int) -> int:
	if size <= 0:
		return 0
	return _rng.randi_range(0, size - 1)

func print(msg: String, pri: int = 3) -> void:
	if pri <= RHPRINT_VERBOSITY:
		print(msg)
