#light target door
extends Area2D

## Signal emitted when the light beam hits this target.
signal unlocked

## Signal emitted when the player enters the unlocked target.
signal player_entered

var is_unlocked: bool = false

#@export var light_beam_node: Node2D 
@export var player_node: Node2D 
@onready var cutscene_camera_controller: Node = $"../CutsceneCameraController"
@onready var main_camera: Camera2D = get_viewport().get_camera_2d() 
@onready var gameplay_camera_controller: Node = get_node_or_null("/root/CameraController")


func _ready():
	add_to_group("light_target")
	body_entered.connect(_on_body_entered)


func unlock_target():
	"""Called by another script (e.g., Levellightmanager) to unlock this target."""
	if not is_unlocked:
		is_unlocked = true
		print("LightTarget: Unlocked!")
		AudioManager.play_sfx(Constants.AUDIO.EDM)
		unlocked.emit()
		cutscene_camera_controller.start_cutscene(main_camera)
		cutscene_camera_controller.add_focus_on_node(self, 1.5)
		cutscene_camera_controller.add_wait(1.5)
		cutscene_camera_controller.add_return_shot(player_node)
		cutscene_camera_controller.play()


func _on_body_entered(body):
	"""Called when a body enters this area."""
	if is_unlocked and body.is_in_group("player"):
		print("LightTarget: Player has entered the unlocked target.")
		player_entered.emit()
