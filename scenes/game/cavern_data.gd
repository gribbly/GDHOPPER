class_name CavernData
extends RefCounted

var index: int
var name: String
var pos: Vector2
var size: Vector2

func _init(p_index: int, p_pos: Vector2, p_name: String, p_size: Vector2) -> void:
	index = p_index
	pos = p_pos
	name = p_name
	size = p_size
