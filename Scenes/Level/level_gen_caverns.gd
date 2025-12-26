## Procgen step: choose cavern placements on the logical `LevelGrid` (pure logic).
## - Uses rejection sampling + inflated footprints to enforce spacing.
## - Returns `LevelGenCavern` data; does NOT instantiate any Nodes or meshes.
## - `level.gd` takes the returned caverns and asks `LevelCSG` to carve them.
class_name LevelGenCaverns
extends RefCounted

func init_grid_unblocked(grid: LevelGrid) -> void:
	grid.for_each_cell_mut(func(_r: int, _c: int, _get: Callable, set_cell: Callable) -> void:
		set_cell.call(false)
	)

func place_caverns(
	grid: LevelGrid,
	cavern_template_half_size_xy: Vector2,
	requests: Array[Dictionary],
	avoid_borders: bool,
	border_margin_cells: int,
	scale_variation: float,
	padding_cells: int,
	attempts_per_cavern: int,
	best_of_k: int
) -> Array[LevelGenCavern]:
	var caverns: Array[LevelGenCavern] = []
	var next_id := 0
	var variation := clampf(scale_variation, 0.0, 1.0)

	for req in requests:
		var count: int = req.get("count", 0)
		var scale_xy: float = req.get("scale_xy", 1.0)
		var size_class: int = req.get("size_class", LevelGenCavern.SizeClass.LARGE)
		var distance_weight: float = req.get("distance_weight", 0.0)
		for _i in range(count):
			var noisy_scale_xy := scale_xy * (1.0 + RH.get_random_float(-variation, variation))
			noisy_scale_xy = maxf(noisy_scale_xy, 0.01)
			var placed: LevelGenCavern = null
			for pad in range(padding_cells, -1, -1):
				placed = _try_place_one(
					grid,
					cavern_template_half_size_xy,
					noisy_scale_xy,
					size_class,
					distance_weight,
					caverns,
					next_id,
					avoid_borders,
					border_margin_cells,
					pad,
					attempts_per_cavern,
					best_of_k
				)
				if placed != null:
					if pad < padding_cells:
						RH.print("🗺️ level_gen_caverns.gd | reduced padding %s→%s to fit cavern (class=%s)" % [padding_cells, pad, size_class], 2)
					break

			if placed != null:
				caverns.append(placed)
				next_id += 1
			else:
				RH.print("🗺️ level_gen_caverns.gd | ⚠️ failed to place cavern (class=%s); skipping" % size_class, 1)

	return caverns

func _try_place_one(
	grid: LevelGrid,
	cavern_template_half_size_xy: Vector2,
	scale_xy: float,
	size_class: int,
	distance_weight: float,
	existing: Array[LevelGenCavern],
	next_id: int,
	avoid_borders: bool,
	border_margin_cells: int,
	padding_cells: int,
	attempts_per_cavern: int,
	best_of_k: int
) -> LevelGenCavern:
	for attempt in range(attempts_per_cavern):
		var candidates := _build_candidates(grid, avoid_borders, border_margin_cells)
		if candidates.is_empty():
			return null

		var chosen := _choose_candidate_best_of_k(
			grid,
			candidates,
			existing,
			distance_weight,
			avoid_borders,
			border_margin_cells,
			best_of_k
		)

		var footprint_radius_cells := _footprint_radius_cells(grid, cavern_template_half_size_xy, scale_xy, padding_cells)
		if _footprint_fits(grid, chosen, footprint_radius_cells):
			_mark_footprint_blocked(grid, chosen, footprint_radius_cells)
			var center_2d := grid.cell_center(chosen.x, chosen.y)
			return LevelGenCavern.new(next_id, size_class, scale_xy, chosen, center_2d)

		if attempt == attempts_per_cavern - 1:
			RH.print("🗺️ level_gen_caverns.gd | failed to fit footprint after %s attempts" % attempts_per_cavern, 2)

	return null

