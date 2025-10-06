# door.gd
extends AnimatedSprite2D

@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var flower: AnimatedSprite2D = $Flower


func _ready():
	# Set default animations
	self.play("doorclosed")
	flower.play("flower closed")
	
	# Initially disable the point light
	point_light_2d.enabled = false
	
	# Connect the animation finished signal to a callback function
	self.animation_finished.connect(_on_animation_finished)


func _on_light_target_unlocked():
	"""Handles the 'unlocked' signal from the LightTarget."""
	flower.play("flower opening")
	
	# --- START OF CORRECTION ---
	# Calculate the duration of the "flower opening" animation
	var anim_name = "flower opening"
	var frame_count = flower.sprite_frames.get_frame_count(anim_name)
	var anim_speed = flower.sprite_frames.get_animation_speed(anim_name)
	
	# Default to 0 duration if speed is 0 to avoid division by zero error
	var duration = 0.0
	if anim_speed > 0:
		duration = frame_count / anim_speed
	# --- END OF CORRECTION ---

	# Animate the PointLight2D over the calculated duration
	point_light_2d.enabled = true
	var tween = create_tween().set_parallel(true)
	tween.tween_property(point_light_2d, "texture_scale", 0.8, duration)
	tween.tween_property(point_light_2d, "energy", 1.0, duration)


func _on_light_target_player_entered():
	"""Handles the 'player_entered' signal from the LightTarget."""
	flower.visible = false
	self.play("LevelPassed")


func _on_animation_finished():
	"""Called when any animation on this AnimatedSprite2D finishes."""
	if self.animation == "LevelPassed":
		print("Door: LevelPassed animation finished. Loading next level.")
		# Make sure GameManager is an autoloaded script with a load_next_level function
		# For example: GameManager.load_next_level()
		# As a placeholder, we can use get_tree().change_scene_to_file()
		# Replace "res://path_to_your_next_level.tscn" with the actual path.
		GameManager.load_next_level()
