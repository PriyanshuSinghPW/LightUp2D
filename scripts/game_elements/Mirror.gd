extends Area2D

# Emitted when the mirror's rotation changes
signal rotated

# A flag to track if this mirror is being dragged
var is_being_dragged: bool = false
# Store the initial rotation and mouse angle when dragging starts
var initial_rotation: float = 0.0
var initial_mouse_angle: float = 0.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play("MirrorAnim")

func _process(_delta: float) -> void:
	# If the mirror is being dragged, calculate the new rotation
	if is_being_dragged:
		# Get the current angle of the mouse relative to the mirror's position
		var current_mouse_angle = (get_global_mouse_position() - global_position).angle()
		# Calculate the change in angle since the drag started
		var angle_delta = current_mouse_angle - initial_mouse_angle
		# Apply this change to the mirror's rotation when the drag began
		rotation = initial_rotation + angle_delta
		emit_signal("rotated")

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# This function is connected to the Area2D's "input_event" signal
	
	# Check for mouse button press to start dragging
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start dragging and record initial state
			is_being_dragged = true
			initial_rotation = rotation
			initial_mouse_angle = (get_global_mouse_position() - global_position).angle()
		else:
			# Stop dragging
			is_being_dragged = false

func _unhandled_input(event: InputEvent) -> void:
	# This handles the case where the player releases the mouse button
	# anywhere on the screen, not just over the mirror.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_being_dragged = false
