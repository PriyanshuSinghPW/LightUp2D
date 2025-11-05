# InputManager.gd (Autoload)
# This script handles global input actions.
extends Node

# --- Existing Signals ---
signal pause_toggled
signal sprint_button_pressed
signal sprint_button_released

# --- NEW SIGNALS for Interaction ---

# Emitted by in-game objects when the player enters their interaction range.
signal show_interaction_button

# Emitted by in-game objects when the player leaves their interaction range.
signal hide_interaction_button

# Emitted by the UI when the mobile interaction button is physically pressed.
signal interaction_button_pressed

signal toggle_companion_standby


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("pause_toggle"):
		emit_signal("pause_toggled")
