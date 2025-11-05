extends Node2D

# --- Node References ---
@onready var dialoguesNode: Control = $CanvasLayer/Dialogues
@onready var dialogue_background: TextureRect = $CanvasLayer/Dialogues/DialogueBackground
@onready var dialogue_label: RichTextLabel = $CanvasLayer/Dialogues/DialogueBackground/DialogueLabel
@onready var character_portrait: TextureRect = $CanvasLayer/Dialogues/Character
@onready var dialogue_timer: Timer = $CanvasLayer/Dialogues/DialogueTimer

@export var light_beam_node: Node2D 
@export var player_node: Node2D 
@onready var cutscene_camera_controller: Node = $"../CutsceneCameraController"
@onready var main_camera: Camera2D = get_viewport().get_camera_2d() 

@onready var gameplay_camera_controller: Node = get_node_or_null("/root/CameraController")
@onready var ObjectiveText: RichTextLabel = $CanvasLayer/ObjectiveText

# --- ASYNCHRONOUS EVENT QUEUE ---
var event_queue: Array = []
var is_system_busy: bool = false

# --- NEW FLAG TO FIX THE INTRO ---
var is_in_intro: bool = true

# --- Dialogue Management ---
var dialogue_queue = []
var current_dialogue_name: String = ""

# --- State Management ---
var puzzle_state = {
	"cloth_removed": false,
	"table_in_position": false,
	"mirror_is_rotated": false,
	"almirah_is_pushed": false,
	"door_is_unlocked": false
}
var story_triggers_fired = {
	"mammoth_area": false,
	"light_beam_cutscene": false,
	"table_push_instruction": false,
	"mirror_rotate_instruction": false,
	"mirror_reflection_discovery": false,
	"almirah_push_instruction": false,
	"almirah_hiding_spot_discovery": false,
	"hint_mirror_rotated_early_played": false
}

