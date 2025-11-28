extends Node2D

# Emitted when the level's objective is met
signal level_complete

# The target that needs to be illuminated
@export var light_target: Node2D
# The source of the light beam
@export var light_source: Node2D

const LightBeamScene = preload("res://scenes/game_elements/LightBeam.tscn")
@export var max_reflections = 10
var _beam_pool: Array[RayCast2D] = []

var is_complete: bool = false


func _ready() -> void:
    # Tell the GameManager that the level is loaded and we are ready to play.
    GameManager.set_state(GameManager.GameState.PLAYING)
    
    level_complete.connect(GameManager.level_was_completed)
    
    # Check that required nodes are set
    if not light_target:
        push_error("Level.gd requires a 'light_target' to be set in the inspector.")
    if not light_source:
        push_error("Level.gd requires a 'light_source' to be set in the inspector.")
        return

    # Populate the beam pool
    for i in range(max_reflections):
        var beam = LightBeamScene.instantiate()
        # We set the default state of the beams here
        beam.is_casting = false
        add_child(beam)
        _beam_pool.append(beam)
    
    # Initial light path calculation
    update_light_path()
    # Continuously update so dynamic objects (player) blocking the beam are handled.
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    # Recompute the beam path each frame so moving blockers (player) instantly cut it.
    update_light_path()


func update_light_path() -> void:
    # Mark all beams as unused; we will enable only those needed this frame.
    var used := []

    # Initial parameters for the first beam
    var current_origin = light_source.global_position
    var current_direction = light_source.global_transform.x # The red axis (right) is our forward direction

    for i in range(max_reflections):
        if i >= _beam_pool.size():
            break # Stop if we run out of beams in the pool

        var beam = _beam_pool[i]
        used.append(beam)

        # Activate if needed
        if not beam.is_casting:
            beam.is_casting = true

        # Position & orient
        beam.global_position = current_origin
        beam.rotation = current_direction.angle()

        # Cast full length first
        beam.target_position.x = beam.max_length
        beam.force_raycast_update()

        var hit_something = false
        var hit_normal = Vector2.ZERO
        var collider = null
        var mirror_node = null
        var reflected_direction = Vector2.ZERO

        # Check for collision
        if beam.is_colliding():
            hit_something = true
            collider = beam.get_collider()
            var hit_point = beam.get_collision_point()
            hit_normal = beam.get_collision_normal()
            
            # Stop the current beam at the hit point.
            var dist = beam.global_position.distance_to(hit_point)
            beam.target_position.x = dist

            # --- Robust Mirror Detection Logic ---
            if collider.has_method("get_redirect_direction"):
                mirror_node = collider
            elif collider.get_parent() and collider.get_parent().has_method("get_redirect_direction"):
                mirror_node = collider.get_parent()
            
            # Check if we hit the target FIRST
            if collider == light_target:
                if not is_complete:
                    if light_target.has_method("unlock_target"):
                        light_target.unlock_target()
                    is_complete = true
                    print("Light beam has hit the target!")
                # We hit the target, so we stop the beam chain here.
                # But we still want to update visuals for THIS beam.
                mirror_node = null # Ensure we don't reflect off the target
            
            # If we hit a mirror, calculate reflection for the NEXT beam
            if mirror_node:
                # --- Standard Reflection using the Flipped Visual Normal ---
                var visual_normal = mirror_node.get_redirect_direction()
                reflected_direction = -current_direction.reflect(visual_normal)

                # --- Corrected Back-face Culling ---
                var dot_product = current_direction.dot(visual_normal)
                if dot_product >= -0.1: 
                    # Hit the back of the mirror, so the path ends here.
                    mirror_node = null # Treat as non-mirror for logic below
                else:
                    # --- Update Angle UI ---
                    var angle_of_deflection = current_direction.angle_to(reflected_direction)
                    beam.update_angle_ui(rad_to_deg(angle_of_deflection), false)
                    
                    if i + 1 < _beam_pool.size():
                        var reflected_beam = _beam_pool[i + 1]
                        reflected_beam.update_angle_ui(rad_to_deg(reflected_direction.angle()), true)
                    
                    # Prepare next iteration
                    var new_origin = hit_point + reflected_direction * 0.1
                    current_origin = new_origin
                    current_direction = reflected_direction
        
        # Update the visuals and logic for this beam
        beam.update_beam_visuals(Vector2(beam.target_position.x, 0), hit_something, hit_normal)
        beam.handle_hit_logic(collider)

        # If we didn't hit a valid mirror (or hit nothing, or hit target), stop the chain
        if not mirror_node or not hit_something:
            break

    # Any beams not used this frame should be turned off.
    for beam in _beam_pool:
        if beam not in used and beam.is_casting:
            beam.is_casting = false


func _on_mirror_rotated() -> void:
    # When a mirror is rotated, we recalculate the entire light path.
    update_light_path()
