extends Area2D

# Emitted when the mirror's rotation changes
signal rotated

# --- Configuration ---
const ROTATION_FRAMES: float = 30.0
const FRAME_0_ROTATION_OFFSET: float = PI / 2.0 # 90 degrees for "down"

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# This is the new node that will handle the invisible, functional rotation
@onready var functional_rotation_node: Node2D = $FunctionalRotation
@onready var debug_pointer: Sprite2D = $FunctionalRotation/DebugPointer
@onready var forward_direction: Marker2D = $FunctionalRotation/ForwardDirection

# --- Drag State ---
var is_being_dragged: bool = false
var initial_rotation: float = 0.0
var initial_mouse_angle: float = 0.0

func get_redirect_direction() -> Vector2:
	"""
	Returns the direction vector the mirror should redirect light towards.
	This is determined by the DebugPointer's global rotation.
	"""
	if debug_pointer:
		# The DebugPointer's orientation directly controls the output direction.
		return Vector2.from_angle(debug_pointer.global_rotation)
	else:
		# Fallback in case the node is missing
		return Vector2.RIGHT

func get_connection_point() -> Vector2:
	"""
	Returns the global position from where the redirected beam should start.
	This is determined by the ForwardDirection marker.
	"""
	if forward_direction:
		return forward_direction.global_position
	# Fallback to the mirror's own center if the marker is somehow missing
	return global_position


func _ready() -> void:
	if not animated_sprite or not functional_rotation_node:
		push_error("Mirror.gd requires AnimatedSprite2D and FunctionalRotation child nodes.")
		return
	animated_sprite.stop()

func _process(_delta: float) -> void:
	if is_being_dragged:
		# --- 1. Calculate and Apply Functional Rotation ---
		var current_mouse_angle = (get_global_mouse_position() - global_position).angle()
		var angle_delta = current_mouse_angle - initial_mouse_angle
		# Apply rotation to the functional node. This will feel "backwards" but is functionally correct.
		functional_rotation_node.rotation = initial_rotation + angle_delta
		
		# --- 2. Update Visual Frame ---
		update_visual_frame()
		
		# --- 3. Emit Signal ---
		emit_signal("rotated")

func update_visual_frame() -> void:
	# Normalize the functional rotation to be between 0 and 2*PI
	var normalized_angle = fposmod(functional_rotation_node.rotation + FRAME_0_ROTATION_OFFSET, 2 * PI)
	
	# INVERT the angle for the visual calculation to match the drag direction
	var inverted_angle = (2 * PI) - normalized_angle
	
	# Map the inverted angle to a frame number
	var frame_float = (inverted_angle / (2 * PI)) * ROTATION_FRAMES
	
	# Set the integer frame on the AnimatedSprite2D
	animated_sprite.frame = int(frame_float) % int(ROTATION_FRAMES)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_being_dragged = true
			# Get the initial rotation from the functional node
			initial_rotation = functional_rotation_node.rotation
			initial_mouse_angle = (get_global_mouse_position() - global_position).angle()
		else:
			is_being_dragged = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_being_dragged = false
