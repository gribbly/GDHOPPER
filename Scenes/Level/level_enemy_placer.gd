## Procgen step: place enemies into generated caverns (scene graph / gameplay).
## - Keeps enemy placement out of `level.gd` so procgen stays readable.
## - Uses raycasts to find floor points on the carved/baked cavern mesh.
class_name LevelEnemyPlacer
extends RefCounted

const _UP := Vector3.UP


func place_one_test_launcher_per_cavern(
	level: Node3D,
	caverns: Array[LevelGenCavern],
	cavern_template_half_size_xy: Vector2,
	test_launcher: PackedScene,
	spawn_probability: float,
	extra_depth: float
) -> int:
	if level == null or test_launcher == null:
		return 0
	if caverns.is_empty():
		return 0
	if cavern_template_half_size_xy == Vector2.ZERO:
		return 0

	var placed := 0
	for cav in caverns:
		if not RH.get_random_bool(spawn_probability):
			continue

		var floor_hit := _raycast_cavern_floor(level, cav, cavern_template_half_size_xy)
		if floor_hit.is_empty():
			continue

		var launcher_instance := test_launcher.instantiate() as Node3D
		if launcher_instance == null:
			RH.print("🪨 level_enemy_placer.gd | ⚠️ test_launcher scene did not instantiate as Node3D", 1)
			continue

		var hit_pos_global: Vector3 = floor_hit["position"]
		var hit_normal: Vector3 = floor_hit.get("normal", _UP)
		var pos_global := hit_pos_global - (hit_normal * maxf(extra_depth, 0.0))

		level.add_child(launcher_instance)
		launcher_instance.global_position = pos_global
		placed += 1

		if RH.show_debug_visuals == true:
			RH.debug_visuals.rh_debug_x_with_label(pos_global, "launcher", Color(0.9, 0.2, 0.25))

	return placed


func _raycast_cavern_floor(
	level: Node3D,
	cav: LevelGenCavern,
	cavern_template_half_size_xy: Vector2
) -> Dictionary:
	var world := level.get_world_3d()
	if world == null:
		return {}

	var half := cavern_template_half_size_xy * cav.scale_xy

	# Pick a point that should be within the cavern bounds in X, and safely inside the void in Y.
	# We raycast downward to find the carved rock surface (the cavern floor).
	var offset_x := RH.get_random_float(-half.x * 0.45, half.x * 0.45)
	var probe_origin_local := cav.center_3d + Vector3(offset_x, half.y * 0.25, 0.0)
	var probe_origin_global := level.to_global(probe_origin_local)

	var ray_len := (half.y * 2.5) + 64.0
	var from := probe_origin_global
	var to := probe_origin_global - (_UP * ray_len)

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	return world.direct_space_state.intersect_ray(query)

