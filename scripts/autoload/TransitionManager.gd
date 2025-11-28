# This script is now a self-contained transition system.
# It is a CanvasLayer that manages its own ColorRect and shader animations.
extends CanvasLayer

# Signal to notify when the transition is fully complete
signal transition_finished

@export var transition_duration: float = 0.9
@export var edge_width: float = 0.06
@export var glow_intensity: float = 1.2
@export var distortion_amount: float = 2.0
@export var distortion_scale: float = 3.0
@export var dissolve_softness: float = 0.25
@export var noise_scroll: Vector2 = Vector2(0.2, 0.0)
@export var glow_color: Color = Color(1.0, 0.55, 0.1, 1.0)

# --- Children Nodes and Shader Resources ---
var color_rect: ColorRect
const BURN_SHADER = preload("res://assets/Shaders/burn_transition.gdshader")

# --- State Variables ---
var is_playing: bool = false

func _ready() -> void:
    # This node will persist across scene changes.
    process_mode = Node.PROCESS_MODE_ALWAYS

    # --- Create the UI programmatically ---
    # 1. Create the ColorRect that will cover the screen.
    color_rect = ColorRect.new()
    color_rect.anchor_right = 1.0
    color_rect.anchor_bottom = 1.0
    add_child(color_rect)

    # --- Create the noise texture ---
    var noise = FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
    noise.frequency = 0.05
    noise.fractal_octaves = 2

    var noise_texture = NoiseTexture2D.new()
    noise_texture.noise = noise
    
    # 2. Create and assign the shader material.
    var material = ShaderMaterial.new()
    material.shader = BURN_SHADER
    material.set_shader_parameter("progress", 0.0)
    material.set_shader_parameter("noise_texture", noise_texture)
    # Initialize other shader params
    material.set_shader_parameter("edge_width", edge_width)
    material.set_shader_parameter("glow_intensity", glow_intensity)
    material.set_shader_parameter("distortion_amount", distortion_amount)
    material.set_shader_parameter("distortion_scale", distortion_scale)
    material.set_shader_parameter("dissolve_softness", dissolve_softness)
    material.set_shader_parameter("noise_scroll", noise_scroll)
    material.set_shader_parameter("glow_color", glow_color)
    color_rect.material = material
    
    # 3. Hide the layer by default.
    visible = false

# --- Public API ---
func transition_to_scene(scene_path: String) -> void:
    if is_playing:
        return
    is_playing = true
    _start_burn(scene_path)

func _start_burn(scene_path: String) -> void:
    # Capture current frame AFTER a frame to ensure fully rendered
    await get_tree().process_frame
    var vp_tex := get_viewport().get_texture()
    if vp_tex == null:
        push_error("Viewport texture unavailable for burn capture")
        is_playing = false
        return
    var img := vp_tex.get_image()
    if img.is_empty():
        await get_tree().process_frame
        img = get_viewport().get_texture().get_image()
    var prev_tex := ImageTexture.create_from_image(img)
    color_rect.material.set_shader_parameter("prev_scene_texture", prev_tex)

    # Show layer with old scene snapshot
    color_rect.material.set_shader_parameter("progress", 0.0)
    visible = true

    # Change to new scene underneath
    var err = get_tree().change_scene_to_file(scene_path)
    if err != OK:
        push_error("Failed to change scene to: " + scene_path)
        is_playing = false
        visible = false
        return

    # Allow new scene to render at least one frame
    await get_tree().process_frame

    # Animate burn (old -> new)
    var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(color_rect.material, "shader_parameter/progress", 1.0, transition_duration)
    await tween.finished

    # Cleanup
    visible = false
    color_rect.material.set_shader_parameter("progress", 0.0)
    is_playing = false
    emit_signal("transition_finished")

func _notification(what):
    if what == NOTIFICATION_INTERNAL_PROCESS:
        # Keep shader params synced if tweaked in Inspector at runtime
        if color_rect and color_rect.material:
            color_rect.material.set_shader_parameter("edge_width", edge_width)
            color_rect.material.set_shader_parameter("glow_intensity", glow_intensity)
            color_rect.material.set_shader_parameter("distortion_amount", distortion_amount)
            color_rect.material.set_shader_parameter("distortion_scale", distortion_scale)
            color_rect.material.set_shader_parameter("dissolve_softness", dissolve_softness)
            color_rect.material.set_shader_parameter("noise_scroll", noise_scroll)
            color_rect.material.set_shader_parameter("glow_color", glow_color)

func _enter_tree():
    set_process_internal(true)
