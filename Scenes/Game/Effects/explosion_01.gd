extends MeshInstance3D

@export var lifetime_seconds := 3.0

var _mat: ShaderMaterial

func prime() -> void:
	var mat := get_surface_override_material(0) as ShaderMaterial
	if mat == null:
		push_error("No ShaderMaterial on Surface Material Override[0].")
		return

	_mat = mat.duplicate() as ShaderMaterial
	set_surface_override_material(0, _mat)
	_mat.set_shader_parameter("flash", true)

func _ready() -> void:	
	# Wait until one frame has actually been drawn, then turn flash off.
	await RenderingServer.frame_post_draw
	if _mat:
		_mat.set_shader_parameter("flash", false)

	RH.print("📸 explosion_01.gd | emit signal \"explosion\"", 1)
	SignalBus.emit_signal("explosion") #Note: Add params after "explosion", ...

	await get_tree().create_timer(lifetime_seconds).timeout
	queue_free()