# --- Dialogue Content (Unchanged) ---
var part1_initial_dialogue = [
	{"character": "Jay", "text": "This place is… bigger than I thought.", "texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png", "duration": 2.3},
	{"character": "Roshni", "text": "And creepier. Look at those exhibits!", "texture": "res://assets/CutSceneAssets/Roshni/RoshniTeaching.png", "duration": 2.7}
]
var part2_mammoth_dialogue = [
	{"character": "Jay", "text": "“Extinct thousands of years ago.” Yeah, no kidding.", "texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png", "duration": 3},
	{"character": "Roshni", "text": "Be nice. That thing’s probably the most alive-looking object here.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniDefault.png", "duration": 3.6}
]
var mirror_reaction_dialogue = [
	{"character": "Jay", "text": "Whoa, a mirror!", "texture": "res://assets/CutSceneAssets/Jay/JayHappy.png", "duration": 2},
	{"character": "Roshni", "text": "What's that doing here?", "texture": "res://assets/CutSceneAssets/Roshni/RoshniThinking.png", "duration": 2.5}
]
var light_beam_dialogue = [
	{"character": "Roshni", "text": "Hey… check that out.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniTeaching.png", "duration": 2.0},
	{"character": "Jay", "text": "The light?", "texture": "res://assets/CutSceneAssets/Jay/JayConfused.png", "duration": 1},
	{"character": "Roshni", "text": "Yeah. See how it cuts straight through the dust? It’s like a ruler in the air — no curves, no turns.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniTeaching.png", "duration": 5},
	{"character": "Jay", "text": "So that’s… “light travels in a straight line,” right?", "texture": "res://assets/CutSceneAssets/Jay/jayDefault.png", "duration": 3.5},
	{"character": "Roshni", "text": "Finally, something from science class you remember.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniDefault.png", "duration": 3.0}
]
var push_table_instruction_dialogue = [
	{"character": "Roshni", "text": "Push the table! Let's get that light to touch the mirror.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExplaining.png", "duration": 4.0}
]
var table_pushed_dialogue = [
	{"character": "Jay", "text": "Okay, it's in position.", "texture": "res://assets/CutSceneAssets/Jay/jayDefault.png", "duration": 2},
	{"character": "Roshni", "text": "Perfect! Now try rotating the mirror to aim the light.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExplaining.png", "duration": 4.0}
]
var mirror_rotation_dialogue = [
	{"character": "Jay", "text": "Woah I can actually rotate this thing, its so cool.", "texture": "res://assets/CutSceneAssets/Jay/jayHappy.png", "duration": 3.0},
	{"character": "Roshni", "text": "Yeah.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExcited.png", "duration": 1.7}
]
var mirror_reflection_dialogue = [
	{"character": "Jay", "text": "Huh… it’s bouncing off the mirror. Straight line again.", "texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png", "duration": 4.0},
	{"character": "Roshni", "text": "Reflection. Not bad, Professor Jay.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniSmile.png", "duration": 3.0}
]
var investigate_reflection_dialogue = [
	{"character": "Jay", "text": "But the light is just hitting that big cupboard.", "texture": "res://assets/CutSceneAssets/Jay/JayConfused.png", "duration": 3.5},
	{"character": "Roshni", "text": "Maybe it's not supposed to. Try giving that thing a push!", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExplaining.png", "duration": 4.0}
]
var almirah_moved_dialogue = [
	{"character": "Jay", "text": "Hey, there's a weird flower on the wall back there.", "texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png", "duration": 4.0},
	{"character": "Roshni", "text": "That must be the target! Aim the light at it.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExplaining.png", "duration": 3.5}
]
var door_unlocked_dialogue = [
	{"character": "Jay", "text": "Whoa! It opened something!", "texture": "res://assets/CutSceneAssets/Jay/JayHappy.png", "duration": 3.0},
	{"character": "Roshni", "text": "A light-activated lock... That's brilliant.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniSmile.png", "duration": 3.5},
	{"character": "Jay", "text": "Let's see what's through here.", "texture": "res://assets/CutSceneAssets/Jay/jayDefault.png", "duration": 2.5}
]
var hint_table_pushed_too_early = [
	{"character": "Jay", "text": "Okay, the table's sitting in the light beam now.", "texture": "res://assets/CutSceneAssets/Jay/jayDefault.png", "duration": 3.0},
	{"character": "Roshni", "text": "But... what's it for? There's nothing for the light to hit. Let's keep looking around.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniThinking.png", "duration": 4.0}
]
var hint_mirror_rotated_too_early = [
	{"character": "Roshni", "text": "Rotating this is cool, but the light isn't even reaching it. We should push that table into the beam first.", "texture": "res://assets/CutSceneAssets/Roshni/RoshniExplaining.png", "duration": 5.0}
]


func _ready():
	dialoguesNode.visible = true
	dialogue_background.visible = false
	ObjectiveText.visible = true
	ObjectiveText.text = "" 
	dialogue_timer.connect("timeout", _on_DialogueTimer_timeout)
	start_dialogue(part1_initial_dialogue, "part1_initial")

func _process(_delta):
	if not is_system_busy and not event_queue.is_empty():
		var current_event = event_queue.pop_front()
		_handle_event(current_event)

# --- Event Handler: The new central point for all game logic ---
func _handle_event(event: Dictionary):
	var event_name = event.get("name", "")
	
	match event_name:
		"dialogue_finished":
			var dialogue_name = event.get("dialogue_name", "")
			# --- FIX IS HERE ---
			if dialogue_name == "part1_initial":
				ObjectiveText.text = "Objective: Explore the museum."
				is_in_intro = false # The intro phase is now over.
			else:
				# All other dialogues can trigger the main puzzle logic update
				if dialogue_name == "light_beam":
					if is_instance_valid(gameplay_camera_controller): gameplay_camera_controller.set_process(true)
				update_narrative_and_objectives()
		
		"mammoth_area_entered":
			if not story_triggers_fired["mammoth_area"]:
				story_triggers_fired["mammoth_area"] = true
				start_dialogue(part2_mammoth_dialogue, "")
		
		"cloth_removed":
			if not puzzle_state["cloth_removed"]:
				puzzle_state["cloth_removed"] = true
				start_dialogue(mirror_reaction_dialogue, "cloth_removed")
		
		"table_pushed":
			if not puzzle_state["table_in_position"]:
				puzzle_state["table_in_position"] = true
				if not puzzle_state["cloth_removed"]:
					start_dialogue(hint_table_pushed_too_early, "")
				else:
					update_narrative_and_objectives()
		
		"mirror_rotated":
			if not puzzle_state["mirror_is_rotated"]:
				puzzle_state["mirror_is_rotated"] = true
				if puzzle_state["table_in_position"] and puzzle_state["cloth_removed"]:
					start_dialogue(mirror_rotation_dialogue, "")
				else:
					update_narrative_and_objectives()
		
		"almirah_pushed":
			if not puzzle_state["almirah_is_pushed"]:
				puzzle_state["almirah_is_pushed"] = true
				update_narrative_and_objectives()
		
		"door_unlocked":
			if not puzzle_state["door_is_unlocked"]:
				puzzle_state["door_is_unlocked"] = true
				start_dialogue(door_unlocked_dialogue, "")
				update_narrative_and_objectives()

func update_narrative_and_objectives():
	if puzzle_state["door_is_unlocked"]:
		ObjectiveText.text = "Objective: Proceed through the unlocked door."; return

	if not puzzle_state["cloth_removed"]:
		ObjectiveText.text = "Objective: Explore the museum."; return

	if not story_triggers_fired["light_beam_cutscene"]:
		run_light_beam_sequence(); return
	
	if not puzzle_state["table_in_position"]:
		ObjectiveText.text = "Objective: Push the table to reflect the light."
		if puzzle_state["mirror_is_rotated"] and not story_triggers_fired["hint_mirror_rotated_early_played"]:
			story_triggers_fired["hint_mirror_rotated_early_played"] = true
			start_dialogue(hint_mirror_rotated_too_early, "")
		elif not story_triggers_fired["table_push_instruction"]:
			story_triggers_fired["table_push_instruction"] = true
			start_dialogue(push_table_instruction_dialogue, "")
		return

	if not puzzle_state["mirror_is_rotated"]:
		ObjectiveText.text = "Objective: Rotate the mirror to aim the light."
		if not story_triggers_fired["mirror_rotate_instruction"]:
			story_triggers_fired["mirror_rotate_instruction"] = true
			start_dialogue(table_pushed_dialogue, "")
		return

	if not story_triggers_fired["mirror_reflection_discovery"]:
		story_triggers_fired["mirror_reflection_discovery"] = true
		start_dialogue(mirror_reflection_dialogue, "mirror_reflection_discovery"); return
	
	if not puzzle_state["almirah_is_pushed"]:
		ObjectiveText.text = "Objective: Push the almirah out of the way."
		if not story_triggers_fired["almirah_push_instruction"]:
			story_triggers_fired["almirah_push_instruction"] = true
			start_dialogue(investigate_reflection_dialogue, "")
		return
	
	ObjectiveText.text = "Objective: Aim the reflected light at the target."
	if not story_triggers_fired["almirah_hiding_spot_discovery"]:
		story_triggers_fired["almirah_hiding_spot_discovery"] = true
		start_dialogue(almirah_moved_dialogue, "")

func start_dialogue(dialogue_array: Array, name: String):
	if is_system_busy: return
	is_system_busy = true
	current_dialogue_name = name
	dialogue_queue = dialogue_array.duplicate(); _display_next_dialogue()
func _display_next_dialogue():
	if dialogue_queue.is_empty(): _end_dialogue(); return
	var current_dialogue = dialogue_queue.pop_front()
	dialogue_label.text = "%s: %s" % [current_dialogue["character"], current_dialogue["text"]]
	character_portrait.texture = load(current_dialogue["texture"])
	dialogue_background.visible = true; character_portrait.visible = true
	dialogue_timer.start(current_dialogue["duration"])
func _on_DialogueTimer_timeout():
	_display_next_dialogue()
func _end_dialogue():
	var finished_dialogue_name = current_dialogue_name
	dialogue_background.visible = false; character_portrait.visible = false
	is_system_busy = false
	event_queue.push_back({"name": "dialogue_finished", "dialogue_name": finished_dialogue_name})

# --- Signal Handlers: These now ONLY queue events. They are simple and instant. ---
func _on_mammoth_area_body_entered(_body: Node2D) -> void:
	# --- FIX IS HERE ---
	# Only queue this event if the intro is over.
	if is_in_intro:
		return
	event_queue.push_back({"name": "mammoth_area_entered"})

func trigger_cloth_removed():
	event_queue.push_back({"name": "cloth_removed"})
func _on_pushable_table_pushed() -> void:
	event_queue.push_back({"name": "table_pushed"})
func _on_mirror_rotated() -> void:
	event_queue.push_back({"name": "mirror_rotated"})
func _on_pushable_almirah_pushed() -> void:
	event_queue.push_back({"name": "almirah_pushed"})
func _on_light_target_unlocked() -> void:
	event_queue.push_back({"name": "door_unlocked"})
		
func run_light_beam_sequence():
	if story_triggers_fired["light_beam_cutscene"]: return
	story_triggers_fired["light_beam_cutscene"] = true
	start_dialogue(light_beam_dialogue, "light_beam")
	if not is_instance_valid(player_node): push_error("Player Node not assigned!"); return
	is_system_busy = true
	cutscene_camera_controller.start_cutscene(main_camera)
	cutscene_camera_controller.add_focus_on_node(light_beam_node, 1.5)
	cutscene_camera_controller.add_wait(3.0)
	cutscene_camera_controller.add_return_shot(player_node)
	cutscene_camera_controller.play()
