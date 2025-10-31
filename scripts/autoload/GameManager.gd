extends Node

# Emitted when the game transitions between states
signal game_state_changed(new_state)
# Emitted specifically when the game over sequence should begin
signal game_over_triggered

# Defines the possible states for the game
enum GameState {
	MENU,
	LOADING,
	PLAYING,
	PAUSED,
	LEVEL_COMPLETE,
	GAME_COMPLETE,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var current_level_index: int = 1

func _ready() -> void:
	# This node will persist across scene changes and run even when paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect to the input manager's pause signal if it exists
	if InputManager.has_signal("pause_toggled"):
		InputManager.pause_toggled.connect(toggle_pause)
	print("GameManager: Ready.")


func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	emit_signal("game_state_changed", current_state)
	print("GameManager: State changed to: ", GameState.keys()[current_state])


func start_new_game() -> void:
	print("GameManager: Starting new game...")
	current_level_index = 1
	load_level(current_level_index)


func load_level(level_index: int) -> void:
	# --- FIX START ---
	# Ensure the engine is unpaused when loading a level.
	# This fixes the issue where restarting from the pause menu leaves the new game paused.
	if get_tree().paused:
		get_tree().paused = false
	# --- FIX END ---
	set_state(GameState.LOADING)
	current_level_index = level_index
	
	var level_path = LevelManager.get_level_path(level_index)
	
	# --- MODIFICATION START ---
	# Get both the BGM path and its specific volume from the LevelManager.
	var bgm_path = LevelManager.get_level_bgm(level_index)
	var bgm_volume = LevelManager.get_level_bgm_volume(level_index) # Get the volume here
	
	if not bgm_path.is_empty():
		# Play the music using the volume we just retrieved.
		# A timer is used here to ensure any previous music has time to stop/fade out
		# during the scene transition, preventing audio conflicts.
		get_tree().create_timer(1.0).timeout.connect(
			func():
				# Use bgm_volume instead of a hardcoded value.
				AudioManager.play_music(bgm_path, 0.5, true, bgm_volume)
		)
	else:
		# If no BGM is defined for the level, just stop any currently playing music.
		AudioManager.stop_music(0.5)
	# --- MODIFICATION END ---
	
	if not level_path.is_empty() and ResourceLoader.exists(level_path):
		print("GameManager: Loading level %d: %s" % [level_index, level_path])
		TransitionManager.transition_to_scene(level_path)
	else:
		push_error("GameManager: Failed to load level %d. Scene not found at: %s" % [level_index, level_path])
		go_to_main_menu()


func reload_current_level() -> void:
	print("GameManager: Reloading current level...")
	load_level(current_level_index)


func level_was_completed() -> void:
	set_state(GameState.LEVEL_COMPLETE)
	AudioManager.stop_music(1.0)
	print("GameManager: Level %d complete." % current_level_index)


func load_next_level() -> void:
	var next_level_index = current_level_index + 1
	
	if LevelManager.get_level_path(next_level_index).is_empty():
		set_state(GameState.GAME_COMPLETE)
		print("GameManager: All levels complete! Returning to menu.")
		go_to_main_menu()
	else:
		print("GameManager: Loading next level...")
		load_level(next_level_index)


func trigger_game_over() -> void:
	# Prevent triggering game over multiple times if already in that state
	if current_state == GameState.GAME_OVER:
		return
	
	set_state(GameState.GAME_OVER)
	# Emit the signal that the UI script is waiting for
	emit_signal("game_over_triggered")
	print("GameManager: GAME OVER triggered.")
	
	# --- FIX START: Pause the game to allow the UI animation to play ---
	get_tree().paused = true
	# --- FIX END ---


func toggle_pause():
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()


func pause_game():
	if current_state != GameState.PLAYING:
		return
	set_state(GameState.PAUSED)
	get_tree().paused = true
	print("GameManager: Game Paused.")


# --- FIX: THIS FUNCTION IS NOW ASYNC TO PREVENT THE RACE CONDITION ---
func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return
	
	# First, change the state. This will signal the UI to start its hiding animation.
	set_state(GameState.PLAYING)
	
	# Then, wait for an amount of time slightly longer than the UI's hide animation (0.3s).
	# This gives the animation time to complete BEFORE we unpause the game.
	await get_tree().create_timer(0.4).timeout
	
	# Now that the pause menu is hidden, we can safely unpause the game tree.
	get_tree().paused = false
	print("GameManager: Game Resumed.")


func go_to_main_menu():
	print("GameManager: Returning to Main Menu.")
	get_tree().paused = false
	set_state(GameState.MENU)
	TransitionManager.transition_to_scene("res://scenes/main/Main.tscn")
	print("GameManager: Main Menu scene transition initiated.")
