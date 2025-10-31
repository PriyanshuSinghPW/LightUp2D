extends Area2D

@onready var Cloth: Sprite2D = $HidingCloth
@onready var HidingCollision: CollisionShape2D = $HidingCollision
@onready var Text: Label = $Text

# Assign your player node to this variable in the Godot Editor's Inspector.
@export var player: CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide the interaction text by default.
	Text.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# First, check if the player variable has been assigned in the editor to avoid errors.
	if not player:
		return

	# Check if the player is inside the area and if the hiding spot is still active.
	var is_player_in_area = get_overlapping_bodies().has(player)
	var is_hiding_spot_active = not HidingCollision.disabled

	# If the player is in range of an active hiding spot...
	if is_player_in_area and is_hiding_spot_active:
		Text.visible = true # Show the interaction text.

		# ...then check if the player presses the "Interaction" button.
		if Input.is_action_just_pressed("Interaction"):
			Cloth.visible = false
			HidingCollision.disabled = true
			Text.visible = false # Hide text immediately after interaction.
			AudioManager.play_sfx(Constants.AUDIO.cloth_drop, 1)
	else:
		# If the player is not in the area or the spot is no longer active, hide the text.
		Text.visible = false
