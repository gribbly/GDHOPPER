## Procgen step: produce a "mostly L-shaped" polyline path between two points (pure logic).
## - Generates 0..N extra bend waypoints, then finishes with an L-shaped approach.
## - Output is a list of `Vector3` points suitable for carving with repeated tunnel shapes.
class_name LevelGenTunnelPaths
extends RefCounted

func build_l_path_with_bends(
	start: Vector3,
	end: Vector3,
	max_extra_bends: int,
	start_clearance_xy: Vector2 = Vector2.ZERO,
	end_clearance_xy: Vector2 = Vector2.ZERO
) -> Array[Vector3]:
	var points: Array[Vector3] = [start]

	var current: Vector3 = start
	var bends: int = 0
	if max_extra_bends > 0:
		bends = RH.get_random_int(0, max_extra_bends)

	var horizontal_first: bool = RH.get_random_bool(0.5)
	var axis_is_x: bool = horizontal_first

	var routing_start: Vector3 = start
	var routing_end: Vector3 = end

	# Try to avoid "instant turns" right after leaving a cavern by inserting a straight "stub"
	# from the start cavern, and by keeping the final turn away from the end cavern.
	#
	# `*_clearance_xy` is a world-space distance measured from cavern center:
	#   (cavern half-extent along axis) + (min straight distance after the edge).
	if start_clearance_xy != Vector2.ZERO or end_clearance_xy != Vector2.ZERO:
		var dx := end.x - start.x
		var dy := end.y - start.y

		var horiz_feasible: bool = absf(dx) >= start_clearance_xy.x and absf(dy) >= end_clearance_xy.y
		var vert_feasible: bool = absf(dy) >= start_clearance_xy.y and absf(dx) >= end_clearance_xy.x

		if horizontal_first and not horiz_feasible and vert_feasible:
			horizontal_first = false
			axis_is_x = false
		elif (not horizontal_first) and not vert_feasible and horiz_feasible:
			horizontal_first = true
			axis_is_x = true

		if horizontal_first:
			var stub_x := _step_towards_with_min_delta(start.x, end.x, start_clearance_xy.x)
			if not is_equal_approx(stub_x, start.x):
				var stub := Vector3(stub_x, start.y, 0.0)
				points.append(stub)
				routing_start = stub

			var end_stub_y := _step_towards_with_min_delta(end.y, start.y, end_clearance_xy.y)
			if not is_equal_approx(end_stub_y, end.y):
				routing_end = Vector3(end.x, end_stub_y, 0.0)
		else:
			var stub_y := _step_towards_with_min_delta(start.y, end.y, start_clearance_xy.y)
			if not is_equal_approx(stub_y, start.y):
				var stub := Vector3(start.x, stub_y, 0.0)
				points.append(stub)
				routing_start = stub

			var end_stub_x := _step_towards_with_min_delta(end.x, start.x, end_clearance_xy.x)
			if not is_equal_approx(end_stub_x, end.x):
				routing_end = Vector3(end_stub_x, end.y, 0.0)

	current = routing_start

	for _i in range(bends):
		if axis_is_x:
			var next_x := _rand_between_towards(current.x, routing_end.x)
			if absf(next_x - current.x) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(next_x, current.y, 0.0)
			points.append(current)
		else:
			var next_y := _rand_between_towards(current.y, routing_end.y)
			if absf(next_y - current.y) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(current.x, next_y, 0.0)
			points.append(current)

		axis_is_x = !axis_is_x

	if horizontal_first:
		if absf(routing_end.x - current.x) > 0.01:
			current = Vector3(routing_end.x, current.y, 0.0)
			points.append(current)
		if absf(routing_end.y - current.y) > 0.01:
			current = Vector3(routing_end.x, routing_end.y, 0.0)
			points.append(current)
	else:
		if absf(routing_end.y - current.y) > 0.01:
			current = Vector3(current.x, routing_end.y, 0.0)
			points.append(current)
		if absf(routing_end.x - current.x) > 0.01:
			current = Vector3(routing_end.x, routing_end.y, 0.0)
			points.append(current)

	if routing_end != end:
		points.append(end)

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

func _step_towards_with_min_delta(from: float, to: float, min_delta: float) -> float:
	var d := to - from
	var delta := maxf(min_delta, 0.0)
	if absf(d) <= delta + 0.0001:
		return from
	return from + signf(d) * delta
