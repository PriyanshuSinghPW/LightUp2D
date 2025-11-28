# CandleManager.gd
extends Node2D

# An array to store candle data objects for faster access
var candles_data: Array[Dictionary] = []

# Timers for flickering and random extinguishing
var flicker_timer = Timer.new()
var turn_off_timer = Timer.new()

# Assign your player in the Godot editor
@export var player: CharacterBody2D

var mobile_interact_pressed: bool = false

# Track candles that are currently in range of the player
var candles_in_range: Array[Dictionary] = []

func _ready():
    # Populate the candles array and setup signals
    for child in get_children():
        if child is AnimatedSprite2D:
            var light = child.get_node_or_null("PointLight2D")
            var area = child.get_node_or_null("Area2D")
            var label = child.get_node_or_null("LightUpText")
            var notifier = child.get_node_or_null("VisibleOnScreenNotifier2D")
            
            if not area or not label:
                continue
                
            # Hide label initially
            label.hide()
            
            # Ensure light state matches animation
            if light:
                light.enabled = "On" in child.animation
                # OPTIMIZATION: Disable shadows on low-end devices automatically
                if OS.get_name() in ["Android", "iOS", "Web"]:
                    light.shadow_enabled = false
                
                # OPTIMIZATION: Culling
                if notifier:
                    notifier.screen_entered.connect(func(): light.visible = true)
                    notifier.screen_exited.connect(func(): light.visible = false)
                    # Set initial state
                    light.visible = notifier.is_on_screen()

            # Store references in a dictionary
            var candle_data = {
                "node": child,
                "light": light,
                "area": area,
                "label": label
            }
            candles_data.append(candle_data)
            
            # Connect signals for efficient proximity detection
            area.body_entered.connect(_on_candle_body_entered.bind(candle_data))
            area.body_exited.connect(_on_candle_body_exited.bind(candle_data))

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
    
    # Connect to the global interaction signal
    InputManager.interaction_button_pressed.connect(_on_interact)


func _process(_delta):
    # OPTIMIZATION: Only process input if there are candles in range
    if candles_in_range.is_empty():
        mobile_interact_pressed = false
        return

    # Check for interaction input once per frame
    var interact_requested = Input.is_action_just_pressed("light") or mobile_interact_pressed
    
    if interact_requested:
        for data in candles_in_range:
            var candle = data["node"]
            # Only light up if it's off
            if "Off" in candle.animation:
                _light_up_candle(data)
    
    # Reset the flag
    mobile_interact_pressed = false


func _on_candle_body_entered(body: Node2D, data: Dictionary):
    if body == player:
        candles_in_range.append(data)
        
        # Show label if candle is off
        var candle = data["node"]
        if "Off" in candle.animation:
            data["label"].show()
            InputManager.emit_signal("show_interaction_button")

func _on_candle_body_exited(body: Node2D, data: Dictionary):
    if body == player:
        candles_in_range.erase(data)
        
        # Hide label
        if data["label"].visible:
            data["label"].hide()
            InputManager.emit_signal("hide_interaction_button")


func _on_interact() -> void:
    mobile_interact_pressed = true

func _on_flicker_timer_timeout():
    # Apply a flickering effect to all lit candles
    # OPTIMIZATION: Calculate random values once and apply to all (or groups)
    # to save CPU cycles on random number generation.
    var base_energy = randf_range(0.45, 0.5)
    var base_alpha = randf_range(0.9, 1.0)
    
    for data in candles_data:
        var light = data["light"]
        # Only flicker if enabled AND visible on screen
        if light and light.enabled and light.visible:
            # Add a tiny variation so they don't look identical, but cheaper
            light.energy = base_energy
            var new_color = light.color
            new_color.a = base_alpha
            light.color = new_color


func _on_turn_off_timer_timeout():
    # Select a random lit candle to extinguish
    var lit_candles = []
    for data in candles_data:
        if "On" in data["node"].animation:
            lit_candles.append(data)

    if not lit_candles.is_empty():
        var random_data = lit_candles[randi() % lit_candles.size()]
        _turn_off_candle(random_data)

    turn_off_timer.wait_time = randf_range(15, 30)


func _turn_off_candle(data: Dictionary):
    var candle = data["node"]
    var light = data["light"]
    var label = data["label"]
    
    # Turn off the light
    if light:
        light.enabled = false

    # Play the correct 'off' animation
    if candle.animation == "CandleFrontOn":
        candle.play("CandleFrontOff")
    elif candle.animation == "candleSideOn":
        candle.play("candleSideOff")
        
    # If player is currently near this candle, show the label now that it's off
    if candles_in_range.has(data):
        label.show()
        InputManager.emit_signal("show_interaction_button")


func _light_up_candle(data: Dictionary):
    var candle = data["node"]
    var light = data["light"]
    var label = data["label"]

    # Turn on the light
    if light:
        light.enabled = true

    # Play the correct 'on' animation
    if candle.animation == "CandleFrontOff":
        candle.play("CandleFrontOn")
    elif candle.animation == "candleSideOff":
        candle.play("candleSideOn")
        
    # Hide the label since it's now on
    label.hide()
    
    # If this was the only candle in range, hide the button
    # (Logic is a bit simplified here, ideally we check if ANY other off candle is in range)
    var any_off_in_range = false
    for c in candles_in_range:
        if "Off" in c["node"].animation:
            any_off_in_range = true
            break
    
    if not any_off_in_range:
        InputManager.emit_signal("hide_interaction_button")
