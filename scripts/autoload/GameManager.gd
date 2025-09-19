# GameManager.gd (Autoload) - Light Puzzle Version
extends Node

signal game_started
signal game_paused
signal game_resumed

enum GameState { MENU, PLAYING, PAUSED }
var current_state = GameState.MENU

# Reference to the player node, can be set by the level
var player: Node = null

const MAIN_MENU_SCENE = "res://scenes/main/Main.tscn"
# We'll assume a Level1 exists for now. We will create this later.
const FIRST_LEVEL_SCENE = "res://scenes/levels/Level1.tscn" 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect to the input manager's pause signal
	InputManager.pause_toggled.connect(toggle_pause)
	print("GameManager: Ready.")

func start_game():
	print("GameManager: start_game() called. Loading first level.")
	# Note: This scene doesn't exist yet. We will create it in a later step.
	get_tree().change_scene_to_file(FIRST_LEVEL_SCENE)
	set_game_state(GameState.PLAYING)

func set_game_state(new_state):
	current_state = new_state
	if new_state == GameState.PLAYING:
		get_tree().paused = false
		emit_signal("game_started")
		print("GameManager: State set to PLAYING.")

func pause_game():
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.PAUSED
	get_tree().paused = true
	emit_signal("game_paused")
	print("GameManager: Game Paused.")

func resume_game():
	if current_state != GameState.PAUSED:
		return
	current_state = GameState.PLAYING
	get_tree().paused = false
	emit_signal("game_resumed")
	print("GameManager: Game Resumed.")

func toggle_pause():
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

func go_to_main_menu():
	print("GameManager: Returning to Main Menu.")
	get_tree().paused = false
	current_state = GameState.MENU
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


