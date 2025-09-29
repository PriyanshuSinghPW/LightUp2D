extends Area2D

# Emitted when the mirror's rotation changes
signal rotated

# --- Configuration ---
const ROTATION_FRAMES: float = 30.0
const FRAME_0_ROTATION_OFFSET: float = PI / 2.0 # 90 degrees for "down"
@export var interact_distance: float = 140.0 # Max distance player can be to rotate
@export var require_player_in_range: bool = true

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

# Cached player reference
var _player: Node2D = null

func _find_player():
	if _player and is_instance_valid(_player):
		return
	# Prefer group lookup if player added to 'player' group
	var by_group = get_tree().get_first_node_in_group("player")
	if by_group:
		_player = by_group
		return
	# Fallback: search by name
	var candidates = get_tree().get_nodes_in_group("Node") # cheap placeholder, will iterate manually
	for n in get_tree().get_root().get_children():
		if n.has_node("Player"):
			_player = n.get_node("Player")
			return
	# Final fallback: direct name search under scene tree
	var root = get_tree().get_root()
	var stack: Array = [root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node.name == "Player":
			_player = node
			return
		for c in node.get_children():
			stack.append(c)

func _player_in_range() -> bool:
	if not require_player_in_range:
		return true
	_find_player()
	if not _player:
		return false
	return _player.global_position.distance_to(global_position) <= interact_distance

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
		# Abort dragging if player moved away
		if not _player_in_range():
			is_being_dragged = false
			return
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
			if _player_in_range():
				is_being_dragged = true
				# Get the initial rotation from the functional node
				initial_rotation = functional_rotation_node.rotation
				initial_mouse_angle = (get_global_mouse_position() - global_position).angle()
			else:
				# Optional: give brief visual feedback (flash) when out of range
				if animated_sprite:
					animated_sprite.modulate = Color(1,0.6,0.6)
					await get_tree().create_timer(0.08).timeout
					animated_sprite.modulate = Color.WHITE
		else:
			is_being_dragged = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_being_dragged = false
