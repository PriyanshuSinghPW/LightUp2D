extends Area2D

@onready var Cloth: Sprite2D = $HidingCloth
@onready var HidingCollision: CollisionShape2D = $HidingCollision
@onready var Text: Label = $Text

@export var player: CharacterBody2D
@export var dialogue_manager: Node

# NEW: State variable to track if the text was visible last frame
var was_text_visible: bool = false

func _ready() -> void:
	Text.visible = false
	# NEW: Connect to the global interaction signal
	InputManager.interaction_button_pressed.connect(_on_interact)

func _process(delta: float) -> void:
	if not player:
		return

	var is_player_in_area = get_overlapping_bodies().has(player)
	var is_hiding_spot_active = not HidingCollision.disabled

	# Determine if the text should be visible this frame
	var should_be_visible = is_player_in_area and is_hiding_spot_active
	Text.visible = should_be_visible

	# NEW: Check if the visibility state CHANGED to emit signals
	if Text.visible and not was_text_visible:
		InputManager.emit_signal("show_interaction_button")
	elif not Text.visible and was_text_visible:
		InputManager.emit_signal("hide_interaction_button")
	
	was_text_visible = Text.visible

# NEW: This function is called by the global signal from InputManager
func _on_interact() -> void:
	# We still check if the player is in the area to make sure we're the
	# intended target of the interaction.
	if Text.visible:
		Cloth.visible = false
		HidingCollision.disabled = true
		Text.visible = false # This will trigger the hide signal in the next _process frame
		AudioManager.play_sfx(Constants.AUDIO.cloth_drop, 1)

		if dialogue_manager:
			dialogue_manager.trigger_cloth_removed()
