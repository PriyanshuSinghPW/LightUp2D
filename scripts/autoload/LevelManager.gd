extends Node

# A dictionary to hold information about each level.
# We can add more data later, like level names or time limits.
const LEVELS = {
    1: {"path": "res://scenes/levels/Level1.tscn"},
    2: {"path": "res://scenes/levels/Level2.tscn"},
    3: {"path": "res://scenes/levels/Level3.tscn"},
    4: {"path": "res://scenes/levels/Level4.tscn"},
    5: {"path": "res://scenes/levels/Level5.tscn"},
    6: {"path": "res://scenes/levels/Level6.tscn"},
    7: {"path": "res://scenes/levels/Level7.tscn"},
    8: {"path": "res://scenes/levels/Level8.tscn"}
}

# Returns the total number of levels defined.
func get_level_count() -> int:
    return LEVELS.size()

# Returns the scene file path for a given level index.
# Returns an empty string if the level doesn't exist.
func get_level_path(level_index: int) -> String:
    if LEVELS.has(level_index):
        return LEVELS[level_index]["path"]
    return ""
