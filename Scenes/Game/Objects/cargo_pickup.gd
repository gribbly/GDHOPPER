class_name CargoPickup
extends RigidBody3D

@export var pickup_enabled := true

func get_pickup_mass() -> float:
	return mass

func get_respawn_scene_path() -> String:
	return scene_file_path

