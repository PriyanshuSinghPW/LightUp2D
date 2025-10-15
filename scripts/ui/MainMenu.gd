extends Control

# Assuming your play button is named "PlayButton" in the MainMenu.tscn scene.
@onready var play_button: TextureButton = $StartingScreen/ButtonsContainer/PlayButton

func _ready():
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
	else:
		push_error("MainMenu.gd: Could not find a node named 'PlayButton'. Please check the node name and path in MainMenu.tscn.")

func _on_play_button_pressed():
	# Start the game logic (if GameManager is used for setup)
	GameManager.start_new_game()
	# Change the scene to Level1
	#get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")
