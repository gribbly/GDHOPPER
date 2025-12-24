class_name ShipInventory
extends RefCounted

class Item:
	var scene_path: String
	var mass: float
	var display_name: String

	func _init(p_scene_path: String, p_mass: float, p_display_name: String) -> void:
		scene_path = p_scene_path
		mass = p_mass
		display_name = p_display_name

var _items: Array[Item] = []

func add_item(scene_path: String, mass: float, display_name: String = "") -> void:
	_items.append(Item.new(scene_path, mass, display_name))

func pop_last() -> Item:
	if _items.is_empty():
		return null
	return _items.pop_back()

func total_mass() -> float:
	var total := 0.0
	for item in _items:
		total += item.mass
	return total

func count() -> int:
	return _items.size()

