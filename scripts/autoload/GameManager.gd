extends Node

# Emitted when the game transitions between states
signal game_state_changed(new_state)

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
    set_state(GameState.LOADING)
    current_level_index = level_index
    
    # Use the LevelManager to get the path
    var level_path = LevelManager.get_level_path(level_index)
    
    if not level_path.is_empty() and ResourceLoader.exists(level_path):
        print("GameManager: Loading level %d: %s" % [level_index, level_path])
        # Change the scene. The new level will set the state to PLAYING.
        get_tree().change_scene_to_file(level_path)
    else:
        push_error("GameManager: Failed to load level %d. Scene not found at: %s" % [level_index, level_path])
        go_to_main_menu()


func reload_current_level() -> void:
    print("GameManager: Reloading current level...")
    load_level(current_level_index)


func level_was_completed() -> void:
    # This function is called by the level itself when the objective is met.
    # It simply changes the state, which will trigger the LevelComplete UI to show.
    set_state(GameState.LEVEL_COMPLETE)
    print("GameManager: Level %d complete." % current_level_index)


func load_next_level_from_ui() -> void:
    # This function is called by the 'Next Level' button on the LevelComplete UI.
    var next_level_index = current_level_index + 1
    
    if LevelManager.get_level_path(next_level_index).is_empty():
        # This was the last level
        set_state(GameState.GAME_COMPLETE)
        print("GameManager: All levels complete! Returning to menu.")
        go_to_main_menu() # Or a "You Win!" screen
    else:
        print("GameManager: Loading next level...")
        load_level(next_level_index)


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


func resume_game():
    if current_state != GameState.PAUSED:
        return
    set_state(GameState.PLAYING)
    get_tree().paused = false
    print("GameManager: Game Resumed.")


func go_to_main_menu():
    print("GameManager: Returning to Main Menu.")
    get_tree().paused = false
    set_state(GameState.MENU)
    # We will create the main menu scene later
    # get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
    print("GameManager: Main Menu scene not created yet.")
