extends Node

# Manages a sequence of camera movements for a cutscene.
# It automatically finds the global CameraController and disables it during the cutscene.

@export var default_transition_speed: float = 4.0
@export var default_zoom_speed: float = 3.0

var _camera: Camera2D
var _gameplay_controller: Node # Reference to the global gameplay CameraController
var _is_active: bool = false
var _shot_queue: Array = []
var _current_target_pos: Vector2
var _current_target_zoom: Vector2
var _wait_timer: float = 0.0

func _process(delta: float) -> void:
	if not _is_active or not is_instance_valid(_camera):
		return

	if _wait_timer > 0:
		_wait_timer -= delta
		if _wait_timer <= 0:
			_process_next_shot_in_queue()
		return

	_camera.global_position = _camera.global_position.lerp(_current_target_pos, delta * default_transition_speed)
	_camera.zoom = _camera.zoom.lerp(_current_target_zoom, delta * default_zoom_speed)

	if _camera.global_position.is_equal_approx(_current_target_pos) and _camera.zoom.is_equal_approx(_current_target_zoom):
		_process_next_shot_in_queue()

# --- Public API ---

# Call this to begin setting up the cutscene.
func start_cutscene(camera: Camera2D):
	_camera = camera
	
	# Find and disable the global gameplay controller
	_gameplay_controller = get_node_or_null("/root/CameraController")
	if is_instance_valid(_gameplay_controller):
		_gameplay_controller.set_process(false) # CRITICAL STEP: Prevents conflicts
	else:
		push_warning("CutsceneCameraController: Global CameraController not found.")

	_shot_queue.clear()
	_is_active = false

# Add a camera movement to focus on a specific Node2D.
func add_focus_on_node(target_node: Node2D, zoom_level: float = 1.0):
	if not is_instance_valid(target_node):
		push_warning("CutsceneCameraController: Invalid target node provided.")
		return
	var shot_data = {
		"type": "move",
		"target_pos": target_node.global_position,
		"target_zoom": Vector2(zoom_level, zoom_level)
	}
	_shot_queue.append(shot_data)

# Add a pause where the camera holds its position.
func add_wait(duration: float):
	var shot_data = {
		"type": "wait",
		"duration": duration
	}
	_shot_queue.append(shot_data)

# Start executing the queued shots.
func play():
	if _shot_queue.size() == 0:
		push_warning("CutsceneCameraController: Play called with no shots in queue.")
		end_cutscene()
		return
	
	_is_active = true
	_process_next_shot_in_queue()

# --- Internal Logic ---

func _process_next_shot_in_queue():
	if _shot_queue.size() > 0:
		var next_shot = _shot_queue.pop_front()
		if next_shot.type == "move":
			_wait_timer = 0.0
			_current_target_pos = next_shot.target_pos
			_current_target_zoom = next_shot.target_zoom
		elif next_shot.type == "wait":
			_wait_timer = next_shot.duration
	else:
		end_cutscene()

# Cleans up and returns control to the gameplay camera.
func end_cutscene():
	_is_active = false
	_shot_queue.clear()
	
	# Re-enable the gameplay controller
	if is_instance_valid(_gameplay_controller):
		_gameplay_controller.set_process(true)
		if _gameplay_controller.has_method("clear_focus"):
			_gameplay_controller.clear_focus()
