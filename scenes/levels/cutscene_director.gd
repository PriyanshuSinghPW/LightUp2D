extends Node2D

# --- Node References ---
@onready var dialoguesNode: Control = $CanvasLayer/Dialogues
@onready var dialogue_background: TextureRect = $CanvasLayer/Dialogues/DialogueBackground
@onready var dialogue_label: RichTextLabel = $CanvasLayer/Dialogues/DialogueBackground/DialogueLabel
@onready var character_portrait: TextureRect = $CanvasLayer/Dialogues/Character
@onready var dialogue_timer: Timer = $CanvasLayer/Dialogues/DialogueTimer

# --- Dialogue Management ---
var dialogue_queue = []
var is_playing = false

# Dictionary to ensure area-based triggers only fire once.
var triggers_fired = {
	"mammoth_area": false,
	"light_beam_area": false
}

# --- Dialogue Content ---
# All dialogue from your scene is here, broken into triggerable parts.
# REPLACE the "res://assets/..." paths with your actual image files.

# Part 1: Plays automatically when the level starts.
var part1_initial_dialogue = [
	{
		"character": "Jay",
		"text": "This place is… bigger than I thought.",
		"texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png",
		"duration": 3.7
	},
	{
		"character": "Roshni",
		"text": "And creepier. Look at those exhibits!",
		"texture": "res://assets/CutSceneAssets/Roshni/RoshniTeaching.png",
		"duration": 4
	}
]

# Part 2: Trigger with an Area2D near the mammoth skeleton.
var part2_mammoth_dialogue = [
	{
		"character": "Jay",
		"text": "“Extinct thousands of years ago.” Yeah, no kidding.",
		"texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png",
		"duration": 4.5
	},
	{
		"character": "Roshni",
		"text": "Be nice. That thing’s probably the most alive-looking object here.",
		"texture": "res://assets/CutSceneAssets/Roshni/RoshniDefault.png",
		"duration": 4.0
	}
]

# Part 3: Trigger with an Area2D where the light beam is visible.
var part3_light_beam_dialogue = [
	{
		"character": "Roshni",
		"text": "Hey… check that out.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Observing.png",
		"duration": 2.0
	},
	{
		"character": "Jay",
		"text": "The light?",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Confused.png",
		"duration": 1.5
	},
	{
		"character": "Roshni",
		"text": "Yeah. See how it cuts straight through the dust? It’s like a ruler in the air — no curves, no turns.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Teaching.png",
		"duration": 5.5
	},
	{
		"character": "Jay",
		"text": "So that’s… “light travels in a straight line,” right?",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Thinking.png",
		"duration": 3.5
	},
	{
		"character": "Roshni",
		"text": "(smirks) Finally, something from science class you remember.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Smirking.png",
		"duration": 3.0
	}
]

# Part 4: Call this function MANUALLY after the player moves the mirror.
var part4_mirror_reflection_dialogue = [
	{
		"character": "Jay",
		"text": "Huh… it’s bouncing off the mirror. Straight line again.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Realizing.png",
		"duration": 4.0
	},
	{
		"character": "Roshni",
		"text": "Reflection. Not bad, Professor Jay.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Pleased.png",
		"duration": 3.0
	}
]

# Part 5: Call this MANUALLY after the scroll appears.
var part5_scroll_reaction_dialogue = [
	{
		"character": "Scroll", # Special character to handle differently
		"text": "The halls of shadow test those who seek the truth of light. Align the ray. Awaken the path.",
		"texture": null, # No portrait for the scroll
		"duration": 6.0
	},
	{
		"character": "Jay",
		"text": "…Okay, that’s not creepy at all.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Worried.png",
		"duration": 3.0
	},
	{
		"character": "Roshni",
		"text": "Maybe it’s like an old museum exhibit puzzle. Let’s keep following the light.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Determined.png",
		"duration": 4.5
	}
]

# Part 6: Call this MANUALLY after the player moves the almirah.
var part6_almirah_moved_dialogue = [
	{
		"character": "Jay",
		"text": "Wait, something’s glowing back there.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Pointing.png",
		"duration": 3.0
	},
	{
		"character": "Roshni",
		"text": "Maybe that’s where the light needs to go.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Thinking.png",
		"duration": 3.0
	},
	{
		"character": "Jay",
		"text": "Problem is, this big cupboard’s in the way.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Default.png",
		"duration": 3.0
	},
	{
		"character": "Roshni",
		"text": "Then move those muscles, mirror boy.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Teasing.png",
		"duration": 2.5
	}
]

