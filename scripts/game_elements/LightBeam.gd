@tool
extends RayCast2D

## Speed at which the laser extends when first fired, in pixels per seconds.
@export var cast_speed := 7000.0
## Maximum length of the laser in pixels.
@export var max_length := 1400.0
## Distance in pixels from the origin to start drawing and firing the laser.
@export var start_distance := 40.0
## Base duration of the tween animation in seconds.
@export var growth_time := 0.1
@export var color := Color.WHITE: set = set_color

## If `true`, the laser is firing.
## It plays appearing and disappearing animations when it's not animating.
## See `appear()` and `disappear()` for more information.
@export var is_casting := false: set = set_is_casting

var tween: Tween = null
var line_width : float = 20.0 # Default value for safety

@onready var line_2d: Line2D = %Line2D
@onready var casting_particles: GPUParticles2D = %CastingParticles2D
@onready var collision_particles: GPUParticles2D = %CollisionParticles2D
@onready var beam_particles: GPUParticles2D = %BeamParticles2D
@onready var angle_ui: Control = $AngleUI
@onready var direction_arrow: Sprite2D = $AngleUI/DirectionArrow
@onready var angle_label: Label = $AngleUI/AngleLabel


func _ready() -> void:
    # This check ensures nodes are ready before we use them
    if not is_node_ready():
        return

    line_width = line_2d.width
    set_color(color)
    set_is_casting(is_casting)
    
    line_2d.points[0] = Vector2.RIGHT * start_distance
    line_2d.points[1] = Vector2.ZERO
    line_2d.visible = false
    
    if casting_particles:
        casting_particles.position = line_2d.points[0]

    if not Engine.is_editor_hint():
        set_physics_process(false)


func _physics_process(delta: float) -> void:
    # Guard clause to prevent crashes in the editor
    if not is_node_ready() or line_2d == null:
        return

    target_position = target_position.move_toward(Vector2.RIGHT * max_length, cast_speed * delta)

    var laser_end_position := target_position
    force_raycast_update()

    if is_colliding():
        laser_end_position = to_local(get_collision_point())
        if collision_particles:
            collision_particles.global_rotation = get_collision_normal().angle()
            collision_particles.position = laser_end_position

    line_2d.points[1] = laser_end_position

    if beam_particles:
        var laser_start_position := line_2d.points[0]
        beam_particles.position = laser_start_position + (laser_end_position - laser_start_position) * 0.5
        var material = beam_particles.process_material
        if material is ParticleProcessMaterial:
            material.emission_box_extents.x = laser_end_position.distance_to(laser_start_position) * 0.5

    if collision_particles:
        collision_particles.emitting = is_colliding()


func update_angle_ui(angle_degrees: float, is_reflected: bool) -> void:
    if not angle_ui:
        return

    # Set the label text, formatted to one decimal place
    angle_label.text = "θ: %.1f°" % angle_degrees
    
    # The arrow sprite's rotation is relative to the beam's rotation.
    # It should always be 0 to point in the same direction as the beam.
    direction_arrow.rotation = 0
    
    # We can use the 'is_reflected' flag for other things, like changing the color
    # or sprite frame of the arrow, but not its rotation.
    if is_reflected:
        direction_arrow.modulate = Color.CYAN # Example: change color for reflected arrows
    else:
        direction_arrow.modulate = Color.WHITE # Default color
    
    # Make the UI visible
    angle_ui.visible = true


func set_is_casting(new_value: bool) -> void:
    if is_casting == new_value:
        return
    is_casting = new_value
    
    # Guard clause
    if not is_node_ready() or line_2d == null:
        return
        
    # Hide the UI when the beam is turned off
    if not new_value and angle_ui:
        angle_ui.visible = false
        
    set_physics_process(is_casting)

    if beam_particles:
        beam_particles.emitting = is_casting
    if casting_particles:
        casting_particles.emitting = is_casting

    if is_casting:
        var laser_start := Vector2.RIGHT * start_distance
        line_2d.points[0] = laser_start
        line_2d.points[1] = laser_start
        if casting_particles:
            casting_particles.position = laser_start
        appear()
    else:
        target_position = Vector2.ZERO
        if collision_particles:
            collision_particles.emitting = false
        disappear()


func appear() -> void:
    # Guard clause
    if line_2d == null:
        return
        
    line_2d.visible = true
    if tween and tween.is_running():
        tween.kill()
    tween = create_tween()
    tween.tween_property(line_2d, "width", line_width, growth_time * 2.0).from(0.0)


func disappear() -> void:
    # Guard clause
    if line_2d == null:
        return
        
    if tween and tween.is_running():
        tween.kill()
    tween = create_tween()
    tween.tween_property(line_2d, "width", 0.0, growth_time).from_current()
    tween.tween_callback(line_2d.hide)


func set_color(new_color: Color) -> void:
    color = new_color

    # Guard clause
    if not is_node_ready():
        return

    if line_2d:
        line_2d.modulate = new_color
    if casting_particles:
        casting_particles.modulate = new_color
    if collision_particles:
        collision_particles.modulate = new_color
    if beam_particles:
        beam_particles.modulate = new_color
