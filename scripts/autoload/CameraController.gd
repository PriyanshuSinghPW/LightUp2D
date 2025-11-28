extends Node

# Dynamic camera framing utility
# Usage:
#   CameraController.configure(player_camera:Camera2D)
#   CameraController.focus_pair(player:Node2D, target:Node2D)
#   CameraController.clear_focus()

@export var max_zoom_out: float = 1.2 # smaller number = further out if base zoom < 1
@export var min_zoom_in: float = 0.5
@export var lerp_speed: float = 3.0 # Slower for smoother cinematic feel
@export var zoom_lerp_speed: float = 2.0 # Slower zoom for less vertigo
@export var reset_lerp_speed: float = 4.0 # Match reset speed for consistency
@export var padding: float = 160.0
@export var keep_player_margin: float = 120.0
@export var debug_mode: bool = true

var _camera: Camera2D
var _active: bool = false
var _player: Node2D
var _targets: Array[Node2D] = []
var _base_zoom: Vector2 = Vector2.ONE
var _original_smoothing: bool = false
var _is_snapped: bool = false

func configure(cam: Camera2D):
    _camera = cam
    _base_zoom = cam.zoom
    if "position_smoothing_enabled" in _camera:
        _original_smoothing = _camera.position_smoothing_enabled
    # Force physics interpolation for smooth movement even at low tick rates
    if "physics_interpolation_mode" in _camera:
        _camera.physics_interpolation_mode = 1 # Node.PHYSICS_INTERPOLATION_MODE_ON

func _auto_find_camera():
    if _camera and is_instance_valid(_camera):
        return
    # Try active viewport camera first
    var vc = get_viewport().get_camera_2d()
    if vc:
        configure(vc)
        return
    # Fallback: breadth-first search for first Camera2D
    var root = get_tree().get_root()
    var queue: Array = [root]
    while queue.size() > 0:
        var n = queue.pop_front()
        if n is Camera2D:
            configure(n)
            return
        for c in n.get_children():
            queue.append(c)

func focus_pair(player: Node2D, target: Node2D):
    if not _camera:
        _auto_find_camera()
    if not _camera:
        if debug_mode:
            push_warning("[CameraController] No camera found, focus_pair aborted")
        return
    _player = player
    _targets = [target]
    _active = true
    
    # Detach camera to prevent fighting with parent movement
    # We do NOT disable smoothing anymore to prevent the "snap" effect
    if _camera.get_parent() == _player:
        _camera.top_level = true
            
    if debug_mode:
        print("[CameraController] Focusing (pair) on player:", player.name, " + target:", target.name, " | base_zoom:", _base_zoom)

func focus_points(player: Node2D, extra_points: Array[Node2D]):
    if not _camera:
        _auto_find_camera()
    if not _camera:
        if debug_mode:
            push_warning("[CameraController] No camera found, focus_points aborted")
        return
    _player = player
    _targets = []
    for p in extra_points:
        if p and is_instance_valid(p):
            _targets.append(p)
    if _targets.size() == 0:
        _active = false
        return
    _active = true
    
    # Detach camera to prevent fighting with parent movement
    # We do NOT disable smoothing anymore to prevent the "snap" effect
    if _camera.get_parent() == _player:
        _camera.top_level = true
            
    if debug_mode:
        var names := []
        for t in _targets:
            names.append(t.name)
        print("[CameraController] Focusing on player + points:", names, " | count:", _targets.size())

func clear_focus():
    _active = false
    if debug_mode:
        print("[CameraController] Clearing focus, resetting to player")
    # Don't just reset zoom - smoothly return camera to player position
    # Camera will smoothly return to player in _process

func _process(delta: float) -> void:
    if not _camera:
        return
    
    # If not active, smoothly return camera to player
    if not _active:
        if is_instance_valid(_player):
            # Smooth return to base zoom
            _camera.zoom = _camera.zoom.lerp(_base_zoom, clamp(delta * zoom_lerp_speed, 0.0, 1.0))
            
            # Handle position return
            if _camera.get_parent() == _player:
                # If we are detached (top_level), we need to return then re-attach
                if _camera.top_level:
                    var target_pos = _player.global_position
                    _camera.global_position = _camera.global_position.lerp(target_pos, clamp(delta * reset_lerp_speed, 0.0, 1.0))
                    
                    # If close enough, re-attach and let Godot handle it
                    if _camera.global_position.distance_to(target_pos) < 5.0:
                        _camera.top_level = false
                        _camera.position = Vector2.ZERO
                        # Smoothing remains enabled throughout
                else:
                    # Already attached, let Godot handle smoothing/following
                    pass
            else:
                # Not a child, must manually follow
                var target_pos = _player.global_position
                _camera.global_position = _camera.global_position.lerp(target_pos, clamp(delta * reset_lerp_speed, 0.0, 1.0))
        return
    
    # Active mode - frame player + target
    if not is_instance_valid(_player):
        _active = false
        return
    # Filter invalid targets
    var valid_targets: Array[Node2D] = []
    for t in _targets:
        if t and is_instance_valid(t):
            valid_targets.append(t)
    if valid_targets.size() == 0:
        _active = false
        return

    var p_pos = _player.global_position
    # Compute bounding box of all targets + player
    var min_x = p_pos.x
    var max_x = p_pos.x
    var min_y = p_pos.y
    var max_y = p_pos.y
    for t in valid_targets:
        var tp = t.global_position
        min_x = min(min_x, tp.x)
        max_x = max(max_x, tp.x)
        min_y = min(min_y, tp.y)
        max_y = max(max_y, tp.y)
    var center = Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)
    _camera.global_position = _camera.global_position.lerp(center, clamp(delta * lerp_speed, 0.0, 1.0))

    # Required extents from bounding box
    var required_width = (max_x - min_x) + padding * 2.0
    var required_height = (max_y - min_y) + padding * 2.0

    # Calculate zoom needed to fit this world-space rect
    var viewport_size = get_viewport().size
    if viewport_size.x == 0 or viewport_size.y == 0:
        return
    
    var needed_zoom_x = viewport_size.x / required_width
    var needed_zoom_y = viewport_size.y / required_height
    var needed_zoom = min(needed_zoom_x, needed_zoom_y)
    
    var desired_zoom = Vector2(needed_zoom, needed_zoom)
    
    # Clamp so we don't zoom too far in or out relative to base
    desired_zoom.x = clamp(desired_zoom.x, _base_zoom.x * min_zoom_in, _base_zoom.x * max_zoom_out)
    desired_zoom.y = clamp(desired_zoom.y, _base_zoom.y * min_zoom_in, _base_zoom.y * max_zoom_out)

    # Use separate zoom lerp speed for smoother zoom transitions
    _camera.zoom = _camera.zoom.lerp(desired_zoom, clamp(delta * zoom_lerp_speed, 0.0, 1.0))

    # Keep player within margin (only in active mode)
    var half_view = (viewport_size * 0.5) / _camera.zoom
    var cam_pos = _camera.global_position
    var rel_player = p_pos - cam_pos
    
    # Nudge camera if player approaches edge
    if abs(rel_player.x) > half_view.x - keep_player_margin:
        var offset_x = sign(rel_player.x) * (abs(rel_player.x) - (half_view.x - keep_player_margin))
        cam_pos.x += offset_x
    if abs(rel_player.y) > half_view.y - keep_player_margin:
        var offset_y = sign(rel_player.y) * (abs(rel_player.y) - (half_view.y - keep_player_margin))
        cam_pos.y += offset_y
    
    _camera.global_position = _camera.global_position.lerp(cam_pos, clamp(delta * lerp_speed, 0.0, 1.0))
