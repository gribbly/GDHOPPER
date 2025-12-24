## Procgen data types shared between steps.
## - `LevelGenCavern` is the output of `LevelGenCaverns` and the input to graph/path steps.
## - Keep these as small data containers so the procgen steps stay decoupled.
class_name LevelGenCavern
extends RefCounted

enum SizeClass { LARGE, MEDIUM, SMALL }

var id: int
var size_class: SizeClass
var scale_xy: float
var center_cell: Vector2i
var center_2d: Vector2
var center_3d: Vector3

func _init(p_id: int, p_size_class: SizeClass, p_scale_xy: float, p_center_cell: Vector2i, p_center_2d: Vector2) -> void:
	id = p_id
	size_class = p_size_class
	scale_xy = p_scale_xy
	center_cell = p_center_cell
	center_2d = p_center_2d
	center_3d = Vector3(center_2d.x, center_2d.y, 0.0)
