extends Control

# Exported variable lets you choose the AnimationPlayer node in the editor
@export var animation_player: AnimationPlayer
@export var animation_name: String = "1st_cutscene"

func _ready():
	# Ensure AnimationPlayer is assigned
	if animation_player == null:
		# Try to find it automatically (if it's a child node)
		animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

	if animation_player:
		play_animation(animation_name)
	else:
		push_warning("No AnimationPlayer found! Please assign one in the inspector.")

func play_animation(name: String):
	if animation_player and animation_player.has_animation(name):
		animation_player.play(name)
	else:
		push_warning("Animation '%s' not found in AnimationPlayer." % name)
