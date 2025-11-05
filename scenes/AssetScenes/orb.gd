extends AnimatedSprite2D

# --- Node References ---
@onready var area_2d: Area2D = $Area2D
@onready var scroll: AnimatedSprite2D = $Scroll
@onready var orb_light: PointLight2D = $orbLight
@onready var Text: Label = $Text

@onready var Canvas: CanvasLayer = $CanvasLayer
@onready var ScrollText: Label = $CanvasLayer/OpenedScroll/ScrollText
@onready var OpenedScroll: TextureRect = $CanvasLayer/OpenedScroll
@onready var closeButton: TextureButton = $CanvasLayer/CloseButton

@export var player: CharacterBody2D
# --- Exposed variable for the scroll's text ---
@export_multiline var scroll_text_content: String = "Your default scroll text here."
# --- New: Exposed variable for the scroll's image ---
# If you assign a texture here, it will be used as an image scroll instead of a text scroll.
@export var scroll_image_texture: Texture2D = null

# NEW: State variable to track if the text was visible last frame
var was_text_visible: bool = false


# --- State Variables ---
var is_unlocked: bool = false
var is_player_in_area: bool = false
var is_ui_busy: bool = false # Prevents spamming open/close actions

# --- Scroll Animation Parameters ---
const FLOAT_DISTANCE = 8.0
const FLOAT_DURATION = 1.5
const UI_ANIMATION_DURATION = 0.5

var _scroll_initial_position: Vector2
var _opened_scroll_original_position: Vector2


func _ready() -> void:
	add_to_group("ClueTarget")
	
	# --- Initial State Setup ---
	play("default")
	scroll.visible = false
	orb_light.texture_scale = 0.7
	Text.visible = false
	Canvas.visible = false
	
	# --- New: Logic to determine scroll type (Image or Text) ---
	if scroll_image_texture:
		# This is an Image Scroll.
		# Assign the provided texture to the OpenedScroll node.
		OpenedScroll.texture = scroll_image_texture
		# Hide the text label.
		ScrollText.visible = false
	else:
		# This is a Text Scroll.
		# Assign the text content and ensure the label is visible.
		ScrollText.text = scroll_text_content
		ScrollText.visible = true
	
	_scroll_initial_position = scroll.position
	_opened_scroll_original_position = OpenedScroll.position
	
	# Set the close button to be transparent initially for the fade-in effect.
	closeButton.modulate.a = 0.0
	
	InputManager.interaction_button_pressed.connect(_on_interact)
	
	closeButton.pressed.connect(_on_close_button_pressed)


func _process(delta: float) -> void:
	if not player:
		return

	is_player_in_area = area_2d.get_overlapping_bodies().has(player)

	# MODIFIED: Logic to show/hide prompt and emit signals
	var should_be_visible = scroll.visible and is_player_in_area
	Text.visible = should_be_visible

	if Text.visible and not was_text_visible:
		InputManager.emit_signal("show_interaction_button")
	elif not Text.visible and was_text_visible:
		InputManager.emit_signal("hide_interaction_button")
	
	was_text_visible = Text.visible

# NEW: This function replaces the direct input check in _process
func _on_interact() -> void:
	# Only interact if the player is in the area
	if is_player_in_area and scroll.visible:
		if not Canvas.visible:
			_open_scroll_ui()
		else:
			_close_scroll_ui()


func unlock_target() -> void:
	if is_unlocked:
		return
	is_unlocked = true

	# --- Activation Sequence ---
	play("spinning")
	
	var tween = create_tween()
	tween.tween_property(orb_light, "texture_scale", 8.0, 1.5).from_current()

	await get_tree().create_timer(2.0).timeout

	play("EmptyPillar")
	
	scroll.visible = true
	_start_scroll_float()
	
	var tween2 = create_tween()
	tween2.tween_property(orb_light, "texture_scale", 1.2, 1.0).from_current()


# --- Function to handle the scroll's floating animation ---
func _start_scroll_float() -> void:
	var float_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(scroll, "position:y", 
		_scroll_initial_position.y - FLOAT_DISTANCE, FLOAT_DURATION
	)
	float_tween.tween_property(scroll, "position:y", 
		_scroll_initial_position.y, FLOAT_DURATION
	)


# --- Function to animate the scroll UI opening ---
func _open_scroll_ui() -> void:
	if is_ui_busy or Canvas.visible:
		return
	is_ui_busy = true
	
	Canvas.visible = true
	
	var screen_size = get_viewport_rect().size
	OpenedScroll.position.y = screen_size.y
	
	closeButton.modulate.a = 0.0
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(OpenedScroll, "position", _opened_scroll_original_position, UI_ANIMATION_DURATION)
	tween.parallel().tween_property(closeButton, "modulate:a", 1.0, UI_ANIMATION_DURATION)
	
	await tween.finished
	is_ui_busy = false


# --- Function to animate the scroll UI closing ---
func _close_scroll_ui() -> void:
	if is_ui_busy or not Canvas.visible:
		return
	is_ui_busy = true
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	var screen_size = get_viewport_rect().size
	tween.tween_property(OpenedScroll, "position:y", screen_size.y, UI_ANIMATION_DURATION)
	tween.parallel().tween_property(closeButton, "modulate:a", 0.0, UI_ANIMATION_DURATION)
	
	await tween.finished
	Canvas.visible = false
	OpenedScroll.position = _opened_scroll_original_position
	is_ui_busy = false


# --- Function to handle the close button being pressed ---
func _on_close_button_pressed() -> void:
	_close_scroll_ui()
