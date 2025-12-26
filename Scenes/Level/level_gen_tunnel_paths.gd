## Procgen step: produce a "mostly L-shaped" polyline path between two points (pure logic).
## - Generates 0..N extra bend waypoints, then finishes with an L-shaped approach.
## - Output is a list of `Vector3` points suitable for carving with repeated tunnel shapes.
class_name LevelGenTunnelPaths
extends RefCounted

var grid_cell_size: Vector2 = Vector2.ZERO

# Tuning/constraints:
# If true, we disallow using the *bottom* edge of a cavern as a connection point for tunnels.
# "Bottom edge" is defined relative to the cavern center (smaller Y).
var forbid_start_exit_bottom: bool = false
var forbid_end_entry_bottom: bool = false

func build_l_path_with_bends(
	start: Vector3,
	end: Vector3,
	max_extra_bends: int,
	start_clearance_xy: Vector2 = Vector2.ZERO,
	end_clearance_xy: Vector2 = Vector2.ZERO
) -> Array[Vector3]:
	var snap_to_grid := grid_cell_size != Vector2.ZERO
	if snap_to_grid:
		start = _snap_to_cell_center(start, grid_cell_size)
		end = _snap_to_cell_center(end, grid_cell_size)

	var points: Array[Vector3] = [start]

	var current: Vector3 = start
	var bends: int = 0
	if max_extra_bends > 0:
		bends = RH.get_random_int(0, max_extra_bends)

	var horizontal_first: bool = RH.get_random_bool(0.5)
	var axis_is_x: bool = horizontal_first

	var routing_start: Vector3 = start
	var routing_end: Vector3 = end

	# STEP 0: Apply "allowed cavern edge" constraints to the endpoint routing.
	#
	# We route tunnels between cavern *centers*, and the first/last segment direction implicitly decides
	# which edge of the cavern the tunnel crosses.
	#
	# Desired rule (gameplay/design): tunnels may only enter/exit caverns via TOP/LEFT/RIGHT edges.
	# In other words, we forbid using the BOTTOM edge as an entry/exit.
	#
	# Coordinate convention: in ROCKHOPPER, +Y is "up". So "bottom" means "smaller Y than the cavern center".
	# - "Exit via bottom"   == first segment from `start` goes DOWN (end.y < start.y).
	# - "Enter via bottom"  == last segment into `end` comes UP from below (end.y > start.y).
	#
	# We enforce this by forcing which axis we prefer at the start/end:
	# - If the overall connection would need to go downwards, force the path to start horizontally (left/right).
	# - If the overall connection would need to go upwards, force the path to finish horizontally (left/right).
	#
	# Note: These two cases cannot both be true for the same (start,end) pair.
	var must_start_horizontal := self.forbid_start_exit_bottom and (end.y < start.y - 0.001)
	var must_end_horizontal := self.forbid_end_entry_bottom and (end.y > start.y + 0.001)
	if must_start_horizontal:
		horizontal_first = true
		axis_is_x = true
	elif must_end_horizontal:
		horizontal_first = false
		axis_is_x = false

	# Try to avoid "instant turns" right after leaving a cavern by inserting a straight "stub"
	# from the start cavern, and by keeping the final turn away from the end cavern.
	#
	# `*_clearance_xy` is a world-space distance measured from cavern center:
	#   (cavern half-extent along axis) + (min straight distance after the edge).
	# Even if the caller doesn't provide clearance boxes, we still want the "no bottom entry/exit" constraint
	# to be enforceable. So we run this block if either clearance is set OR if a bottom constraint is active.
	if start_clearance_xy != Vector2.ZERO or end_clearance_xy != Vector2.ZERO or must_start_horizontal or must_end_horizontal:
		var dx := end.x - start.x
		var dy := end.y - start.y

		var horiz_feasible: bool = absf(dx) >= start_clearance_xy.x and absf(dy) >= end_clearance_xy.y
		var vert_feasible: bool = absf(dy) >= start_clearance_xy.y and absf(dx) >= end_clearance_xy.x

		# STEP 1: Choose whether we route "horizontal first" vs "vertical first".
		# - Normally this is random, with feasibility nudges from clearance boxes.
		# - If the caller forbids bottom entry/exit, the constraint above can force this choice.
		if (not must_start_horizontal) and (not must_end_horizontal) and horizontal_first and not horiz_feasible and vert_feasible:
			horizontal_first = false
			axis_is_x = false
		elif (not must_start_horizontal) and (not must_end_horizontal) and (not horizontal_first) and not vert_feasible and horiz_feasible:
			horizontal_first = true
			axis_is_x = true

		if horizontal_first:
			# STEP 2A: Add a horizontal "exit stub" from the start cavern (when possible).
			# This creates a straight segment leaving the cavern before we allow bends.
			var stub_x := _step_towards_with_min_delta(start.x, end.x, start_clearance_xy.x)
			if not is_equal_approx(stub_x, start.x):
				var stub := Vector3(stub_x, start.y, 0.0)
				if snap_to_grid:
					stub = _snap_to_cell_center(stub, grid_cell_size)
				points.append(stub)
				routing_start = stub
			elif must_start_horizontal:
				# STEP 2A (forced detour): If we *must* start horizontally but can't "step toward" (e.g. end.x == start.x),
				# create a sideways detour so the first segment exits via LEFT or RIGHT instead of the bottom edge.
				var delta := _min_detour_delta(start_clearance_xy.x, grid_cell_size.x if snap_to_grid else 0.0)
				var s := 1.0 if RH.get_random_bool(0.5) else -1.0
				var detour := Vector3(start.x + (s * delta), start.y, 0.0)
				if snap_to_grid:
					detour = _snap_to_cell_center(detour, grid_cell_size)
				if detour.distance_to(start) > 0.001:
					points.append(detour)
					routing_start = detour

			# STEP 3A: Keep the *final* turn away from the end cavern by shifting the routing-end in Y.
			var end_stub_y := _step_towards_with_min_delta(end.y, start.y, end_clearance_xy.y)
			if not is_equal_approx(end_stub_y, end.y):
				routing_end = Vector3(end.x, end_stub_y, 0.0)
				if snap_to_grid:
					routing_end = _snap_to_cell_center(routing_end, grid_cell_size)
		else:
			# STEP 2B: Add a vertical "exit stub" from the start cavern (when possible).
			# This creates a straight segment leaving the cavern before we allow bends.
			var stub_y := _step_towards_with_min_delta(start.y, end.y, start_clearance_xy.y)
			if not is_equal_approx(stub_y, start.y):
				var stub := Vector3(start.x, stub_y, 0.0)
				if snap_to_grid:
					stub = _snap_to_cell_center(stub, grid_cell_size)
				points.append(stub)
				routing_start = stub

			# STEP 3B: Keep the *final* turn away from the end cavern by shifting the routing-end in X.
			# If we must NOT enter via the bottom edge, we also need to ensure the final approach is horizontal.
			var end_stub_x := _step_towards_with_min_delta(end.x, start.x, end_clearance_xy.x)
			if not is_equal_approx(end_stub_x, end.x):
				routing_end = Vector3(end_stub_x, end.y, 0.0)
				if snap_to_grid:
					routing_end = _snap_to_cell_center(routing_end, grid_cell_size)
			elif must_end_horizontal:
				# STEP 3B (forced detour): If we *must* finish horizontally but can't "step toward" (e.g. end.x == start.x),
				# force a sideways routing-end so the final segment(s) into `end` come from LEFT/RIGHT, not from below.
				var delta := _min_detour_delta(end_clearance_xy.x, grid_cell_size.x if snap_to_grid else 0.0)
				var s := 1.0 if RH.get_random_bool(0.5) else -1.0
				routing_end = Vector3(end.x + (s * delta), end.y, 0.0)
				if snap_to_grid:
					routing_end = _snap_to_cell_center(routing_end, grid_cell_size)

	current = routing_start

	# STEP 4: Insert optional extra bends between routing_start and routing_end.
	# These are purely for making paths look less uniform; the path is still axis-aligned.
	for _i in range(bends):
		if axis_is_x:
			var next_x := _rand_between_towards(current.x, routing_end.x)
			if snap_to_grid:
				next_x = _rand_grid_center_between_towards(current.x, routing_end.x, grid_cell_size.x)
			if absf(next_x - current.x) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(next_x, current.y, 0.0)
			points.append(current)
		else:
			var next_y := _rand_between_towards(current.y, routing_end.y)
			if snap_to_grid:
				next_y = _rand_grid_center_between_towards(current.y, routing_end.y, grid_cell_size.y)
			if absf(next_y - current.y) < 0.01:
				axis_is_x = !axis_is_x
				continue
			current = Vector3(current.x, next_y, 0.0)
			points.append(current)

		axis_is_x = !axis_is_x

	if horizontal_first:
		# STEP 5A: Finish with the final L approach: X then Y.
		if absf(routing_end.x - current.x) > 0.01:
			current = Vector3(routing_end.x, current.y, 0.0)
			points.append(current)
		if absf(routing_end.y - current.y) > 0.01:
			current = Vector3(routing_end.x, routing_end.y, 0.0)
			points.append(current)
	else:
		# STEP 5B: Finish with the final L approach: Y then X.
		if absf(routing_end.y - current.y) > 0.01:
			current = Vector3(current.x, routing_end.y, 0.0)
			points.append(current)
		if absf(routing_end.x - current.x) > 0.01:
			current = Vector3(routing_end.x, routing_end.y, 0.0)
			points.append(current)

	# STEP 6: If we introduced an adjusted routing_end, append the real end as the final waypoint.
	# This commonly results in the last segment being horizontal (which is what we want when forbidding bottom entry).
	if routing_end != end:
		points.append(end)

	var out := _dedupe_consecutive(points)
	return _remove_collinear(out)

