class_name LevelHelper
extends RefCounted

# Tuneables
const MARGIN_X := 16.0
const MARGIN_Y := 16.0

# Internals
var half_width: float
var third_width: float
var two_thirds_width: float
var half_height: float
var x_min: float
var x_max: float
var y_min: float
var y_max: float

# get_point types
enum XType { left, right, center }
enum YType { surface, shallow, deep }

# get_relative_point types
enum PlacementType { surface, below }
enum NoiseType { strict, strictish, fuzzed }

func init() -> void:
	half_width = RH.level_dimensions.x / 2.0
	third_width = RH.level_dimensions.x / 3.0
	two_thirds_width = third_width * 2.0
	half_height = RH.level_dimensions.y / 2.0
	x_min = MARGIN_X
	x_max = RH.level_dimensions.x - MARGIN_X
	y_min = MARGIN_Y
	y_max = RH.level_dimensions.y - MARGIN_Y

func get_point(x_type: XType, y_type: YType) -> Vector3:
	var x := 0.0
	var y := 0.0
   
	match x_type:
		XType.left:
			x = RH.get_random_float(x_min, third_width)
		XType.right:
			x = RH.get_random_float(two_thirds_width, x_max)
		XType.center:
			x = RH.get_random_float(third_width + MARGIN_X, two_thirds_width - MARGIN_X)
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled XType", 2)
			x = RH.get_random_float(0.0 + MARGIN_X, RH.level_dimensions.x - MARGIN_X)
	
	match y_type:
		YType.surface:
			y = RH.level_dimensions.y
		YType.shallow:
			y = RH.get_random_float(half_height + MARGIN_Y, y_max)
		YType.deep:
			y = RH.get_random_float(y_min, half_height - MARGIN_Y)
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled YType", 2)
			y = RH.get_random_float(0.0 + MARGIN_Y, RH.level_dimensions.y - MARGIN_Y)

	RH.print("🔪 level_helper.gd | get_point returning %v" % Vector3(x, y, 0.0), 3)
	return Vector3(x, y, 0.0)

func get_relative_point(source: Vector3, placement_type: PlacementType, noise_type: NoiseType) -> Vector3:
	var x := source.x
	var y := source.y

	match placement_type:
		PlacementType.surface:
			y = RH.level_dimensions.y
		PlacementType.below:
			y = source.y / 2.0
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled PlacementType", 2)
			y = 0.0
	
	match noise_type:
		NoiseType.strict:
			x = source.x
		NoiseType.strictish:
			x += (RH.get_random_float(-MARGIN_X, MARGIN_X)) * 0.3
		NoiseType.fuzzed:
			x += (RH.get_random_float(-MARGIN_X, MARGIN_X)) * 0.8
		_:
			RH.print("🔪 level_helper.gd | ⚠️ WARNING - unhandled NoiseType", 2)
			x = 0.0

	RH.print("🔪 level_helper.gd | get_relative_point returning %v" % Vector3(x, y, 0.0), 3)
	return Vector3(x, y, 0.0)
