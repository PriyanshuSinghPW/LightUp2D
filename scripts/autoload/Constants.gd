# Constants.gd (Autoload)
# Contains default, fallback configuration values for the entire game.
# This script should have NO dependencies on other scripts.
extends Node

# --- Player Defaults ---
const PLAYER_DEFAULTS = {
	"speed": 300.0
}

# --- Game Defaults ---
# We can add more game-specific constants here later.
const GAME_DEFAULTS = {
	"level_width": 1280,
	"level_height": 720
}

const AUDIO = {
	"walksound" : "res://assets/audio/footsteps-on-wood-fast.mp3",
	"pushing" : "res://assets/audio/push-object.mp3",
	"gear_rotate" : "res://assets/audio/gear-click.mp3",
	"gear_rotate_single" : "res://assets/audio/gear-click-1.mp3",
	"halloween_music": "res://assets/audio/halloween-background-music.mp3",
	"scary_bgm": "res://assets/audio/halloween-horror-classical-bgm-4.mp3",
	"cloth_drop": "res://assets/audio/clothes-drop.mp3",
	"scary_music": "res://assets/audio/the-price-of-fear.mp3",
	"EDM": "res://assets/audio/intro-music-black-box-edm-sound.mp3"
}
