# NodeShake.gd
# A reusable component to shake any Node2D for a specific duration.
extends Node2D

var _original_position := Vector2.ZERO
var _is_shaking: bool = false
var _shake_intensity: float = 0.0

var _noise := FastNoiseLite.new()
var _noise_offset_x: float = 0.0
var _noise_offset_y: float = 0.0

@onready var _shake_timer: Timer = Timer.new()

func _ready():
	# Store the starting position so we can always return to it.
	_original_position = position
	
	# Configure the noise for a random but smooth shake.
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 2.0 # Higher frequency = more jittery

	# We create the timer in code so this component is self-contained.
	add_child(_shake_timer)
	_shake_timer.one_shot = true
	_shake_timer.timeout.connect(_on_shake_timer_timeout)
	
	# Disable processing by default to save performance.
	set_process(false)

func _process(delta):
	if not _is_shaking:
		return
	
	# Use time to move through the noise map, creating movement.
	_noise_offset_x += delta * 25 # Speed of x-axis shake
	_noise_offset_y += delta * 25 # Speed of y-axis shake

	# Get two different noise values for X and Y.
	var offset_x = _noise.get_noise_1d(_noise_offset_x) * _shake_intensity
	var offset_y = _noise.get_noise_1d(_noise_offset_y + 5000.0) * _shake_intensity # Add large number for a different noise value

	# Apply the shake offset to the original position.
	position = _original_position + Vector2(offset_x, offset_y)


### --- PUBLIC API --- ###

# Call this function from another script to start the shake.
func start_shake(duration: float, intensity: float):
	# Don't start a new shake if one is already active.
	if _is_shaking:
		return
		
	print("Shake Started! Duration: %s, Intensity: %s" % [duration, intensity])
	_shake_intensity = intensity
	_is_shaking = true
	
	# Start the countdown timer.
	_shake_timer.start(duration)
	
	# Enable the _process loop.
	set_process(true)


### --- SIGNAL CALLBACK --- ###

func _on_shake_timer_timeout():
	print("Shake Ended.")
	_is_shaking = false
	
	# IMPORTANT: Reset the position back to the original.
	position = _original_position
	
	# Disable the _process loop until it's needed again.
	set_process(false)
