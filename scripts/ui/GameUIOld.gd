extends Control

func _ready() -> void:
	# Hide the pause menu by default when a level loads.
	hide()
	# Connect to the GameManager's signal to know when the state changes.
	GameManager.game_state_changed.connect(_on_game_state_changed)

# This function is called whenever the GameManager's state changes.
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# Show the pause menu only when the game is paused.
			show()
		_:
			# Hide it in all other states (PLAYING, MENU, etc.).
			hide()

# This function must be connected to your "Resume" button's 'pressed' signal
# in the PauseMenu.tscn scene editor.
func _on_resume_button_pressed() -> void:
	GameManager.resume_game()

# This function can be connected to a "Main Menu" or "Quit to Menu" button.
func _on_main_menu_button_pressed() -> void:
	GameManager.go_to_main_menu()


func _on_button_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_pressed() -> void:
	pass # Replace with function body.


func _on_resume_pressed() -> void:
	pass # Replace with function body.
