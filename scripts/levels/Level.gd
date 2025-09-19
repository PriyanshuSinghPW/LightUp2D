extends Node2D

# Emitted when the level's objective is met
signal level_complete

# The target that needs to be illuminated
@export var light_target: Node2D

# The source of the light beam
@export var light_source: Node2D

var is_complete: bool = false

func _ready() -> void:
    # Check that required nodes are set
    if not light_target:
        push_error("Level.gd requires a 'light_target' to be set in the inspector.")
    if not light_source:
        push_error("Level.gd requires a 'light_source' to be set in the inspector.")

func check_win_condition() -> void:
    if is_complete:
        return

    # This is where the core logic will go.
    # We will need to check if the light beam from the source
    # is hitting the target.
    # For now, this is a placeholder.
    
    # Example logic (will be replaced):
    # if light_beam.is_colliding_with(light_target):
    #     is_complete = true
    #     emit_signal("level_complete")
    #     print("Level Complete!")
    pass

func _on_mirror_rotated() -> void:
    # When a mirror is rotated, we need to recalculate the light path
    # and check if the win condition is met.
    check_win_condition()
