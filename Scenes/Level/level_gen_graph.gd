## Procgen step: build a connection graph between caverns (pure logic).
## - Computes an MST (Prim's algorithm) over a complete graph of caverns.
## - Optionally adds a small number of extra edges for loops.
## - Returns edges as index pairs into the cavern array.
class_name LevelGenGraph
extends RefCounted

func build_mst_edges(caverns: Array[LevelGenCavern]) -> Array[Vector2i]:
	var edges: Array[Vector2i] = []
	var n := caverns.size()
	if n <= 1:
		return edges

	var in_tree: Array[bool] = []
	in_tree.resize(n)
	in_tree.fill(false)
	in_tree[0] = true
	var in_tree_count := 1

	while in_tree_count < n:
		var best_w := INF
		var best_a := -1
		var best_b := -1

		for a in range(n):
			if not in_tree[a]:
				continue
			for b in range(n):
				if in_tree[b]:
					continue
				var w := _weight(caverns[a], caverns[b])
				if w < best_w:
					best_w = w
					best_a = a
					best_b = b

		if best_a == -1:
			break

		edges.append(Vector2i(best_a, best_b))
		in_tree[best_b] = true
		in_tree_count += 1

	return edges

func add_extra_edges_nearest_nonconnected(
	caverns: Array[LevelGenCavern],
	edges: Array[Vector2i],
	extra_connection_probability: float
) -> Array[Vector2i]:
	if caverns.size() <= 2:
		return edges

	var connected := _build_connected_set(edges)
	var n := caverns.size()

	for i in range(n):
		if not RH.get_random_bool(extra_connection_probability):
			continue

		var nearest_j := -1
		var nearest_w := INF
		for j in range(n):
			if i == j:
				continue
			if _has_edge(connected, i, j):
				continue
			var w := _weight(caverns[i], caverns[j])
			if w < nearest_w:
				nearest_w = w
				nearest_j = j

		if nearest_j != -1:
			var e := Vector2i(mini(i, nearest_j), maxi(i, nearest_j))
			edges.append(e)
			connected[e] = true

	return edges

func _weight(a: LevelGenCavern, b: LevelGenCavern) -> float:
	var dx := absf(b.center_2d.x - a.center_2d.x)
	var dy := absf(b.center_2d.y - a.center_2d.y)
	return dx + dy

func _build_connected_set(edges: Array[Vector2i]) -> Dictionary:
	var connected_set: Dictionary = {}
	for e in edges:
		var key := Vector2i(mini(e.x, e.y), maxi(e.x, e.y))
		connected_set[key] = true
	return connected_set

func _has_edge(connected: Dictionary, a: int, b: int) -> bool:
	return connected.has(Vector2i(mini(a, b), maxi(a, b)))
