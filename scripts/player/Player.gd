extends CharacterBody2D

# Player movement script for a top-down oblique view.

# We'll get the speed from our global constants file.
var speed = Constants.PLAYER_DEFAULTS.speed
# A multiplier for how much faster we move and animate when sprinting.
@export var sprint_multiplier: float = 1.75
# The base pitch for footstep sounds.
@export var base_footstep_pitch: float = 1.0
# The pitch multiplier for footstep sounds when sprinting.
@export var sprint_footstep_pitch_multiplier: float = 1.2

# Keep track of the last movement direction to determine the correct idle state.
var last_direction = Vector2(0, 1) # Default to facing down (front)
var is_pushing: bool = false # State to track if we are pushing

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer

func _ready() -> void:
	# Set the initial state to idle front.
	animated_sprite.play("idle front")
	
	# Configure camera controller with our camera
	if camera:
		CameraController.configure(camera)
	
	# Ensure the footstep player starts with the base pitch.
	footstep_player.pitch_scale = base_footstep_pitch

func _physics_process(delta: float) -> void:
	# Get the input direction from the player's input.
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Handle sprinting.
	var current_speed = speed
	var footstep_pitch_scale = base_footstep_pitch
	if Input.is_action_pressed("sprint") and input_direction != Vector2.ZERO:
		current_speed *= sprint_multiplier
		animated_sprite.speed_scale = sprint_multiplier
		footstep_pitch_scale *= sprint_footstep_pitch_multiplier
	else:
		animated_sprite.speed_scale = 1.0
	
	# Set the player's velocity based on input and speed.
	velocity = input_direction.normalized() * current_speed
	
	# --- NEW AND CORRECTED PUSHING LOGIC ---
	# We simulate the movement for this frame to see what we would hit.
	# The 'true' at the end of move_and_collide means this is a "test only" move.
	# The player will not actually move from this line of code.
	var was_pushing_this_frame: bool = false
	var collision = move_and_collide(velocity * delta, true)
	
	if collision:
		var collider = collision.get_collider()
		
		if collider.is_in_group("pushable") or collider.is_in_group("companion"):
			if collider.has_method("apply_push"):
				if collider.is_in_group("pushable"):
					was_pushing_this_frame = true
					# Tell the AudioManager to play the looping sound
					AudioManager.play_looping_sfx(Constants.AUDIO.pushing, 0.0)
				collider.apply_push(velocity)

	# If we were pushing but are not anymore, stop the sound.
	if is_pushing and not was_pushing_this_frame:
		AudioManager.stop_looping_sfx(Constants.AUDIO.pushing)
	
	# Update the state for the next frame.
	is_pushing = was_pushing_this_frame

	# Now, perform the actual player movement.
	# This function handles sliding against walls and other bodies correctly.
	move_and_slide()
	
	# Update the animation based on the player's state.
	update_animation(input_direction)
	
	# --- Footstep sound logic ---
	if input_direction != Vector2.ZERO:
		# If moving, ensure footstep player is playing and update pitch.
		if not footstep_player.playing:
			footstep_player.play()
		footstep_player.pitch_scale = footstep_pitch_scale
	else:
		# If idle, stop the footstep player.
		if footstep_player.playing:
			footstep_player.stop()

func update_animation(direction: Vector2) -> void:
	var new_animation = animated_sprite.animation
	
	if direction != Vector2.ZERO:
		# Player is moving, so update last_direction
		last_direction = direction
		
		# --- Check for Diagonal Movement First ---
		if direction.x != 0 and direction.y != 0:
			if direction.y < 0: # Moving Up
				if direction.x < 0:
					new_animation = "run dig back left"
				else:
					new_animation = "run dig back right"
			else: # Moving Down
				if direction.x < 0:
					new_animation = "run dig front left"
				else:
					new_animation = "run dig front right"
		# --- Else, Check for Cardinal Movement ---
		elif direction.y < 0:
			new_animation = "run back"
		elif direction.y > 0:
			new_animation = "run front"
		elif direction.x < 0:
			new_animation = "run left"
		elif direction.x > 0:
			new_animation = "run right"
	else:
		# --- Player is Idle ---
		# Use the last direction to set the idle animation
		var is_diagonal = last_direction.x != 0 and last_direction.y != 0
		
		# --- Check for Diagonal Idle State First ---
		if is_diagonal:
			if last_direction.y < 0: # Was moving Up
				if last_direction.x < 0:
					new_animation = "idle dig back left"
				else:
					new_animation = "idle dig back right"
			else: # Was moving Down
				if last_direction.x < 0:
					new_animation = "idle dig front left"
				else:
					new_animation = "idle dig front right"
		# --- Else, Check for Cardinal Idle State ---
		elif last_direction.y < 0:
			new_animation = "idle back"
		elif last_direction.y > 0:
			new_animation = "idle front"
		elif last_direction.x < 0:
			new_animation = "idle left"
		elif last_direction.x > 0:
			new_animation = "idle right"
			
	# Only change the animation if the new state is different from the current one
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)
