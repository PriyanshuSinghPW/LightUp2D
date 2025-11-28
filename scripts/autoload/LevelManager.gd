extends Node

# A dictionary to hold information about each level.
# We can add more data later, like level names or time limits.
const LEVELS = {
    # --- MODIFICATION START ---
    # Added a "bgm" key to store the path to the background music for each level.
    1: {"path": "res://scenes/levels/Level1.tscn", "bgm": "res://assets/audio/halloween-scary-music.mp3", "bgm_volume_db": -10.0},
    2: {"path": "res://scenes/levels/Level2.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    3: {"path": "res://scenes/levels/Level3.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    4: {"path": "res://scenes/levels/Level4.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    5: {"path": "res://scenes/levels/Level5.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    6: {"path": "res://scenes/levels/Level6.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    7: {"path": "res://scenes/levels/Level7.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"},
    8: {"path": "res://scenes/levels/Level8.tscn", "bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3"}
    # --- MODIFICATION END ---
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

# Returns an empty string if the level or BGM doesn't exist.
func get_level_bgm(level_index: int) -> String:
    if LEVELS.has(level_index) and LEVELS[level_index].has("bgm"):
        return LEVELS[level_index]["bgm"]
    return ""

func get_level_bgm_volume(level_index: int) -> float:
    if LEVELS.has(level_index) and LEVELS[level_index].has("bgm_volume_db"):
        return LEVELS[level_index]["bgm_volume_db"]
    return 0.0 # Default volume in decibels
