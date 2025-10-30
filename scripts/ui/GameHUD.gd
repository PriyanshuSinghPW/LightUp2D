extends Control

# Make sure your pause button is named "PauseButton" in the GameHUD.tscn scene.
@onready var pause_button: Button = $PauseButton

func _ready() -> void:
	# The HUD should be hidden by default until a level starts.
	hide()
	# Connect to the GameManager's signal to know when the state changes.
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Connect the pause button to the GameManager's toggle function.
	if pause_button:
		pause_button.pressed.connect(GameManager.toggle_pause)
	else:
		push_error("GameHUD.gd: PauseButton node not found!")

# This function is called whenever the GameManager's state changes.
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PLAYING:
			# Show the HUD only when the game is actively being played.
			show()
		_:
			# Hide it in all other states (MENU, PAUSED, LOADING, etc.).
			hide()