# Part 7: Call this MANUALLY after the door unlocks.
var part7_door_unlocked_dialogue = [
	{
		"character": "Jay",
		"text": "Whoa. The flower opened the door!",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Excited.png",
		"duration": 3.0
	},
	{
		"character": "Roshni",
		"text": "A light-powered lock. That’s… kinda genius.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Impressed.png",
		"duration": 3.5
	},
	{
		"character": "Jay",
		"text": "And super weird.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Weirded_Out.png",
		"duration": 2.0
	},
	{
		"character": "Roshni",
		"text": "Hey, weird is how science starts. Let’s see what other “projects” this museum’s hiding.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Adventurous.png",
		"duration": 5.0
	},
	{
		"character": "Whisper", # Another special character
		"text": "The first ray awakens the seeker… but the dusk is patient.",
		"texture": null, # No portrait
		"duration": 5.0
	},
	{
		"character": "Jay",
		"text": "…Okay, that’s officially creepy.",
		"texture": "res://assets/CharacterPortraits/Jay/Jay_Scared.png",
		"duration": 2.5
	},
	{
		"character": "Roshni",
		"text": "(half-smile) Told you this would be fun.",
		"texture": "res://assets/CharacterPortraits/Roshni/Roshni_Smirking_Confident.png",
		"duration": 3.0
	}
]


func _ready():
	dialoguesNode.visible = true
	dialogue_background.visible = false
	dialogue_timer.connect("timeout", _on_DialogueTimer_timeout)
	start_dialogue(part1_initial_dialogue)

# --- Core Dialogue Logic ---

func start_dialogue(dialogue_array: Array):
	if is_playing:
		return
	is_playing = true
	dialogue_queue = dialogue_array.duplicate()
	_display_next_dialogue()

func _display_next_dialogue():
	if dialogue_queue.is_empty():
		_end_dialogue()
		return

	var current_dialogue = dialogue_queue.pop_front()
	var character = current_dialogue["character"]
	var text = current_dialogue["text"]
	var texture_path = current_dialogue["texture"]
	
	# Handle special, non-character dialogue like the scroll or whispers
	if character == "Scroll" or character == "Whisper":
		character_portrait.visible = false
		dialogue_label.text = "[i]%s[/i]" % text # Italicize for effect
	else:
		character_portrait.visible = true
		dialogue_label.text = "%s: %s" % [character, text] # Bold the name
		if texture_path:
			character_portrait.texture = load(texture_path)

	dialogue_background.visible = true
	dialogue_timer.start(current_dialogue["duration"])

func _on_DialogueTimer_timeout():
	_display_next_dialogue()

func _end_dialogue():
	is_playing = false
	dialogue_background.visible = false
	character_portrait.visible = false

# --- Trigger Handlers for Area2Ds ---
# Connect your Area2D's "body_entered" signal to these functions.

func _on_mammoth_area_body_entered(body: Node2D) -> void:
	if not triggers_fired["mammoth_area"] and body.is_in_group("player"):
		triggers_fired["mammoth_area"] = true
		start_dialogue(part2_mammoth_dialogue)

func _on_light_beam_area_entered(body):
	if not triggers_fired["light_beam_area"] and body.is_in_group("player"):
		triggers_fired["light_beam_area"] = true
		start_dialogue(part3_light_beam_dialogue)


# --- Public Functions for Interaction-Based Triggers ---
# Call these functions from your other game scripts (player, mirror, etc.)

# Call this from the mirror script after it has been moved successfully.
func trigger_mirror_reflection():
	start_dialogue(part4_mirror_reflection_dialogue)

# Call this from the script managing the scroll's appearance.
func trigger_scroll_reaction():
	start_dialogue(part5_scroll_reaction_dialogue)
	
# Call this from your player/almirah script after it has been pushed.
func trigger_almirah_pushed():
	start_dialogue(part6_almirah_moved_dialogue)

# Call this from whatever script handles the door unlocking logic.
func trigger_door_unlocked():
	start_dialogue(part7_door_unlocked_dialogue)
