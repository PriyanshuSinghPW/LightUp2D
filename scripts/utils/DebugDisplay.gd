# DebugDisplay.gd - FINAL RELIABLE VERSION
extends RichTextLabel

@export var debug_mode: bool = false

# We don't need to connect to signals if we are updating every frame.
# This makes the script simpler and more robust for debugging.

func _ready():
	# Enable BBCode parsing
	self.bbcode_enabled = true
	if debug_mode:
		self.show()
	
	# Anchor the label to the top of the screen
	anchor_right = 1.0
	offset_bottom = 100.0 # Give it some height

func _physics_process(_delta: float):
	# By calling update_display every frame, we guarantee the UI always
	# reflects the exact current state of the game managers.
	if debug_mode:
		update_display()

func update_display():
	# Add safety checks in case managers are not ready yet
	if not GameManager or not SequenceManager or not SequenceManager.current_sequence:
		self.text = "Waiting for Managers..."
		return
		
	# Define colors
	var label_color = "white"
	var value_color = "green"
	
	# Build the BBCode string
	var bbcode_text = ""
	
	var game_state = GameManager.GameState.keys()[GameManager.current_state]
	bbcode_text += "[color=%s]State: [/color][color=%s]%s[/color] | " % [label_color, value_color, game_state]
	
	bbcode_text += "[color=%s]Score: [/color][color=%s]%d[/color] | " % [label_color, value_color, GameManager.current_score]
	
	var history = SequenceManager.collected_numbers
	var last_four = history.slice(max(0, history.size() - 4))
	var history_string = ", ".join(last_four.map(func(n): return str(n)))
	bbcode_text += "[color=%s]History: [/color][color=%s][..., %s][/color] | " % [label_color, value_color, history_string]
	
	var target = SequenceManager.get_current_target()
	bbcode_text += "[color=%s]Target: [/color][color=%s]%d[/color]" % [label_color, value_color, target]
	
	var snake = get_tree().get_first_node_in_group("snake")
	if snake and is_instance_valid(snake):
		var speed = snake.get_speed()
		bbcode_text += " | [color=%s]Speed: [/color][color=%s]%.0f[/color]" % [label_color, value_color, speed]
	
	# Set the text. Using clear() and append_text() is correct for RichTextLabel.
	self.clear()
	self.append_text(bbcode_text)
