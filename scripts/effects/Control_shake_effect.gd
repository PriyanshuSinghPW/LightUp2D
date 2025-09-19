extends Control

@export var shake_intensity: float = 5.0      # Subtle shake distance
@export var shake_speed: float = 1.5          # Lower = slower movement

var _original_position := Vector2.ZERO
var _noise := FastNoiseLite.new()
var _noise_offset := 0.0
var _current_shake := Vector2.ZERO

func _ready():
	_original_position = position
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 0.3                     # Lower frequency = smoother curves

func _process(delta):
	_noise_offset += delta * shake_speed

	# Smooth noise-based offset
	var target_x = _noise.get_noise_2d(_noise_offset, 0.0) * shake_intensity
	var target_y = _noise.get_noise_2d(0.0, _noise_offset) * shake_intensity
	var target_offset = Vector2(target_x, target_y)

	# Smooth interpolation between current and target offset
	_current_shake = _current_shake.lerp(target_offset, 0.1)

	position = _original_position + _current_shake