func _rand_between_towards(current: float, target: float) -> float:
	var lo := minf(current, target)
	var hi := maxf(current, target)
	if hi - lo < 0.01:
		return target
	var v := RH.get_random_float(lo, hi)
	if target >= current:
		return clampf(v, current, target)
	return clampf(v, target, current)

func _rand_grid_center_between_towards(current: float, target: float, cell: float) -> float:
	if cell <= 0.0:
		return target
	var current_i := int(floor(current / cell))
	var target_i := int(floor(target / cell))
	if current_i == target_i:
		return current
	if target_i > current_i:
		var i := RH.get_random_int(current_i + 1, target_i)
		return (float(i) + 0.5) * cell
	var j := RH.get_random_int(target_i, current_i - 1)
	return (float(j) + 0.5) * cell

func _dedupe_consecutive(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() <= 1:
		return points
	var out: Array[Vector3] = [points[0]]
	for i in range(1, points.size()):
		if points[i].distance_to(out.back()) > 0.001:
			out.append(points[i])
	return out

func _remove_collinear(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() <= 2:
		return points
	var out: Array[Vector3] = [points[0]]
	for i in range(1, points.size() - 1):
		var prev: Vector3 = out.back()
		var cur: Vector3 = points[i]
		var nxt: Vector3 = points[i + 1]
		var collinear_x := is_equal_approx(prev.y, cur.y) and is_equal_approx(cur.y, nxt.y) and is_equal_approx(prev.z, cur.z) and is_equal_approx(cur.z, nxt.z)
		var collinear_y := is_equal_approx(prev.x, cur.x) and is_equal_approx(cur.x, nxt.x) and is_equal_approx(prev.z, cur.z) and is_equal_approx(cur.z, nxt.z)
		if collinear_x or collinear_y:
			continue
		out.append(cur)
	out.append(points.back())
	return out

func _step_towards_with_min_delta(from: float, to: float, min_delta: float) -> float:
	var d := to - from
	var delta := maxf(min_delta, 0.0)
	if absf(d) <= delta + 0.0001:
		return from
	return from + signf(d) * delta

func _min_detour_delta(clearance: float, cell_size: float) -> float:
	# When we need to force a horizontal segment but `start.x == end.x` (or similar),
	# we pick a sideways detour distance that:
	# - is at least the caller-provided clearance (if any), so we fully clear the cavern wall, AND
	# - is at least one grid cell (when snapping), so snapping can't collapse the detour back onto the same center.
	var delta := maxf(clearance, 0.0)
	if delta < 0.001:
		return cell_size if cell_size > 0.0 else 1.0
	if cell_size > 0.0:
		return maxf(delta, cell_size)
	return delta

func _snap_to_cell_center(p: Vector3, cell_size: Vector2) -> Vector3:
	var x := p.x
	var y := p.y
	if cell_size.x > 0.0:
		x = (floor(p.x / cell_size.x) + 0.5) * cell_size.x
	if cell_size.y > 0.0:
		y = (floor(p.y / cell_size.y) + 0.5) * cell_size.y
	return Vector3(x, y, 0.0)
