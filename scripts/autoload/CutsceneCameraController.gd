# CutSceneCameraController.gd (Corrected)
extends Node

@export var default_transition_speed: float = 4.0
@export var default_zoom_speed: float = 3.0

var _camera: Camera2D
var _gameplay_controller: Node
var _is_active: bool = false
var _shot_queue: Array = []
var _current_target_pos: Vector2
var _current_target_zoom: Vector2
var _wait_timer: float = 0.0

# FIX: New state to manage the final handoff cleanly.
var _is_final_shot: bool = false

var _original_zoom: Vector2

const POS_COMPLETE_THRESHOLD = 0.5
const ZOOM_COMPLETE_THRESHOLD = 0.01

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

	var pos_reached = _camera.global_position.distance_to(_current_target_pos) < POS_COMPLETE_THRESHOLD
	var zoom_reached = abs(_camera.zoom.x - _current_target_zoom.x) < ZOOM_COMPLETE_THRESHOLD

	# FIX: Modified completion logic for a clean handoff.
	if pos_reached and zoom_reached:
		_camera.global_position = _current_target_pos
		_camera.zoom = _current_target_zoom
		
		# If this was the final return shot, end the cutscene properly.
		# This prevents any overlap between camera controllers.
		if _is_final_shot:
			end_cutscene()
		else:
			# Otherwise, process the next event in the queue.
			_process_next_shot_in_queue()

# --- Public API ---

func is_playing() -> bool:
	return _is_active

func start_cutscene(camera: Camera2D):
	_camera = camera
	_original_zoom = camera.zoom
	
	_gameplay_controller = get_tree().get_root().get_node_or_null("CameraController")
	if is_instance_valid(_gameplay_controller):
		# FIX: Reset the gameplay camera's state before disabling it.
		# This ensures it returns to the default player-follow mode smoothly.
		_gameplay_controller.clear_focus()
		_gameplay_controller.set_process(false)
	else:
		push_warning("CutsceneCameraController: Global CameraController at path '/root/CameraController' not found.")

	_shot_queue.clear()
	_is_active = false
	# FIX: Reset the final shot flag at the start of each new cutscene.
	_is_final_shot = false

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

# FIX: Renamed and simplified the return shot function for clarity.
func add_return_to_target_and_end(target_node: Node2D):
	if not is_instance_valid(target_node):
		push_warning("CutsceneCameraController: Invalid target node provided for return shot.")
		return
	var shot_data = {
		"type": "return_and_end", # A special type to signal the final shot.
		"target_pos": target_node.global_position,
		"target_zoom": _original_zoom
	}
	_shot_queue.append(shot_data)

func add_wait(duration: float):
	var shot_data = {
		"type": "wait",
		"duration": duration
	}
	_shot_queue.append(shot_data)

func play():
	if _shot_queue.is_empty():
		push_warning("CutsceneCameraController: Play called with no shots in queue.")
		end_cutscene()
		return
	
	_is_active = true
	_process_next_shot_in_queue()

func _process_next_shot_in_queue():
	if not _shot_queue.is_empty():
		var next_shot = _shot_queue.pop_front()
		
		# FIX: Simplified shot processing logic.
		if next_shot.type == "move":
			_wait_timer = 0.0
			_current_target_pos = next_shot.target_pos
			_current_target_zoom = next_shot.target_zoom
		elif next_shot.type == "return_and_end":
			_wait_timer = 0.0
			_is_final_shot = true # Mark this as the final shot.
			_current_target_pos = next_shot.target_pos
			_current_target_zoom = next_shot.target_zoom
		elif next_shot.type == "wait":
			_wait_timer = next_shot.duration
	else:
		if not _is_final_shot:
			end_cutscene()

func end_cutscene():
	_is_active = false
	_is_final_shot = false # Reset state
	_shot_queue.clear()
	
	if is_instance_valid(_camera):
		_camera.zoom = _original_zoom
	
	# Re-enable the main controller only after this one is fully deactivated.
	if is_instance_valid(_gameplay_controller):
		_gameplay_controller.set_process(true)
