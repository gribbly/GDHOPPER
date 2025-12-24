## Logical 2D grid used during procgen (pure data, no Nodes).
## - Cells can store arbitrary values; in procgen we currently store a `bool` "blocked" flag.
## - World space for the grid is 2D (`Vector2`); final placements are converted to `Vector3` by callers.
class_name LevelGrid
extends RefCounted

# Implements a 2D grid for use by level.gd
# Usage:
#	var grid := LevelGrid.new(50, 80, Vector2(2.0, 2.0), Vector2(-80, -50))
#
#	grid.set_cell(1, 2, {"type": "rock"})
#	var center: Vector2 = grid.cell_center(1, 2)

var rows: int
var cols: int
var cell_size: Vector2
var origin: Vector2        # top-left corner of cell (0,0) in local/world 2D space

var _cells: Array          # sized rows*cols

func _init(p_rows: int, p_cols: int, p_cell_size: Vector2, p_origin: Vector2 = Vector2.ZERO) -> void:
	RH.print("🗺️ level_grid.gd | _init origin = %s" % p_origin, 1)
	rows = p_rows
	cols = p_cols
	cell_size = p_cell_size
	origin = p_origin
	_cells = []
	_cells.resize(rows * cols)

func _idx(row: int, col: int) -> int:
	return row * cols + col

func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < rows and col >= 0 and col < cols

func get_cell(row: int, col: int):
	assert(in_bounds(row, col))
	return _cells[_idx(row, col)]

func set_cell(row: int, col: int, value) -> void:
	assert(in_bounds(row, col))
	_cells[_idx(row, col)] = value

func cell_center(row: int, col: int) -> Vector2:
	assert(in_bounds(row, col))
	return origin + Vector2((col + 0.5) * cell_size.x, (row + 0.5) * cell_size.y)

func cell_rect(row: int, col: int) -> Rect2:
	assert(in_bounds(row, col))
	var top_left := origin + Vector2(col * cell_size.x, row * cell_size.y)
	return Rect2(top_left, cell_size)

func world_to_cell(pos: Vector2) -> Vector2i:
	# Returns the row/col containing pos (can be out of bounds)
	var local := pos - origin
	var col := int(floor(local.x / cell_size.x))
	var row := int(floor(local.y / cell_size.y))
	RH.print("🪨 level_grid.gd | world_to_cell returning %s" % Vector2i(row, col), 1)
	return Vector2i(row, col)

func for_each_cell(cb: Callable) -> void:
	# cb(row:int, col:int, value) -> void
	for row in range(rows):
		for col in range(cols):
			cb.call(row, col, _cells[_idx(row, col)])

func for_each_cell_mut(cb: Callable) -> void:
	# cb(row:int, col:int, get:Callable, set:Callable) -> void
	# Useful if you want the callback to modify cells without returning anything.
	for row in range(rows):
		for col in range(cols):
			var r := row
			var c := col
			var getter := func(): return _cells[_idx(r, c)]
			var setter := func(v): _cells[_idx(r, c)] = v
			cb.call(r, c, getter, setter)

func positions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.resize(rows * cols)
	var i := 0
	for row in range(rows):
		for col in range(cols):
			out[i] = Vector2i(row, col)
			i += 1
	return out

func values() -> Array:
	# Returns a shallow copy
	return _cells.duplicate(false)

func row_iter(row: int) -> Array:
	assert(row >= 0 and row < rows)
	var out: Array = []
	out.resize(cols)
	for col in range(cols):
		out[col] = _cells[_idx(row, col)]
	return out

func col_iter(col: int) -> Array:
	assert(col >= 0 and col < cols)
	var out: Array = []
	out.resize(rows)
	for row in range(rows):
		out[row] = _cells[_idx(row, col)]
	return out
