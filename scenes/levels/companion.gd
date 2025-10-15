extends CharacterBody2D

## --- Companion AI Script ---

#== EXPORT VARIABLES (Adjust in the Inspector) ==#

# The player character the companion should follow.
@export var player_to_follow: Node2D

# Movement Tuning
@export var speed: float = 80.0
@export var acceleration: float = 0.1
@export var deceleration: float = 0.25

# The distance the companion tries to maintain from the player.
@export var follow_distance: float = 100.0
# The "dead zone" where the companion will stop moving.
@export var stop_distance: float = 80.0

# How far away the player must be before the companion teleports.
@export var respawn_distance: float = 1000.0

# How long the companion can be stuck before it teleports.
@export var stuck_time_threshold: float = 3.0


#== NODE REFERENCES ==#
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


#== PRIVATE VARIABLES ==#
var last_direction = Vector2(0, 1) # Default to facing down (front)

# For the stuck check
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO

# --- NEW: Variable to store the push velocity from the player ---
var push_velocity: Vector2 = Vector2.ZERO


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

	# --- Movement Logic ---
	var direction_to_player = current_position.direction_to(player_position)
	
	if distance_to_player > follow_distance:
		# Move towards the player with acceleration
		velocity = velocity.lerp(direction_to_player * speed, acceleration)
	elif distance_to_player < stop_distance:
		# Slow down and stop when close to the player
		velocity = velocity.lerp(Vector2.ZERO, deceleration)
	else:
		# Maintain a sweet spot by gently decelerating
		velocity = velocity.lerp(Vector2.ZERO, deceleration)
	
	# --- MODIFIED: Add the push velocity to the final velocity ---
	velocity += push_velocity

	move_and_slide()
	
	# --- NEW: Decay the push velocity so it stops when not being pushed ---
	push_velocity = push_velocity.lerp(Vector2.ZERO, 0.25)

	update_animation(velocity.normalized() if velocity.length() > 1.0 else Vector2.ZERO)

# --- NEW: Function for the player to call to push the companion ---
func apply_push(force: Vector2):
	push_velocity = force

func update_animation(direction: Vector2) -> void:
	var new_animation = animated_sprite.animation

	if direction != Vector2.ZERO:
		# Companion is moving, so update the last known direction
		last_direction = direction
		
		# Check for vertical movement first, as it's more visually distinct
		if direction.y < -0.5: # Moving Up (Back)
			if direction.x < -0.5:
				new_animation = "walk back left" # Animation exists
			elif direction.x > 0.5:
				new_animation = "walk back right" # Animation exists
			else:
				new_animation = "walk back" # Animation exists
		elif direction.y > 0.5: # Moving Down (Front)
			# Fallback: Since "walk front left" and "walk front right" are missing,
			# we default to "walk front" for any forward movement.
			#new_animation = "walk front" # Animation exists
			if direction.x < -0.5:
				new_animation = "walk front"
			elif direction.x > 0.5:
				new_animation = "walk front"
			else:
				new_animation = "walk front"
		
		# Check for pure horizontal movement if not moving vertically
		elif direction.x < -0.5:
			# Fallback: No "walk left", so use "walk back left" as a substitute.
			new_animation = "walk back left"
		elif direction.x > 0.5:
			# Fallback: No "walk right", so use "walk back right" as a substitute.
			new_animation = "walk back right"
	else:
		# --- Companion is Idle ---
		# Use last direction to set the correct idle animation.
		# Since there are no diagonal idle animations, we prioritize
		# the dominant direction (vertical or horizontal).
		if abs(last_direction.y) > abs(last_direction.x):
			# More vertical than horizontal
			if last_direction.y < 0:
				new_animation = "idle back"
			else:
				new_animation = "idle front"
		else:
			# More horizontal than vertical
			if last_direction.x < 0:
				new_animation = "idle left"
			else:
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
