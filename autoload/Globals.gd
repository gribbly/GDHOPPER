extends Node

# TUNEABLES
var print_min_priority: int = 3

# Internal
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func get_random_float(low: float, high: float) -> float:
	return rng.randf_range(low, high)

func set_rhprint_priority(p: int) -> void:
	print_min_priority = p

func print(msg: String, pri: int = 3) -> void:
	if pri <= print_min_priority:
		print(msg)