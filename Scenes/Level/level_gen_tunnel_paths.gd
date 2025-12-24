## Procgen step: produce a "mostly L-shaped" polyline path between two points (pure logic).
## - Generates 0..N extra bend waypoints, then finishes with an L-shaped approach.
## - Output is a list of `Vector3` points suitable for carving with repeated tunnel shapes.
class_name LevelGenTunnelPaths
extends RefCounted

func build_l_path_with_bends(start: Vector3, end: Vector3, max_extra_bends: int) -> Array[Vector3]:
	var points: Array[Vector3] = [start]

	var current: Vector3 = start
	var bends: int = 0
	if max_extra_bends > 0:
		bends = RH.get_random_int(0, max_extra_bends)

	var horizontal_first: bool = RH.get_random_bool(0.5)
	var axis_is_x: bool = horizontal_first

	for _i in range(bends):
		if axis_is_x:
			var next_x := _rand_between_towards(current.x, end.x)
			if absf(next_x - current.x) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(next_x, current.y, 0.0)
			points.append(current)
		else:
			var next_y := _rand_between_towards(current.y, end.y)
			if absf(next_y - current.y) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(current.x, next_y, 0.0)
			points.append(current)

		axis_is_x = !axis_is_x

	if horizontal_first:
		if absf(end.x - current.x) > 0.01:
			current = Vector3(end.x, current.y, 0.0)
			points.append(current)
		if absf(end.y - current.y) > 0.01:
			current = Vector3(end.x, end.y, 0.0)
			points.append(current)
	else:
		if absf(end.y - current.y) > 0.01:
			current = Vector3(current.x, end.y, 0.0)
			points.append(current)
		if absf(end.x - current.x) > 0.01:
			current = Vector3(end.x, end.y, 0.0)
			points.append(current)

	if points.back() != end:
		points[points.size() - 1] = end

	return _dedupe_consecutive(points)

func _rand_between_towards(current: float, target: float) -> float:
	var lo := minf(current, target)
	var hi := maxf(current, target)
	if hi - lo < 0.01:
		return target
	var v := RH.get_random_float(lo, hi)
	if target >= current:
		return clampf(v, current, target)
	return clampf(v, target, current)

func _dedupe_consecutive(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() <= 1:
		return points
	var out: Array[Vector3] = [points[0]]
	for i in range(1, points.size()):
		if points[i].distance_to(out.back()) > 0.001:
			out.append(points[i])
	return out
