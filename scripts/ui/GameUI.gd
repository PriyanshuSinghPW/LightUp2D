extends CanvasLayer

# Game UI elements
@onready var GameUI: Control = $GameUI
@onready var PauseButton: TextureButton = $GameUI/PauseButton

# Pause Menu objects
@onready var PauseMenu: Control = $PauseMenu
@onready var ResumeButton: TextureButton = $PauseMenu/background/BoxContainer/ResumeButton
@onready var RestartButton: TextureButton = $PauseMenu/background/BoxContainer/RestartButton
@onready var ExitButton: TextureButton = $PauseMenu/background/BoxContainer/ExitButton
@onready var PauseButtonsContainer: TextureRect = $PauseMenu/background
@onready var BlurBg: ColorRect = $PauseMenu/BlurBg
@onready var Vignette: ColorRect = $PauseMenu/Vignette
@onready var SpookyImage: TextureRect = $PauseMenu/Spooky
@onready var GameOver: Control = $GameOver
@onready var GameOverFade: ColorRect = $"GameOver/FadeEffect"
@onready var GameOverGraphic: TextureRect = $GameOver/GameOverGraphic

@onready var SprintButton: TextureButton = $GameUI/SprintButton
@onready var CompanionButton: TextureButton = $GameUI/CompanionButton
@onready var InteractionButton: TextureButton = $GameUI/InteractionButton

# NEW: A counter to track how many objects are requesting the button to be shown.
var _interaction_request_counter: int = 0

# Variables to store the original positions.
var _buttons_original_pos: Vector2
var _spooky_original_pos: Vector2

# State lock to prevent animations from interrupting each other.
var _is_animating: bool = false


# The function MUST be 'async' to use 'await'.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Wait for a single frame to ensure all node positions and sizes are correct.
	await get_tree().create_timer(0.01).timeout

	# Now it's safe to store the original positions.
	_buttons_original_pos = PauseButtonsContainer.position
	_spooky_original_pos = SpookyImage.position
	
	PauseMenu.hide()
	BlurBg.modulate.a = 0.0
	Vignette.modulate.a = 0.0

	# Initialize GameOver elements to be hidden and fully transparent
	GameOver.hide()
	GameOverFade.modulate.a = 0.0
	GameOverGraphic.modulate.a = 0.0

	# Connect signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.game_over_triggered.connect(_on_game_over_triggered) # Connect the new game over signal
	ResumeButton.pressed.connect(_on_resume_pressed)
	ExitButton.pressed.connect(_on_main_menu_pressed)
	PauseButton.pressed.connect(_on_pause_button_pressed)
	RestartButton.pressed.connect(_on_restart_pressed)
	
		# Connect the sprint button's down and up signals to our new functions.
	SprintButton.button_down.connect(_on_sprint_button_down)
	SprintButton.button_up.connect(_on_sprint_button_up)
	
		# --- NEW: Connect to interaction signals ---
	InputManager.show_interaction_button.connect(_on_show_interaction_button)
	InputManager.hide_interaction_button.connect(_on_hide_interaction_button)
	InteractionButton.pressed.connect(_on_interaction_button_pressed)
	
	CompanionButton.pressed.connect(_on_companion_button_pressed)

	# Start with the button hidden
	InteractionButton.hide()

# --- NEW: Function to handle the companion button press ---
func _on_companion_button_pressed() -> void:
	# Broadcast the global signal that the companion is listening for.
	InputManager.emit_signal("toggle_companion_standby")

# --- THIS IS THE CORRECTED FUNCTION ---
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# When the game pauses, hide the standard UI and show the animated pause menu.
			GameUI.hide()
			_show_pause_menu_animated()
			
		GameManager.GameState.PLAYING:
			# When the game is playing (e.g., resuming from pause), show the standard UI
			# and hide the animated pause menu.
			GameUI.show()
			_hide_pause_menu_animated()
			
		# By removing the default '_:' case, this function will now correctly do nothing
		# for the GAME_OVER, MENU, or LOADING states. This prevents it from setting
		# the _is_animating flag and blocking our game over function.


