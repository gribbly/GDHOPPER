extends Node

# TUNEABLES
var rhprint_verbosity_level: int = 3 #lower verbosity level means you'll see less output. "1" is really clean. "3" is "typical development"

# Internal
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func get_random_float(low: float, high: float) -> float:
	return rng.randf_range(low, high)

func set_rhprint_verbosity_level(p: int) -> void:
	rhprint_verbosity_level = p

func print(msg: String, pri: int = 3) -> void:
	if pri <= rhprint_verbosity_level:
		print(msg)