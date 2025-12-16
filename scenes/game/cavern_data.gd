class_name CavernData
extends RefCounted

var index: int
var scale: float
var pos: Vector3

func _init(p_index: int, p_size: float, p_pos: Vector3) -> void:
	index = p_index
	scale = p_size
	pos = p_pos
