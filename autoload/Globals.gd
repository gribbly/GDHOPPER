extends Node

var print_min_priority: int = 3

func set_rhprint_priority(p: int) -> void:
	print_min_priority = p

func print(msg: String, pri: int = 3) -> void:
	if pri <= print_min_priority:
		print(msg)