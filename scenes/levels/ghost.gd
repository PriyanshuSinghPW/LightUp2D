extends AnimatedSprite2D

## The group this enemy belongs to.
const GHOST_GROUP = "ghost"

## Signal emitted when the ghost touches the player.
signal player_touched

## The speed at which the ghost moves towards the player.
@export var move_speed: float = 50.0
## The frequency of the floating motion.
@export var float_frequency: float = 2.0
## The amplitude of the floating motion.
@export var float_amplitude: float = 10.0
## The time it takes for the ghost to die when hit by the beam.
@export var time_to_die: float = 0.7
## The time the player must be in contact with the ghost for a game over.
@export var game_over_contact_time: float = 2.0
@export var fade_in_duration: float = 0.5

var player: CharacterBody2D = null
var is_in_beam: bool = false
var time_in_beam: float = 0.0
var time_in_contact_with_player: float = 0.0
# --- FIX START: Add a flag to prevent multiple triggers ---
var _game_over_triggered: bool = false
# --- FIX END ---

var original_position: Vector2

func _ready():
	# --- START: FADE-IN ANIMATION ---
	# Start the ghost as fully transparent
	self.modulate.a = 0.0
	
	# Create a tween to handle the animation
	var tween = create_tween()
	# Animate the 'a' (alpha) channel of the modulate property to 1 (fully visible)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	# --- END: FADE-IN ANIMATION ---
	
	add_to_group(GHOST_GROUP)
	original_position = global_position
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float):
	if not is_instance_valid(player):
		return

	# Movement towards the player
	var direction = (player.global_position - global_position).normalized()
	global_position += direction * move_speed * delta

	# Floating effect
	var float_offset = Vector2(0, sin(Time.get_ticks_msec() * 0.001 * float_frequency) * float_amplitude)
	position += float_offset * delta * 50 # Multiplying by a factor to make the float more noticeable

	# Flip sprite based on direction
	if direction.x > 0:
		self.flip_h = true
	elif direction.x < 0:
		self.flip_h = false

	# Handle beam damage
	if is_in_beam:
		time_in_beam += delta
		shake()
		modulate = Color.RED
		if time_in_beam >= time_to_die:
			die()
	else:
		# Reset if not in the beam
		time_in_beam = 0
		self.offset = Vector2.ZERO
		self.modulate = Color.WHITE

## Called when the ghost is hit by the beam.
func hit_by_beam():
	is_in_beam = true

## Called when the ghost is no longer hit by the beam.
func left_beam():
	is_in_beam = false

## Creates a shaking effect.
func shake():
	var random_offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
	self.offset = random_offset

## Handles the death of the ghost.
func die():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Fade out
	tween.tween_callback(queue_free)

## Called when the Area2D for player contact detects a body.
func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		time_in_contact_with_player = 0 # Reset timer on new contact

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		time_in_contact_with_player = 0 # Reset timer if player leaves

func _process(delta: float):
	# Check for continuous contact with the player
	if get_node("Area2D").get_overlapping_bodies().any(func(body): return body.is_in_group("player")):
		time_in_contact_with_player += delta
		# --- FIX START: Check the flag before triggering ---
		if time_in_contact_with_player >= game_over_contact_time and not _game_over_triggered:
			game_over()
		# --- FIX END ---
	else:
		time_in_contact_with_player = 0

## Function to handle game over logic.
func game_over():
	# --- FIX START: Set flag and disable processing ---
	_game_over_triggered = true
	set_physics_process(false) # Stop moving
	set_process(false) # Stop checking for game over
	# --- FIX END ---
	
	print("Game Over!")
	GameManager.trigger_game_over()
