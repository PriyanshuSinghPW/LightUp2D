extends Node

# Assuming your play button is named "PlayButton" in the MainMenu.tscn scene.
# If it has a different name, you'll need to update the path.
@onready var play_button: Button = $"/root/MainMenu/PlayButton"

func _ready():
	# Check if the play button exists
	if play_button:
		# Connect the button's "pressed" signal to a function in this script.
		play_button.pressed.connect(_on_play_button_pressed)
	else:
		push_error("MainMenu.gd: Could not find a node named 'PlayButton'. Please check the node name and path in MainMenu.tscn.")

func _on_play_button_pressed():
	# When the button is pressed, tell the GameManager to start the game.
	GameManager.start_game()
