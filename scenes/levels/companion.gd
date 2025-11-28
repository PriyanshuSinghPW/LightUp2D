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

@onready var DialogueBackground: TextureRect = $CanvasLayer/Dialogue/DialogueBackground
@onready var DialogueLabel: RichTextLabel = $CanvasLayer/Dialogue/DialogueBackground/DialogueLabel
@onready var CharacterImage: TextureRect = $CanvasLayer/Dialogue/CharacterImage

var is_feedback_playing: bool = false


#== PRIVATE VARIABLES ==#
var last_direction = Vector2(0, 1) # Default to facing down (front)

# For the stuck check
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO

# State variable to track stand by mode
var is_in_standby_mode: bool = false

# Variable to store the push velocity from the player
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
    DialogueBackground.visible = false
    CharacterImage.visible = false
    
        # NEW: Connect to the global signal from the InputManager.
    InputManager.toggle_companion_standby.connect(toggle_standby)


func _physics_process(delta: float) -> void:
    if not is_instance_valid(player_to_follow):
        return # Stop processing if the player is not valid.
    
    # MODIFIED: The input check now calls our new function.
    if Input.is_action_just_pressed("toggle_standby"):
        toggle_standby()

    var current_position = global_position
    var player_position = player_to_follow.global_position
    var distance_to_player = current_position.distance_to(player_position)

    # --- MODIFIED: Only check for respawning and being stuck if NOT in standby mode ---
    if not is_in_standby_mode:
        # Fallback Logic: Handle getting stuck or too far away
        if distance_to_player > respawn_distance:
            teleport_near_player()
            return # Skip the rest of the logic for this frame.

        check_if_stuck(delta)
    
    # Movement Logic is now conditional on stand by mode
    if not is_in_standby_mode:
        # Normal following logic
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
    else:
        # In stand by mode, the companion actively tries to stop.
        velocity = velocity.lerp(Vector2.ZERO, deceleration)

    # Add the push velocity to the final velocity (works in both modes)
    velocity += push_velocity

    move_and_slide()
    
    # Decay the push velocity so it stops when not being pushed
    push_velocity = push_velocity.lerp(Vector2.ZERO, 0.25)

    update_animation(velocity.normalized() if velocity.length() > 1.0 else Vector2.ZERO)

# This can be called from anywhere (keyboard input, mobile button, etc.).
func toggle_standby() -> void:
    # If feedback is already playing, ignore the new request to prevent spam.
    if is_feedback_playing:
        return
        
    is_feedback_playing = true
    is_in_standby_mode = not is_in_standby_mode
    
    # Set the correct text based on the new mode.
    if is_in_standby_mode:
        DialogueLabel.text = "Roshni, Stand By"
    else:
        DialogueLabel.text = "Roshni, Follow Me"
        
    # Show the UI elements.
    DialogueBackground.visible = true
    CharacterImage.visible = true
    
    # Wait for 0.5 seconds. The 'await' keyword pauses the function here.
    await get_tree().create_timer(0.6).timeout
    
    # After the timer finishes, hide the UI elements again.
    DialogueBackground.visible = false
    CharacterImage.visible = false
    
    # Unlock the function so it can be called again.
    is_feedback_playing = false

func apply_push(force: Vector2):
    push_velocity = force


func update_animation(direction: Vector2) -> void:
    var new_animation = animated_sprite.animation

    if direction != Vector2.ZERO:
        last_direction = direction
        
        if direction.y < -0.5:
            if direction.x < -0.5:
                new_animation = "walk back left"
            elif direction.x > 0.5:
                new_animation = "walk back right"
            else:
                new_animation = "walk back"
        elif direction.y > 0.5:
            if direction.x < -0.5:
                new_animation = "walk front"
            elif direction.x > 0.5:
                new_animation = "walk front"
            else:
                new_animation = "walk front"
        
        elif direction.x < -0.5:
            new_animation = "walk back left"
        elif direction.x > 0.5:
            new_animation = "walk back right"
    else:
        # Companion is Idle
        if abs(last_direction.y) > abs(last_direction.x):
            if last_direction.y < 0:
                new_animation = "idle back"
            else:
                new_animation = "idle front"
        else:
            if last_direction.x < 0:
                new_animation = "idle left"
            else:
                new_animation = "idle right"

    if animated_sprite.animation != new_animation:
        animated_sprite.play(new_animation)


func check_if_stuck(delta: float) -> void:
    if velocity.length() > 0 and global_position.distance_to(last_position) < 1.0:
        stuck_timer += delta
    else:
        stuck_timer = 0

    if stuck_timer > stuck_time_threshold:
        teleport_near_player()
        stuck_timer = 0

    last_position = global_position


func teleport_near_player() -> void:
    var offset = (player_to_follow.global_position - global_position).normalized() * (follow_distance - 20)
    global_position = player_to_follow.global_position - offset
    velocity = Vector2.ZERO