func _build_candidates(grid: LevelGrid, avoid_borders: bool, border_margin_cells: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for row in range(grid.rows):
		for col in range(grid.cols):
			if grid.get_cell(row, col) == true:
				continue
			if avoid_borders:
				if row < border_margin_cells or col < border_margin_cells:
					continue
				if row >= grid.rows - border_margin_cells or col >= grid.cols - border_margin_cells:
					continue
			out.append(Vector2i(row, col))
	return out

func _choose_candidate_best_of_k(
	grid: LevelGrid,
	candidates: Array[Vector2i],
	existing: Array[LevelGenCavern],
	distance_weight: float,
	avoid_borders: bool,
	border_margin_cells: int,
	best_of_k: int
) -> Vector2i:
	var k: int = mini(best_of_k, candidates.size())
	var best_cell: Vector2i = candidates[RH.get_random_index(candidates.size())]
	var best_score: float = -INF

	for _i in range(k):
		var cell: Vector2i = candidates[RH.get_random_index(candidates.size())]
		var score: float = _score_candidate(grid, cell, existing, distance_weight, avoid_borders, border_margin_cells)
		if score > best_score:
			best_score = score
			best_cell = cell

	return best_cell

func _score_candidate(
	grid: LevelGrid,
	cell: Vector2i,
	existing: Array[LevelGenCavern],
	distance_weight: float,
	avoid_borders: bool,
	border_margin_cells: int
) -> float:
	var p2 := grid.cell_center(cell.x, cell.y)

	var nearest := INF
	for cav in existing:
		var d := p2.distance_to(cav.center_2d)
		if d < nearest:
			nearest = d
	if existing.is_empty():
		nearest = 0.0

	var dist_to_edge_cells: int = mini(
		mini(cell.x, grid.rows - 1 - cell.x),
		mini(cell.y, grid.cols - 1 - cell.y)
	)
	var edge_penalty := 0.0
	if avoid_borders:
		edge_penalty = 0.0
	else:
		edge_penalty = 1.0 / float(dist_to_edge_cells + 1)
	var noise := RH.get_random_float(0.0, 0.25 * maxf(grid.cell_size.x, grid.cell_size.y))

	return (nearest * distance_weight) - (edge_penalty * float(border_margin_cells)) + noise

func _footprint_radius_cells(grid: LevelGrid, cavern_template_half_size_xy: Vector2, scale_xy: float, padding_cells: int) -> Vector2i:
	var half_world := cavern_template_half_size_xy * scale_xy
	var radius_x := int(ceili(half_world.x / grid.cell_size.x)) + padding_cells
	var radius_y := int(ceili(half_world.y / grid.cell_size.y)) + padding_cells
	return Vector2i(maxi(radius_y, 1), maxi(radius_x, 1))

func _footprint_fits(grid: LevelGrid, center_cell: Vector2i, radius_cells: Vector2i) -> bool:
	for row in range(center_cell.x - radius_cells.x, center_cell.x + radius_cells.x + 1):
		for col in range(center_cell.y - radius_cells.y, center_cell.y + radius_cells.y + 1):
			if not grid.in_bounds(row, col):
				return false
			if not _in_ellipse(center_cell, Vector2i(row, col), radius_cells):
				continue
			if grid.get_cell(row, col) == true:
				return false
	return true

func _mark_footprint_blocked(grid: LevelGrid, center_cell: Vector2i, radius_cells: Vector2i) -> void:
	for row in range(center_cell.x - radius_cells.x, center_cell.x + radius_cells.x + 1):
		for col in range(center_cell.y - radius_cells.y, center_cell.y + radius_cells.y + 1):
			if not grid.in_bounds(row, col):
				continue
			if not _in_ellipse(center_cell, Vector2i(row, col), radius_cells):
				continue
			grid.set_cell(row, col, true)

func _in_ellipse(center: Vector2i, cell: Vector2i, radius: Vector2i) -> bool:
	var rx := float(maxi(radius.y, 1))
	var ry := float(maxi(radius.x, 1))
	var dx := float(cell.y - center.y) / rx
	var dy := float(cell.x - center.x) / ry
	return (dx * dx + dy * dy) <= 1.0
