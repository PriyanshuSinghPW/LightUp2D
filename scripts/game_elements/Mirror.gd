extends Area2D

# Emitted when the mirror's rotation changes
signal rotated

# --- Configuration ---
const ROTATION_FRAMES: float = 30.0
const FRAME_0_ROTATION_OFFSET: float = PI / 2.0 # 90 degrees for "down"
@export var interact_distance: float = 140.0 # Max distance player can be to rotate
@export var require_player_in_range: bool = true
@export_range(0.05, 5.0, 0.05) var rotation_sensitivity: float = 0.15 # <1 slower, >1 faster
@export var shift_precision_divisor: float = 4.0 # Hold Shift for finer control

# --- Node References ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# This is the new node that will handle the invisible, functional rotation
@onready var functional_rotation_node: Node2D = $FunctionalRotation
@onready var debug_pointer: Sprite2D = $FunctionalRotation/DebugPointer
@onready var forward_direction: Marker2D = $FunctionalRotation/ForwardDirection
var _rotation_started: bool = false

# --- Drag State ---
var is_being_dragged: bool = false
var initial_rotation: float = 0.0
var initial_mouse_angle: float = 0.0
var was_in_range_last_frame: bool = false
var camera_focus_active: bool = false
var proximity_check_counter: int = 0
var cached_target: Node2D = null

# Cached player reference
var _player: Node2D = null
var _camera_cached: Camera2D = null
@export var auto_frame_target: NodePath
@export var auto_frame_enabled: bool = true

func _get_camera():
	if _camera_cached and is_instance_valid(_camera_cached):
		return _camera_cached
	_find_player()
	if _player and _player.has_node("Camera2D"):
		_camera_cached = _player.get_node("Camera2D")
	return _camera_cached

func _find_player():
	if _player and is_instance_valid(_player):
		return
	# Prefer group lookup if player added to 'player' group
	var by_group = get_tree().get_first_node_in_group("player")
	if by_group:
		_player = by_group
		return
	# Fallback: search by name
	var _candidates = get_tree().get_nodes_in_group("Node") # cheap placeholder, will iterate manually
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
	add_to_group("mirror")

func _process(_delta: float) -> void:
	# Check proximity every 5 frames for performance (proximity doesn't need frame-perfect accuracy)
	if auto_frame_enabled:
		proximity_check_counter += 1
		if proximity_check_counter >= 5:
			proximity_check_counter = 0
			
			var in_range = _player_in_range()
			
			# Player just entered range - activate framing
			if in_range and not was_in_range_last_frame:
				print("[Mirror] Player entered range, activating camera framing")
				_activate_camera_framing()
				camera_focus_active = true
			# Player just left range - deactivate framing
			elif not in_range and was_in_range_last_frame:
				print("[Mirror] Player left range, resetting camera")
				_deactivate_camera_framing()
				camera_focus_active = false
			
			was_in_range_last_frame = in_range
	
	if is_being_dragged:
		# Abort dragging if player moved away
		if not _player_in_range():
			is_being_dragged = false
			# --- MODIFICATION START ---
			# Stop the sound if the player moves out of range
			if _rotation_started:
				AudioManager.stop_looping_sfx(Constants.AUDIO.gear_rotate)
				_rotation_started = false
			# --- MODIFICATION END ---
			return
		# --- 1. Calculate and Apply Functional Rotation ---
		var current_mouse_angle = (get_global_mouse_position() - global_position).angle()
		# Wrap delta into -PI..PI to avoid jumps crossing the boundary
		var angle_delta = wrapf(current_mouse_angle - initial_mouse_angle, -PI, PI)

		var applied_sensitivity = rotation_sensitivity
		# Optional precision mode when Shift is held
		if Input.is_key_pressed(KEY_SHIFT):
			applied_sensitivity /= max(shift_precision_divisor, 1.0)
			
		if not _rotation_started and abs(angle_delta) > 0.01:
			# --- MODIFICATION START ---
			# Use the looping SFX player so we can stop it later
			AudioManager.play_looping_sfx(Constants.AUDIO.gear_rotate, 1)
			# --- MODIFICATION END ---
			_rotation_started = true

		functional_rotation_node.rotation = initial_rotation + angle_delta * applied_sensitivity
		
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
				_rotation_started = false 
				# Get the initial rotation from the functional node
				initial_rotation = functional_rotation_node.rotation
				initial_mouse_angle = (get_global_mouse_position() - global_position).angle()
				# Camera framing is now handled by proximity check in _process
				_find_player()
				print("[Mirror] Drag started, player: ", _player)
			else:
				# Optional: give brief visual feedback (flash) when out of range
				if animated_sprite:
					animated_sprite.modulate = Color(1,0.6,0.6)
					await get_tree().create_timer(0.08).timeout
					animated_sprite.modulate = Color.WHITE
		else:
			# This block executes when the left mouse button is RELEASED
			if is_being_dragged:
				is_being_dragged = false
				# --- MODIFICATION START ---
				# Stop the sound when the player releases the mouse
				if _rotation_started:
					AudioManager.stop_looping_sfx(Constants.AUDIO.gear_rotate)
					_rotation_started = false
				# --- MODIFICATION END ---


