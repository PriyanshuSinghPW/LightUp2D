extends CharacterBody2D

# Player movement script for a top-down oblique view.

# We'll get the speed from our global constants file.
var speed = Constants.PLAYER_DEFAULTS.speed

# Keep track of the last movement direction to determine the correct idle state.
var last_direction = Vector2(0, 1) # Default to facing down (front)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Set the initial state to idle front.
	animated_sprite.play("idle front")

func _physics_process(delta: float) -> void:
	# Get the input direction
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Handle the movement
	velocity = input_direction.normalized() * speed
	move_and_slide()
	
	# Update animation based on state
	update_animation(input_direction)

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


func _on_light_target_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
