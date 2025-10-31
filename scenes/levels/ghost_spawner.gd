extends Node2D

## The Ghost scene to be spawned.
@export var ghost_scene: PackedScene
## The number of ghosts to spawn in total.
@export var total_ghosts_to_spawn: int = 10
## The number of ghosts to spawn at a time.
@export var ghosts_per_spawn: int = 2
## The delay between each spawn wave.
@export var spawn_interval: float = 5.0

var spawned_ghosts: int = 0
var spawn_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout",Callable(self,"_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	spawn_timer.start()
	# Spawn the first wave immediately
	_on_spawn_timer_timeout()

func _on_spawn_timer_timeout():
	# If the total number of ghosts has already been spawned, stop.
	if spawned_ghosts >= total_ghosts_to_spawn:
		spawn_timer.stop()
		return

	# --- START: CORRECTED LOGIC ---
	# Calculate how many ghosts to spawn in this specific wave.
	# It's either the full 'ghosts_per_spawn' amount, or the remaining number if it's less than a full wave.
	var ghosts_to_spawn_this_wave = min(ghosts_per_spawn, total_ghosts_to_spawn - spawned_ghosts)
	# --- END: CORRECTED LOGIC ---

	for i in range(ghosts_to_spawn_this_wave):
		if not ghost_scene:
			push_warning("Ghost scene is not set in the spawner!")
			return
			
		var ghost = ghost_scene.instantiate()
		ghost.global_position = self.global_position
		# It's better to add the ghost to the scene's main tree, not as a child of the spawner.
		get_tree().current_scene.add_child(ghost)
		spawned_ghosts += 1
