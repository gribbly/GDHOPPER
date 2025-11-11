extends Node3D

@onready var debug_immediate_mesh : MeshInstance3D = %DebugImmediateMesh

func _ready() -> void:
	RH.print("📐 debug_visuals.gd | ready()", 1)

	if debug_immediate_mesh:
		RH.print("📐 debug_visuals.gd | found %DebugImmediateMesh", 3)
