extends Control

# Exported variable lets you choose the AnimationPlayer node in the editor.
@export var animation_player: AnimationPlayer

@onready var fade_effect: ColorRect = $"Fade effect"

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var dialogue_background: TextureRect = $CanvasLayer/DialogueBackground
@onready var dialogue_label: RichTextLabel =  $CanvasLayer/DialogueBackground/DialogueLabel

@onready var next_button: TextureButton = $CanvasLayer/NextButton
@onready var skip_button: TextureButton = $CanvasLayer/SkipButton

@onready var jay: TextureRect = $Scene3/Jay1
@onready var roshni: TextureRect = $Scene3/Roshni1

# --- Cutscene Data ---
var dialogue_index = -1
var cutscene_finished = false
# An array of dictionaries to hold all dialogue data.
var dialogues = [
	{
		"character": "Jay",
		"text": "Whoa… look at this place. The museum’s huge!",
		"texture": "res://assets/CutSceneAssets/Jay/jayexcitedsurprised.png"
	},
	{
		"character": "Roshni",
		"text": "Yeah… and it’s been abandoned for, like, twenty years.",
		"texture": "res://assets/CutSceneAssets/Roshni/RoshniDefault.png"
	},
	{
		"character": "Jay",
		"text": "Are you sure we’ll find anything useful for our science project in there?",
		"texture": "res://assets/CutSceneAssets/Jay/JayDefault.png"
	},
	{
		"character": "Roshni",
		"text": "According to my research, this museum still has artifacts and old tech that could finally help your brain understand how light works.",
		"texture": "res://assets/CutSceneAssets/Roshni/RoshniThinking.png"
	},
	{
		"character": "Jay",
		"text": "According to my inner conscience, we’re in trouble. This place gives me the creeps.",
		"texture": "res://assets/CutSceneAssets/Jay/JayConfused.png"
	},
	{
		"character": "Roshni",
		"text": "Oh, come on! We’re not backing out now. Weren’t you the one bragging about being a “paranormal expert”? Ghost buster or something?",
		"texture": "res://assets/CutSceneAssets/Roshni/RoshniTeaching.png"
	},
	{
		"character": "Jay",
		"text": "(smirks) Yeah, you’re right… I have two hundred years of ghost-busting experience. Let’s do this.",
		"texture": "res://assets/CutSceneAssets/Jay/JayThumbsUp.png"
	}
]


func _ready():
	# Ensure AnimationPlayer is assigned.
	if animation_player == null:
		animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
		if animation_player == null:
			push_error("No AnimationPlayer found! Please assign one in the inspector.")
			return
			
	# Initial setup: Hide the dialogue UI until the first animation is done.
	canvas_layer.visible = false
	fade_effect.visible = true
	
	# Connect signals for buttons and animations.
	next_button.pressed.connect(_on_next_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	animation_player.animation_finished.connect(_on_animation_finished)
	
	get_tree().create_timer(1.0).timeout.connect(
		func(): 
			AudioManager.play_music(Constants.AUDIO.scary_music, 0.1, true, -5)
	)
	# Start the cutscene by playing the first animation.
	animation_player.play("1st_cutscene")


func _process(_delta):
	# This function constantly checks the animation state to stop it at precise points.
	if animation_player.is_playing() and animation_player.current_animation == "2nd_scene":
		var speed = animation_player.get_playing_speed()
		var pos = animation_player.current_animation_position

		# Stop when playing forward for Roshni at her position.
		if speed > 0 and pos >= 0.2425:
			animation_player.pause()
			animation_player.seek(0.2425, true) # Snap to exact position.

		# Stop when playing backward for Jay at his position.
		elif speed < 0 and pos <= 0.0:
			animation_player.pause()
			animation_player.seek(0.0, true) # Snap to exact position.


func _on_animation_finished(anim_name):
	# This function is called when any animation in the AnimationPlayer finishes.
	if anim_name == "1st_cutscene":
		# Now that the first cutscene is over, start the interactive dialogue part.
		animation_player.play("2nd_scene")
		animation_player.pause()
		animation_player.seek(0.0, true) # Set to Jay's starting position.
		
		canvas_layer.visible = true
		_update_dialogue() # Display the first line of dialogue.


func _update_dialogue():
	dialogue_index += 1
	if dialogue_index >= dialogues.size():
		_end_cutscene()
		return

	var current_dialogue = dialogues[dialogue_index]
	var character = current_dialogue["character"]
	
	# Update dialogue text with character name.
	dialogue_label.text = "%s: %s" % [character, current_dialogue["text"]]
	
	# --- MODIFICATION START ---
	# Check if a new texture is specified for this line.
	if current_dialogue.has("texture"):
		# Apply the texture to the correct character.
		if character == "Jay":
			jay.texture = load(current_dialogue["texture"])
		elif character == "Roshni":
			roshni.texture = load(current_dialogue["texture"])
	# --- MODIFICATION END ---
		
	# Animate to the speaking character's position.
	if character == "Roshni":
		# Play forward from Jay's position (0.0) to Roshni's (0.2425).
		animation_player.play("2nd_scene")
	elif character == "Jay":
		# For Jay's dialogues, play backwards from Roshni's position.
		# EXCEPTION: For the very first dialogue (index 0), we are already at 0.0,
		# so we don't need to play anything.
		if dialogue_index > 0:
			animation_player.play_backwards("2nd_scene")


func _end_cutscene():
	if cutscene_finished:
		return
	cutscene_finished = true
	
	canvas_layer.visible = false
	# Play the fade effect in reverse to fade out.
	# This assumes "Fade_Effect_Animation" is in the same AnimationPlayer.
	animation_player.play_backwards("Fade_Effect_Animation")
	await animation_player.animation_finished
	
	AudioManager.stop_music(1)
	# This call assumes you have an autoload script named "GameManager".
	GameManager.start_new_game()


# --- Signal Handlers ---

func _on_next_button_pressed():
	# Only advance the dialogue if the UI is visible and the cutscene isn't over.
	if canvas_layer.visible and not cutscene_finished:
		_update_dialogue()


func _on_skip_button_pressed():
	_end_cutscene()
