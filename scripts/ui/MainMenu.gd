extends CanvasLayer

# Assuming your play button is named "PlayButton" in the MainMenu.tscn scene.
@onready var play_button: TextureButton =  $Control/StartingScreen/ButtonsContainer/PlayButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var light_up_logo: TextureRect = $"Control/StartingScreen/LightUp logo"

# --- IMPORTANT: Load the new logo-specific shader ---
const BURN_LOGO_SHADER = preload("res://assets/Shaders/burn_logo.gdshader")

func _ready():
    if animation_player:
        animation_player.play("MainMenu_Animation")
    else:
        push_warning("No AnimationPlayer found! Please assign one in the inspector.")
    if play_button:
        play_button.pressed.connect(_on_play_button_pressed)
    else:
        push_error("MainMenu.gd: Could not find a node named 'PlayButton'. Please check the node name and path in MainMenu.tscn.")
        
    AudioManager.play_music(Constants.AUDIO.halloween_music, 0.1, true, -10)

func _on_play_button_pressed():
    # Disable the play button to prevent multiple clicks
    play_button.disabled = true

    # Play the click animation
    if animation_player:
        animation_player.play("Play_Click_Animation")
        # Wait for the animation to finish
        await animation_player.animation_finished

    # --- Burn the Logo ---
    # 1. Create the shader material
    var material = ShaderMaterial.new()
    material.shader = BURN_LOGO_SHADER
    
    # 2. Set up the noise texture needed by the shader
    var noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
    noise.frequency = 0.05
    noise.fractal_octaves = 2
    var noise_texture = NoiseTexture2D.new()
    noise_texture.noise = noise
    material.set_shader_parameter("noise_texture", noise_texture)

    # 3. Initialize the 'progress' parameter before tweening to avoid errors
    material.set_shader_parameter("progress", 0.0)
    
    # 4. Apply the material to the logo
    light_up_logo.material = material

    # 5. Create a tween to animate the shader's progress from 0.0 to 1.0
    var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(material, "shader_parameter/progress", 1.0, 2.5) # Animate over 1.5 seconds
    
    # Wait for the burn animation to complete
    await tween.finished
    
    AudioManager.stop_music(1)
    # --- Change Scene ---
    get_tree().change_scene_to_file("res://scenes/CutScenes/CutScene1.tscn")
