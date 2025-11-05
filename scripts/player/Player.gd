extends CharacterBody2D

# ... (all your other variables are the same) ...
var speed = Constants.PLAYER_DEFAULTS.speed
@export var sprint_multiplier: float = 1.75
@export var base_footstep_pitch: float = 1.0
@export var sprint_footstep_pitch_multiplier: float = 1.2
var last_direction = Vector2(0, 1)
var is_pushing: bool = false
var joystick_direction := Vector2.ZERO

# NEW: This variable will track the state of the mobile sprint button.
var mobile_sprint_pressed: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var footstep_player: AudioStreamPlayer2D = $FootstepPlayer

func _ready() -> void:
	animated_sprite.play("idle front")
	
	if camera:
		CameraController.configure(camera)
	
	footstep_player.pitch_scale = base_footstep_pitch
	
	# NEW: Connect to the global event bus to "listen" for the signals.
	InputManager.sprint_button_pressed.connect(_on_mobile_sprint_pressed)
	InputManager.sprint_button_released.connect(_on_mobile_sprint_released)

func _physics_process(delta: float) -> void:
	var input_direction: Vector2
	if joystick_direction != Vector2.ZERO:
		input_direction = joystick_direction
	else:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var current_speed = speed
	var footstep_pitch_scale = base_footstep_pitch
	
	# MODIFIED: Check both the keyboard/gamepad "sprint" action and our new variable.
	if (Input.is_action_pressed("sprint") or mobile_sprint_pressed) and input_direction != Vector2.ZERO:
		current_speed *= sprint_multiplier
		animated_sprite.speed_scale = sprint_multiplier
		footstep_pitch_scale *= sprint_footstep_pitch_multiplier
	else:
		animated_sprite.speed_scale = 1.0
	
	# ... (the rest of your physics_process and update_animation code remains exactly the same) ...
	velocity = input_direction.normalized() * current_speed
	var was_pushing_this_frame: bool = false
	var collision = move_and_collide(velocity * delta, true)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("pushable") or collider.is_in_group("companion"):
			if collider.has_method("apply_push"):
				if collider.is_in_group("pushable"):
					was_pushing_this_frame = true
					AudioManager.play_looping_sfx(Constants.AUDIO.pushing, 0.0)
				collider.apply_push(velocity)
	if is_pushing and not was_pushing_this_frame:
		AudioManager.stop_looping_sfx(Constants.AUDIO.pushing)
	is_pushing = was_pushing_this_frame
	move_and_slide()
	update_animation(input_direction)
	if input_direction != Vector2.ZERO:
		if not footstep_player.playing:
			footstep_player.play()
		footstep_player.pitch_scale = footstep_pitch_scale
	else:
		if footstep_player.playing:
			footstep_player.stop()

# --- (your update_animation function is unchanged) ---
func update_animation(direction: Vector2) -> void:
	# ... same code as before ...
	var new_animation = animated_sprite.animation
	var DIAGONAL_THRESHOLD = 0.4
	if direction != Vector2.ZERO:
		last_direction = direction
		var norm_dir = direction.normalized()
		var is_diagonal = abs(norm_dir.x) > DIAGONAL_THRESHOLD and abs(norm_dir.y) > DIAGONAL_THRESHOLD
		if is_diagonal:
			if norm_dir.y < 0:
				new_animation = "run dig back left" if norm_dir.x < 0 else "run dig back right"
			else:
				new_animation = "run dig front left" if norm_dir.x < 0 else "run dig front right"
		else:
			if abs(norm_dir.x) > abs(norm_dir.y):
				new_animation = "run left" if norm_dir.x < 0 else "run right"
			else:
				new_animation = "run back" if norm_dir.y < 0 else "run front"
	else:
		var norm_last_dir = last_direction.normalized()
		var is_last_dir_diagonal = abs(norm_last_dir.x) > DIAGONAL_THRESHOLD and abs(norm_last_dir.y) > DIAGONAL_THRESHOLD
		if is_last_dir_diagonal:
			if norm_last_dir.y < 0:
				new_animation = "idle dig back left" if norm_last_dir.x < 0 else "idle dig back right"
			else:
				new_animation = "idle dig front left" if norm_last_dir.x < 0 else "idle dig front right"
		else:
			if abs(norm_last_dir.x) > abs(norm_last_dir.y):
				new_animation = "idle left" if norm_last_dir.x < 0 else "idle right"
			else:
				new_animation = "idle back" if norm_last_dir.y < 0 else "idle front"
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)


# NEW: These functions are now called by the global signals.
func _on_mobile_sprint_pressed():
	mobile_sprint_pressed = true

func _on_mobile_sprint_released():
	mobile_sprint_pressed = false
