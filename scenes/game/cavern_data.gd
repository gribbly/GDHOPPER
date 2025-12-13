class_name CavernData
extends RefCounted

var index: int
var size: Vector3
var pos: Vector3

func _init(p_index: int, p_size: Vector3, p_pos: Vector3) -> void:
	index = p_index
	size = p_size
	pos = p_pos
