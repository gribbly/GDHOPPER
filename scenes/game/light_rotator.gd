extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rotations_per_second = 1.0 / 2.0   # one full turn every 2 seconds
	rotation.y += TAU * rotations_per_second * delta
