# InputManager.gd (Autoload)
# This script handles global input actions.
extends Node

signal pause_toggled

func _ready():
	# We want this node to run all the time, even when the game is paused,
	# so we can catch the "unpause" action.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent):
	# This manager now only handles global actions, like pausing.
	# Player movement is handled in the Player.gd script.
	if event.is_action_pressed("pause_toggle"):
		emit_signal("pause_toggled")
