extends CharacterBody2D

# Player movement script for a top-down oblique view.

# We'll get the speed from our global constants file.
var speed = Constants.PLAYER_DEFAULTS.speed

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("player")

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/animation.
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
	
	move_and_slide()
	
	# Optional: Add animation handling here later.
	# update_animation(input_direction)

# Example for animation handling (we can implement this later)
# func update_animation(direction: Vector2) -> void:
# 	if not has_node("AnimatedSprite2D"):
# 		return
# 	
# 	var anim_sprite = get_node("AnimatedSprite2D")
# 	if direction.length() > 0:
# 		anim_sprite.play()
# 	else:
# 		anim_sprite.stop()
#
# 	# Update animation based on direction (e.g., "walk_up", "walk_down")
# 	if direction.y < 0:
# 		anim_sprite.animation = "walk_up"
# 	elif direction.y > 0:
# 		anim_sprite.animation = "walk_down"
# 	elif direction.x < 0:
# 		anim_sprite.animation = "walk_left"
# 	elif direction.x > 0:
# 		anim_sprite.animation = "walk_right"
