# ShatterEffect.gd
extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D

# This function is called from the outside to start the effect.
func burst():
	# Start the particle emission.
	particles.emitting = true
	
	# Create a timer that will free the scene after the particles have faded.
	# We add a small buffer (0.1s) to be safe.
	var timer = get_tree().create_timer(particles.lifetime + 0.1)
	await timer.timeout
	queue_free()
