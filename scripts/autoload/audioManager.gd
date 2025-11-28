# AudioManager.gd
extends Node

# --- NODE REFERENCES ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player_pool_container: Node = $SFXPlayerPool
@onready var dialogue_player: AudioStreamPlayer = $DialoguePlayer

# --- CONFIG ---
const SFX_PLAYER_COUNT = 12
const SETTINGS_FILE_PATH = "user://audio_settings.cfg"

# --- INTERNAL STATE ---
var sfx_players: Array[AudioStreamPlayer] = []
var looping_sfx: Dictionary = {} # Tracks looping SFX -> {"path": player_node}
var master_volume_db: float = 0.0
var music_volume_db: float = 0.0
var sfx_volume_db: float = 0.0
var current_music_path: String = ""


func _ready():
    await ready
    
    process_mode = Node.PROCESS_MODE_ALWAYS
    music_player.bus = "Music"
    
    # Create dialogue player if it doesn't exist
    if not dialogue_player:
        dialogue_player = AudioStreamPlayer.new()
        dialogue_player.name = "DialoguePlayer"
        add_child(dialogue_player)
    dialogue_player.bus = "SFX"  # Use SFX bus for dialogues
    
    for i in SFX_PLAYER_COUNT:
        var sfx_player = AudioStreamPlayer.new()
        sfx_player.bus = "SFX"
        sfx_players.append(sfx_player)
        sfx_player_pool_container.add_child(sfx_player)
    
    load_settings()
    
    # --- Connect to ALL necessary GameManager signals ---
    #GameManager.level_started.connect(_on_level_started)
    #GameManager.delivery_timer_started.connect(_on_delivery_timer_started)
    #GameManager.delivery_succeeded.connect(_on_delivery_succeeded)
    #GameManager.delivery_failed.connect(_on_delivery_failed)
    #GameManager.level_results_ready.connect(_on_level_complete)
    
    # Connect to scene tree for scene change detection
    #if get_tree():
        #get_tree().tree_changed.connect(_on_scene_changed)
    #await get_tree().create_timer(0.01).timeout
    
    #play_music(Constants.AUDIO.starting_screen, 0.2, true, 1)
    
    print("Audio Manager is ready.")


# --- Scene Change Handler ---
#func _on_scene_changed():
    #"""Called when the scene tree changes. Used to detect scene transitions."""
    #var current_scene = get_tree().current_scene if get_tree() else null
    #if current_scene:
        ## If we're leaving a level scene, stop all music
        #if not "Level" in current_scene.scene_file_path:
            #stop_all_audio()


# --- Signal Handler Functions ---
#func _on_level_started(_level_number: int):
    #"""Called when a level begins. Plays the general background music."""
    #play_music(Constants.AUDIO.LevelBgm, 0.2, true, 0.0)  # Full volume
#
#func _on_delivery_timer_started(_allotted_time: float):
    #"""Called when a timed delivery starts. Plays the tense delivery music."""
    #play_music(Constants.AUDIO.Level1DeliveryMusic, 0.2, true, 0.0)  # Full volume
#
#func _on_delivery_succeeded(_delivery_data, _points):
    #"""Called on successful delivery. Plays success SFX and restores calm music."""
    #print("AudioManager: Delivery Succeeded.")
    #play_sfx(Constants.AUDIO.delivery_success)
    #play_music(Constants.AUDIO.LevelBgm, 0.2, true, 0.0)

#func _on_delivery_failed(_delivery_data):
    #"""Called on failed delivery. Plays fail SFX and restores calm music."""
    #print("AudioManager: Delivery Failed.")
    #play_sfx(Constants.AUDIO.delivery_fail)
    #play_music(Constants.AUDIO.LevelBgm, 0.2, true, 0.0)
#
#func _on_level_complete(_level_num, _score, _successes, _total):
    #"""Called when the entire level is finished. Stops music and plays fanfare."""
    #print("AudioManager: Level Complete.")
    #await stop_music(0.5)
    #play_sfx(Constants.AUDIO.level_complete)


# =============================================================================
# --- PUBLIC API ---
# =============================================================================

func play_music(music_path: String, fade_in_time: float = 0.2, loop: bool = false, volume_db: float = 0.0):
    """
    Plays music with specified parameters.
    volume_db: Volume adjustment in decibels. 0 = normal, -10 = quieter, 10 = louder
    """
    # Don't restart if it's the same music already playing
    if current_music_path == music_path and music_player.is_playing():
        # Just update the volume if needed
        music_player.volume_db = volume_db
        return
    
    if music_player.is_playing():
        await stop_music(0.5)
    
    if not ResourceLoader.exists(music_path):
        printerr("AudioManager: Music path not found: ", music_path)
        return

    var new_stream = load(music_path)
    if new_stream is AudioStream:
        # Set loop mode on the stream
        if new_stream is AudioStreamOggVorbis:
            new_stream.loop = loop
        elif new_stream is AudioStreamMP3:
            new_stream.loop = loop
        elif new_stream is AudioStreamWAV:
            if loop:
                new_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
            else:
                new_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
            
    music_player.stream = new_stream
    music_player.volume_db = -80  # Start silent for fade in
    music_player.play()
    current_music_path = music_path
    
    # Fade in to the target volume
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", volume_db, fade_in_time).from(-80)

