class_name LevelHelper
extends RefCounted

# Tuneables
const MARGIN_X := 16.0
const MARGIN_Y := 24.0

# Internals
var _level_dimensions: Vector3

func set_level_dimensions(dimensions: Vector3) -> void:
	_level_dimensions = dimensions

func get_point(x_type: String, y_type: String) -> Vector3:
	var x := 0.0
	var y := 0.0
   
	match x_type:
		"left":
			x = RH.get_random_float(0.0 + MARGIN_X, _level_dimensions.x / 2.0)
		"right":
			x = RH.get_random_float(_level_dimensions.x / 2.0, _level_dimensions.x - MARGIN_X)
		"center":
			x = (_level_dimensions.x / 2.0) * RH.get_random_float(0.6, 1.3)
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled x_type", 2)
			x = RH.get_random_float(0.0 + MARGIN_X, _level_dimensions.x - MARGIN_X)
	
	match y_type:
		"surface":
			y = _level_dimensions.y
		"shallow":
			y = RH.get_random_float(_level_dimensions.y / 2.0, _level_dimensions.y - MARGIN_Y)
		"deep":
			y = RH.get_random_float(0.0 + MARGIN_Y, _level_dimensions.y / 2.0)
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled y_type", 2)
			y = RH.get_random_float(0.0 + MARGIN_Y, _level_dimensions.y - MARGIN_Y)

	return Vector3(x, y, 0.0)

func get_relative_point(source: Vector3, placement_type: String, noise_type: String) -> Vector3:
	var x := source.x
	var y := source.y

	match placement_type:
		"surface":
			y = _level_dimensions.y
		"below":
			y = source.y / 2.0
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled placement_type", 2)
			y = 0.0
	
	match noise_type:
		"strict":
			x = source.x
		"strictish":
			x += (RH.get_random_float(-MARGIN_X, MARGIN_X)) * 0.3
		"fuzzed":
			x += (RH.get_random_float(-MARGIN_X, MARGIN_X)) * 0.8
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled placement_type", 2)
			x = 0.0

	return Vector3(x, y, 0.0)
