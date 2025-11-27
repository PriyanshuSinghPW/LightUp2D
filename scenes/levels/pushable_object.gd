extends CharacterBody2D

### MODIFICATION START ###
# Signal to announce that the object has been pushed for the first time.
signal pushed

## How quickly the object slows down after being pushed.
@export var friction: float = 0.1

var push_velocity: Vector2 = Vector2.ZERO

func _physics_process(delta: float):
	# Apply the current push velocity to the object's movement.
	velocity = push_velocity
	move_and_slide()
	# Gradually slow down the object using linear interpolation (lerp).
	# This simulates friction.
	push_velocity = push_velocity.lerp(Vector2.ZERO, friction)

func apply_push(force: Vector2):
	"""
	This function is called by the player to apply a push force.
	"""
	push_velocity = force
	# If this is the very first time the object is pushed, emit our signal.
	pushed.emit()
