extends GPUParticles3D

# Controls a ThrustParticles scene attached to the ship

func _ready() -> void:
	RH.print("🔥 thrust_particles.gd | ready()", 2)
	emitting = false

func start() -> void:
	emitting = true

func stop() -> void:
	emitting = false