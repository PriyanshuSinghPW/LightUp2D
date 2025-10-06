extends CharacterBody2D

## --- Companion AI Script ---

#== EXPORT VARIABLES (Adjust in the Inspector) ==#

# The player character the companion should follow.
@export var player_to_follow: Node2D

# How fast the companion moves.
@export var speed: float = 80.0

# The distance the companion tries to maintain from the player.
@export var follow_distance: float = 100.0

# How far away the player must be before the companion teleports.
@export var respawn_distance: float = 1000.0

# How long the companion can be stuck before it teleports.
@export var stuck_time_threshold: float = 3.0


#== NODE REFERENCES ==#
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D


#== PRIVATE VARIABLES ==#
var last_direction = Vector2(0, 1) # Default to facing down (front)

# For the stuck check
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Ensure the player node is assigned before starting.
	if not is_instance_valid(player_to_follow):
		print("ERROR: Player node not assigned to companion!")
		set_physics_process(false) # Disable the AI if no player is set.
		return
		
	# Initialize the starting state.
	animated_sprite.play("idle front")
	last_position = global_position


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_to_follow):
		return # Stop processing if the player is not valid.

	var current_position = global_position
	var player_position = player_to_follow.global_position
	var distance_to_player = current_position.distance_to(player_position)

	# --- Fallback Logic: Handle getting stuck or too far away ---
	if distance_to_player > respawn_distance:
		teleport_near_player()
		return # Skip the rest of the logic for this frame.
	
	check_if_stuck(delta)

	# Set the target location for the navigation agent.
	navigation_agent.target_position = player_position

	# --- Movement Logic ---
	if distance_to_player > follow_distance:
		# If far from the player, get the next path point and move towards it.
		var next_path_position = navigation_agent.get_next_path_position()
		var move_direction = current_position.direction_to(next_path_position)
		
		velocity = move_direction * speed
		move_and_slide()
		update_animation(move_direction)
	else:
		# If close enough, stop moving.
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO) # Pass zero vector to trigger idle state.
		
	
func update_animation(direction: Vector2) -> void:
	var new_animation = animated_sprite.animation
	
	if direction != Vector2.ZERO:
		# Companion is moving, update last_direction
		last_direction = direction
		
		# --- Determine correct "walk" animation based on direction ---
		# Using dot products to find the most dominant direction.
		var forward_dot = direction.dot(Vector2.DOWN)
		var back_dot = direction.dot(Vector2.UP)
		var right_dot = direction.dot(Vector2.RIGHT)

		# Check diagonal directions first (e.g., "walk back left")
		if back_dot > 0.5 and right_dot < -0.5:
			new_animation = "walk back left"
		elif back_dot > 0.5 and right_dot > 0.5:
			new_animation = "walk back right"
		# Check cardinal directions
		elif back_dot > 0.7:
			new_animation = "walk back"
		elif forward_dot > 0.7:
			new_animation = "walk front"
		# (Note: You can add "walk front left/right" here if you have them)

	else:
		# --- Companion is Idle ---
		# Use last direction to set the correct idle animation.
		if last_direction.dot(Vector2.UP) > 0.7:
			new_animation = "idle back"
		elif last_direction.dot(Vector2.DOWN) > 0.7:
			new_animation = "idle front"
		elif last_direction.dot(Vector2.LEFT) > 0.7:
			new_animation = "idle left"
		elif last_direction.dot(Vector2.RIGHT) > 0.7:
			new_animation = "idle right"
			
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)


func check_if_stuck(delta: float) -> void:
	# If moving very slowly (or not at all) while trying to move...
	if velocity.length() > 0 and global_position.distance_to(last_position) < 1.0:
		stuck_timer += delta
	else:
		stuck_timer = 0 # Reset timer if moving normally.

	# If the timer exceeds the threshold, teleport.
	if stuck_timer > stuck_time_threshold:
		teleport_near_player()
		stuck_timer = 0 # Reset after teleporting.

	last_position = global_position


func teleport_near_player() -> void:
	# Find a safe position near the player and move the companion there.
	# This places it slightly behind the player.
	var offset = (player_to_follow.global_position - global_position).normalized() * (follow_distance - 20)
	global_position = player_to_follow.global_position - offset
	velocity = Vector2.ZERO # Stop movement immediately after teleport.