func _show_pause_menu_animated() -> void:
	if _is_animating: return
	_is_animating = true

	PauseMenu.show()
	
	# Reset starting positions and opacity to guarantee the animation runs correctly every time.
	PauseButtonsContainer.position = _buttons_original_pos + Vector2(0, PauseButtonsContainer.size.y)
	SpookyImage.position = _spooky_original_pos - Vector2(SpookyImage.size.x, 0)
	BlurBg.modulate.a = 0.0
	Vignette.modulate.a = 0.0

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(PauseButtonsContainer, "position", _buttons_original_pos, 0.5)
	tween.tween_property(SpookyImage, "position", _spooky_original_pos, 0.5)
	tween.tween_property(BlurBg, "modulate:a", 1.0, 0.5)
	tween.tween_property(Vignette, "modulate:a", 1.0, 0.5)
	
	await tween.finished
	_is_animating = false

func _hide_pause_menu_animated() -> void:
	if _is_animating: return
	_is_animating = true

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.tween_property(PauseButtonsContainer, "position", _buttons_original_pos + Vector2(0, PauseButtonsContainer.size.y), 0.3)
	tween.tween_property(SpookyImage, "position", _spooky_original_pos - Vector2(SpookyImage.size.x, 0), 0.3)
	tween.tween_property(BlurBg, "modulate:a", 0.0, 0.3)
	tween.tween_property(Vignette, "modulate:a", 0.0, 0.3)

	await tween.finished
	PauseMenu.hide()
	_is_animating = false

func _on_pause_button_pressed() -> void:
	print("PauseButton Pressed")
	if _is_animating: return
	GameManager.pause_game()

func _on_resume_pressed() -> void:
	if _is_animating: return
	GameManager.resume_game()
	
func _on_restart_pressed() -> void:
	if _is_animating: return
	GameManager.reload_current_level()

func _on_main_menu_pressed() -> void:
	if _is_animating: return
	GameManager.go_to_main_menu()

# New function for Game Over animation
func _on_game_over_triggered() -> void:
	if _is_animating: return
	_is_animating = true

	print("Game Over UI Triggered!")

	# Hide GameUI and PauseMenu if they are visible
	GameUI.hide()
	PauseMenu.hide()

	# Show the GameOver control node
	GameOver.show()

	# Ensure starting opacities are 0 for the animation
	GameOverFade.modulate.a = 0.0
	GameOverGraphic.modulate.a = 0.0

	var tween = create_tween()
	
	# Animate GameOverFade opacity to 1 (black screen)
	tween.tween_property(GameOverFade, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	await tween.finished

	# Small delay before showing the graphic
	await get_tree().create_timer(0.5).timeout

	var graphic_tween = create_tween()
	# Animate GameOverGraphic opacity to 1
	graphic_tween.tween_property(GameOverGraphic, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await graphic_tween.finished

	# Small delay before reloading
	await get_tree().create_timer(1.0).timeout

	_is_animating = false
	GameManager.reload_current_level()
	
	
# This function is called when the sprint button is pressed down.
func _on_sprint_button_down() -> void:
	# Broadcast the global "pressed" signal from our InputManager.
	InputManager.emit_signal("sprint_button_pressed")

# This function is called when the sprint button is released.
func _on_sprint_button_up() -> void:
	# Broadcast the global "released" signal from our InputManager.
	InputManager.emit_signal("sprint_button_released")
	
	
func _on_show_interaction_button() -> void:
	_interaction_request_counter += 1
	if _interaction_request_counter > 0:
		InteractionButton.show()

func _on_hide_interaction_button() -> void:
	_interaction_request_counter = max(0, _interaction_request_counter - 1)
	if _interaction_request_counter == 0:
		InteractionButton.hide()

# Called when the actual on-screen button is pressed by the player
func _on_interaction_button_pressed() -> void:
	# Broadcast the global signal that all interactable objects are listening for.
	InputManager.emit_signal("interaction_button_pressed")
