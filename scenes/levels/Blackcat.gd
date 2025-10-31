extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D # This Area2D should be a child of the cat

@export var base_speed = 150.0

var current_speed = 0.0
var direction = Vector2.ZERO
var rng = RandomNumberGenerator.new()

var ALLOWED_DIRECTIONS = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2(-1, -1).normalized(), # Up-Left
	Vector2(1, -1).normalized(),  # Up-Right
	Vector2(-1, 1).normalized(),  # Down-Left
	Vector2(1, 1).normalized()   # Down-Right
]

enum State {
	IDLE,
	RUNNING,
	JUMPING,
	SITTING,
	WALKING
}

var current_state = State.IDLE
# Timer to prevent the cat from getting stuck by reacting too quickly
var collision_cooldown_timer: Timer

func _ready():
	rng.randomize()
	
	# Connect the Area2D's signal. This triggers when it detects a wall.
	area_2d.body_entered.connect(_on_avoidance_area_entered)
	
	# This timer prevents the cat from changing direction multiple times in a split second
	collision_cooldown_timer = Timer.new()
	collision_cooldown_timer.wait_time = 0.25 # Cooldown of 0.25 seconds
	collision_cooldown_timer.one_shot = true
	add_child(collision_cooldown_timer)

	animated_sprite.animation_finished.connect(_on_animation_finished)

	randomize_direction()
	set_state(State.RUNNING)

func _physics_process(delta):
	if current_state == State.RUNNING or current_state == State.WALKING:
		velocity = direction * current_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

# --- INTELLIGENT AVOIDANCE LOGIC ---
# This function is called when the cat's Area2D detects an object.
func _on_avoidance_area_entered(body):
	# Do nothing if we are on cooldown or if the detected object is not a wall
	if not collision_cooldown_timer.is_stopped() or not body.is_in_group("Walls"):
		return

	# Start the cooldown timer to prevent getting stuck in a detection loop
	collision_cooldown_timer.start()

	# --- Smart Direction Finding ---
	# 1. Find the direction pointing from the cat TOWARDS the wall
	var direction_to_wall = (body.global_position - global_position).normalized()
	
	# 2. Find the best new direction that points AWAY from the wall
	var best_direction = direction
	var best_dot_product = 1.0 # Start with the worst possible score

	for new_dir in ALLOWED_DIRECTIONS:
		# A dot product of -1 means the new direction is directly away from the wall.
		# A dot product of 1 means it's directly towards the wall.
		# We want the direction with the smallest (most negative) dot product.
		var dot = new_dir.dot(direction_to_wall)
		if dot < best_dot_product:
			best_dot_product = dot
			best_direction = new_dir

	# 3. Set the new, safer direction
	direction = best_direction
	update_flip()
	
	# Randomly decide on an action after avoiding a wall
	var random_chance = rng.randf()
	if random_chance < 0.2:
		set_state(State.JUMPING)
	elif random_chance < 0.5:
		set_state(State.SITTING)

func randomize_direction():
	direction = ALLOWED_DIRECTIONS.pick_random()
	update_flip()

# --- FIXED: This function is now back to your original logic ---
func update_flip():
	if direction.x < 0:
		animated_sprite.flip_h = false
	elif direction.x > 0:
		animated_sprite.flip_h = true

func set_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state
	
	match new_state:
		State.RUNNING:
			current_speed = base_speed
		State.WALKING:
			current_speed = base_speed * 0.5
		State.IDLE, State.SITTING, State.JUMPING:
			current_speed = 0
			
	update_animation()

func update_animation():
	var anim_name = ""
	match current_state:
		State.IDLE: anim_name = "idle"
		State.RUNNING: anim_name = "running"
		State.JUMPING: anim_name = "jumping"
		State.SITTING: anim_name = "sitting"
		State.WALKING: anim_name = "walking"

	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_animation_finished():
	if animated_sprite.animation == "sitting":
		set_state(State.IDLE)
		# Using await is a cleaner way to handle timers in recent Godot versions
		await get_tree().create_timer(rng.randf_range(1.5, 4.0)).timeout
		set_state(State.RUNNING)
	
	if animated_sprite.animation == "jumping":
		set_state(State.RUNNING)
