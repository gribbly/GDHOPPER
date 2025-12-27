extends Node

# Globals
const CSG_THICKNESS := 16.0
const RHPRINT_VERBOSITY := 3 #lower verbosity level means you'll see less output. "1" is really clean. "3" is "typical development"
var level_dimensions := Vector3.ZERO

# Debug globals
var debug_visuals: DebugVisuals = null
var show_debug_info_panel := false
var show_debug_visuals := false

# Internals
var _rng := RandomNumberGenerator.new()
var _level_node: Node3D


func _ready() -> void:
	RH.print("🌐 Globals.gd | ready()", 2)
	_rng.randomize()


# level.gd will set level node at the start of level gen
# level node is freed and recreated every time level gen runs
func set_level_node(node: Node3D):
	_level_node = node


func get_level_node():
	if _level_node == null:
		push_warning("🌐 Globals.gd | ⚠️ WARNING - attempt to get _level_node while it's null")
	else:
		return _level_node


# Global print - access using 'RH.print'
# Optionall pass a priority as an int. Default = 3. This interacts with RHPRINT_VERBOSITY
# RH.print("Hello, worlds!", 3)
func print(msg: String, pri: int = 3) -> void:
	if pri <= RHPRINT_VERBOSITY:
		print(msg)



# debug_visuals.gd will register itself on ready
# Then anything that wants to draw debug visuals can do so via 'RH.debug_visuals'
func register_debug_visuals(instance: DebugVisuals) -> void:
	RH.print("🌐 Globals.gd | register_debug_visuals", 4)
	if debug_visuals != null:
		push_warning("🌐 Globals.gd | ⚠️ WARNING - re-registering debug_visuals. This won't break but shouldn't happen!")
	debug_visuals = instance


# debug_visuals.gd will register itself when it exits the tree
func unregister_debug_visuals(instance: DebugVisuals) -> void:
	RH.print("🌐 Globals.gd | unregister_debug_visuals", 4)
	if debug_visuals == instance:
		debug_visuals = null

# Random functions
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