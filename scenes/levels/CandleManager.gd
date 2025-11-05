# CandleManager.gd
extends Node2D

# An array to store all the candle AnimatedSprite2D nodes
var candles = []

# Timers for flickering and random extinguishing
var flicker_timer = Timer.new()
var turn_off_timer = Timer.new()

# Assign your player in the Godot editor
@export var player: CharacterBody2D
# We no longer need the global interaction_ui export

var mobile_interact_pressed: bool = false


func _ready():
	# Populate the candles array and hide all their interaction texts
	for child in get_children():
		if child is AnimatedSprite2D:
			candles.append(child)
			
			# Find the local text label for this candle and hide it
			var light_up_text = child.get_node_or_null("LightUpText")
			if light_up_text:
				light_up_text.hide()

			# Ensure all lights are on at the start
			var light = child.get_node_or_null("PointLight2D")
			if light:
				light.enabled = "On" in child.animation

	# Configure and start the flicker timer
	flicker_timer.wait_time = 0.1
	flicker_timer.one_shot = false
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)
	add_child(flicker_timer)
	flicker_timer.start()

	# Configure and start the timer for random extinguishing
	turn_off_timer.wait_time = randf_range(10, 20)
	turn_off_timer.one_shot = false
	turn_off_timer.timeout.connect(_on_turn_off_timer_timeout)
	add_child(turn_off_timer)
	turn_off_timer.start()
		# NEW: Connect to the global interaction signal
	InputManager.interaction_button_pressed.connect(_on_interact)


func _process(delta):
	for candle in candles:
		var interaction_area = candle.get_node_or_null("Area2D")
		var light_up_text = candle.get_node_or_null("LightUpText")

		if not interaction_area or not light_up_text:
			continue

		var is_player_in_area = interaction_area.get_overlapping_bodies().has(player)
		var is_candle_off = "Off" in candle.animation
		
		# Store previous visibility to detect changes
		var was_visible = light_up_text.visible

		if is_player_in_area and is_candle_off:
			light_up_text.show()

			# MODIFIED: Check for keyboard OR our new mobile flag
			if Input.is_action_just_pressed("light") or mobile_interact_pressed:
				_light_up_candle(candle)
		else:
			light_up_text.hide()
			
		# NEW: Emit signals if visibility changed
		if light_up_text.visible and not was_visible:
			InputManager.emit_signal("show_interaction_button")
		elif not light_up_text.visible and was_visible:
			InputManager.emit_signal("hide_interaction_button")

	# NEW: Reset the flag at the end of the frame
	mobile_interact_pressed = false


func _on_interact() -> void:
	mobile_interact_pressed = true

func _on_flicker_timer_timeout():
	# Apply a flickering effect to all lit candles
	for candle in candles:
		if "On" in candle.animation:
			var light = candle.get_node_or_null("PointLight2D")
			if light and light.enabled:
				light.energy = randf_range(0.45, 0.5)
				var new_color = light.color
				new_color.a = randf_range(0.9, 1.0)
				light.color = new_color


func _on_turn_off_timer_timeout():
	# Select a random lit candle to extinguish
	var lit_candles = []
	for candle in candles:
		if "On" in candle.animation:
			lit_candles.append(candle)

	if not lit_candles.is_empty():
		var random_candle = lit_candles[randi() % lit_candles.size()]
		_turn_off_candle(random_candle)

	turn_off_timer.wait_time = randf_range(15, 30)


func _turn_off_candle(candle: AnimatedSprite2D):
	# Turn off the light
	var light = candle.get_node_or_null("PointLight2D")
	if light:
		light.enabled = false

	# Play the correct 'off' animation
	if candle.animation == "CandleFrontOn":
		candle.play("CandleFrontOff")
	elif candle.animation == "candleSideOn":
		candle.play("candleSideOff")


func _light_up_candle(candle: AnimatedSprite2D):
	# Turn on the light
	var light = candle.get_node_or_null("PointLight2D")
	if light:
		light.enabled = true

	# Play the correct 'on' animation
	if candle.animation == "CandleFrontOff":
		candle.play("CandleFrontOn")
	elif candle.animation == "candleSideOff":
		candle.play("candleSideOn")