func _unhandled_input(event: InputEvent) -> void:
	# This is a fallback to catch mouse releases that might happen outside the Area2D
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if is_being_dragged:
			is_being_dragged = false
			# --- MODIFICATION START ---
			# Also stop the sound here for robustness
			if _rotation_started:
				AudioManager.stop_looping_sfx(Constants.AUDIO.gear_rotate)
				_rotation_started = false
			# --- MODIFICATION END ---
		# Camera framing is now controlled by proximity, not drag state

func _activate_camera_framing():
	print("[Mirror] _activate_camera_framing called")
	if not auto_frame_enabled:
		print("[Mirror] auto_frame_enabled is FALSE, aborting")
		return
	
	# Use cached target if available
	var target: Node2D = cached_target
	
	# Only search if we don't have a cached target
	if target == null or not is_instance_valid(target):
		# First check if user specified a target via NodePath
		if auto_frame_target != NodePath("") and has_node(auto_frame_target):
			target = get_node(auto_frame_target)
			print("[Mirror] Using explicit auto_frame_target: ", target)
		
		# If no explicit target, search for LightTarget in the level
		if target == null:
			var light_targets = get_tree().get_nodes_in_group("light_target")
			if light_targets.size() > 0:
				target = light_targets[0]
				print("[Mirror] Found LightTarget in tree: ", target)
		
		# Check if this mirror has a LightTarget child (less common)
		if target == null and has_node("LightTarget"):
			target = get_node("LightTarget")
			print("[Mirror] Using LightTarget child: ", target)
		
		if target == null:
			print("[Mirror] No LightTarget found, using mirror itself")
			target = self
		
		# Cache the target for future use
		cached_target = target
	
	var cam = _get_camera()
	if not cam:
		print("[Mirror] ERROR: No camera found!")
		return
	
	var cc = get_node_or_null("/root/CameraController")
	if not cc:
		print("[Mirror] ERROR: CameraController not found!")
		return
	
	# Gather nearest two other mirrors in range to include them as context targets
	var mirrors = get_tree().get_nodes_in_group("mirror")
	var others: Array[Node2D] = []
	for m in mirrors:
		if m == self:
			continue
		if m is Node2D and is_instance_valid(m):
			others.append(m)
	# Sort by distance to player (not to this mirror) for relevance
	others.sort_custom(func(a,b): return a.global_position.distance_to(_player.global_position) < b.global_position.distance_to(_player.global_position))
	var selected: Array[Node2D] = []
	for i in range(min(2, others.size())):
		selected.append(others[i])
	# Always include the primary target last for consistency
	selected.append(target)
	print("[Mirror] Activating focus with additional mirrors:", selected.size(), " primary:", target.name)
	cc.focus_points(_player, selected)

func _deactivate_camera_framing():
	print("[Mirror] _deactivate_camera_framing called")
	var cc = get_node_or_null("/root/CameraController")
	if cc:
		cc.clear_focus()