func stop_music(fade_out_time: float = 1.0):
    current_music_path = ""
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", -80, fade_out_time)
    await tween.finished
    music_player.stop()

func play_dialogue(dialogue_path: String, volume_db: float = 0.0):
    """
    Plays a dialogue, stopping any previous dialogue.
    volume_db: Volume adjustment in decibels. 0 = normal, -10 = quieter, 10 = louder
    """
    # Stop any currently playing dialogue
    if dialogue_player.is_playing():
        dialogue_player.stop()
    
    if not ResourceLoader.exists(dialogue_path):
        printerr("AudioManager: Dialogue path not found: ", dialogue_path)
        return
    
    dialogue_player.stream = load(dialogue_path)
    dialogue_player.volume_db = volume_db
    dialogue_player.play()
    
    print("AudioManager: Playing dialogue - ", dialogue_path, " at volume: ", volume_db, "db")

func stop_dialogue():
    """Stops the currently playing dialogue."""
    if dialogue_player.is_playing():
        dialogue_player.stop()

func play_sfx(sfx_path: String, volume_db: float = 0.0):
    if not ResourceLoader.exists(sfx_path):
        printerr("AudioManager: SFX path not found: ", sfx_path)
        return
        
    var sfx_player = _get_available_sfx_player()
    if sfx_player:
        sfx_player.stream = load(sfx_path)
        sfx_player.volume_db = volume_db
        sfx_player.play()

func play_looping_sfx(sfx_path: String, volume_db: float = 0.0):
    if looping_sfx.has(sfx_path):
        return # Already playing

    if not ResourceLoader.exists(sfx_path):
        printerr("AudioManager: SFX path not found: ", sfx_path)
        return

    var sfx_player = _get_available_sfx_player()
    if sfx_player:
        var stream = load(sfx_path)
        # Ensure the audio stream is set to loop
        if stream is AudioStreamOggVorbis: stream.loop = true
        elif stream is AudioStreamMP3: stream.loop = true
        elif stream is AudioStreamWAV: stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        
        sfx_player.stream = stream
        sfx_player.volume_db = volume_db
        sfx_player.play()
        looping_sfx[sfx_path] = sfx_player # Track this player

func stop_looping_sfx(sfx_path: String):
    if looping_sfx.has(sfx_path):
        var sfx_player = looping_sfx[sfx_path]
        if sfx_player and sfx_player.is_playing():
            sfx_player.stop()
        looping_sfx.erase(sfx_path) # Stop tracking this player


func play_button_click():
    """Convenience function to play button click sound."""
    play_sfx(Constants.AUDIO.buttonCLick, -5.0)  # Slightly quieter for UI

func stop_all_audio():
    """Immediately stops all music and SFX."""
    print("AudioManager: Stopping all audio.")
    music_player.stop()
    dialogue_player.stop()
    current_music_path = ""
    
    for sfx_player in sfx_players:
        if sfx_player.is_playing():
            sfx_player.stop()

# Settings management (simplified)
func save_settings():
    var config = ConfigFile.new()
    config.set_value("audio", "master_volume_db", master_volume_db)
    config.set_value("audio", "music_volume_db", music_volume_db)
    config.set_value("audio", "sfx_volume_db", sfx_volume_db)
    var error = config.save(SETTINGS_FILE_PATH)
    if error != OK:
        printerr("AudioManager: Failed to save audio settings!")

func load_settings():
    var config = ConfigFile.new()
    var error = config.load(SETTINGS_FILE_PATH)
    
    if error == OK:
        master_volume_db = config.get_value("audio", "master_volume_db", 0.0)
        music_volume_db = config.get_value("audio", "music_volume_db", 0.0)
        sfx_volume_db = config.get_value("audio", "sfx_volume_db", 0.0)
        print("AudioManager: Loaded audio settings.")
    else:
        master_volume_db = 0.0
        music_volume_db = 0.0
        sfx_volume_db = 0.0
        print("AudioManager: No settings file found, using defaults.")
    
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_volume_db)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_volume_db)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_volume_db)

func _get_available_sfx_player() -> AudioStreamPlayer:
    for player in sfx_players:
        if not player.is_playing():
            return player
    return sfx_players[0]

func linear_to_db(linear_value: float) -> float:
    if linear_value <= 0.0001:
        return -80.0
    return 20 * log(linear_value) / log(10)

func db_to_linear(db_value: float) -> float:
    return pow(10, db_value / 20)
