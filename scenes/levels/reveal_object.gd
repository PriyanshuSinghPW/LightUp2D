extends Area2D

@onready var Cloth: Sprite2D = $HidingCloth
@onready var HidingCollision: CollisionShape2D = $HidingCollision
@onready var Text: Label = $Text

@export var player: CharacterBody2D
@export var dialogue_manager: Node

var was_text_visible: bool = false

func _ready() -> void:
	Text.visible = false
	# This connects the MOBILE button signal to our interaction function.
	InputManager.interaction_button_pressed.connect(_on_interact)

func _process(delta: float) -> void:
	if not player:
		return

	var is_player_in_area = get_overlapping_bodies().has(player)
	var is_hiding_spot_active = not HidingCollision.disabled

	var should_be_visible = is_player_in_area and is_hiding_spot_active
	Text.visible = should_be_visible

	# Logic to show/hide the mobile button
	if Text.visible and not was_text_visible:
		InputManager.emit_signal("show_interaction_button")
	elif not Text.visible and was_text_visible:
		InputManager.emit_signal("hide_interaction_button")
	
	was_text_visible = Text.visible

	# --- NEW: Add the keyboard input check back in ---
	# This checks for the KEYBOARD "Interaction" press.
	if Input.is_action_just_pressed("Interaction"):
		# It calls the exact same function as the mobile button.
		_on_interact()


# This function is now the central point for interaction logic,
# called by BOTH the mobile button signal and the keyboard input check.
func _on_interact() -> void:
	# Check if the text is visible to ensure we can interact.
	if Text.visible:
		Cloth.visible = false
		HidingCollision.disabled = true
		Text.visible = false # This will trigger the hide signal in the next _process frame
		AudioManager.play_sfx(Constants.AUDIO.cloth_drop, 1)

		if dialogue_manager:
			dialogue_manager.trigger_cloth_removed()
