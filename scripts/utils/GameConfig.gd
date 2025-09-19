# GameConfig.gd - UPGRADED VERSION
class_name GameConfig
extends RefCounted

var snake: Dictionary
var arena: Dictionary
var scoring: Dictionary
var spawner: Dictionary

func _init(json_data: Dictionary = {}):
	# Start with the defaults from Constants.gd
	snake = Constants.GAME_DEFAULTS.duplicate(true)
	arena = Constants.ARENA_DEFAULTS.duplicate(true)
	scoring = Constants.SCORING_DEFAULTS.duplicate(true)
	spawner = {} # Spawner has no defaults, it's fully JSON driven.

	# --- Override defaults with values from the loaded JSON ---
	
	# --- SNAKE CONFIG ---
	if json_data.has("snake"):
		var json_snake = json_data.snake
		# Convert normalized speed to pixels/sec
		# We'll use a conversion factor. 1.0 speed = 100 pixels/sec
		var speed_multiplier = 100.0
		snake.baseSpeed = json_snake.get("baseSpeed", 2.5) * speed_multiplier
		snake.speedPerCorrect = json_snake.get("speedPerCorrect", 0.05) * speed_multiplier
		snake.maxSpeed = json_snake.get("maxSpeed", 8.0) * speed_multiplier
		
		# These are direct copies
		snake.growthPerCorrect = json_snake.get("growthPerCorrect", 1)
		snake.initial_snake_length = json_snake.get("initial_snake_length", 4)
		
	# --- ARENA CONFIG ---
	if json_data.has("arena") and json_data.arena.has("bounds"):
		var json_bounds = json_data.arena.bounds
		# Convert normalized dimensions to pixel dimensions
		var base_resolution = Vector2(Constants.ARENA_DEFAULTS.width, Constants.ARENA_DEFAULTS.height)
		arena.width = json_bounds.get("width", 1.0) * base_resolution.x
		arena.height = json_bounds.get("height", 1.0) * base_resolution.y

	# --- SCORING & SPAWNER (These can be merged directly) ---
	if json_data.has("scoring"):
		scoring.merge(json_data.scoring, true)

	if json_data.has("spawner"):
		spawner.merge(json_data.spawner, true)
	
	print("✅ Game configuration initialized from detailed JSON.")
