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
    
    # Connect the level complete signal to the GameManager.
    # When this level emits 'level_complete', the GameManager will change the state.
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
    # We do NOT immediately set is_casting=false to avoid restarting animations each frame.
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

        # Check for collision
        if beam.is_colliding():
            var collider = beam.get_collider()
            var hit_point = beam.get_collision_point()
            
            # Stop the current beam at the hit point.
            beam.target_position.x = beam.global_position.distance_to(hit_point)

            # --- Robust Mirror Detection Logic ---
            var mirror_node = null
            if collider.has_method("get_redirect_direction"):
                mirror_node = collider
            elif collider.get_parent() and collider.get_parent().has_method("get_redirect_direction"):
                mirror_node = collider.get_parent()
            # --- End of Logic ---

            # Check if we hit the target FIRST
            if collider == light_target:
                if not is_complete:
                    is_complete = true
                    emit_signal("level_complete")
                    print("Level Complete!")
                break # Stop the loop, we won!

            # Now, check if we found a valid mirror node
            if mirror_node:
                # --- Standard Reflection using the Flipped Visual Normal ---
                # 1. Get the visually-opposite normal vector from the mirror.
                var visual_normal = mirror_node.get_redirect_direction()

                # 2. Use Godot's built-in 'reflect' method. By using the flipped
                #    visual_normal, the reflection will be calculated for the correct quadrant.
                var reflected_direction = -current_direction.reflect(visual_normal)

                # --- Corrected Back-face Culling ---
                # A ray hits the front-face if its direction is opposite to the visual_normal.
                # Their dot product will be negative.
                var dot_product = current_direction.dot(visual_normal)
                if dot_product >= -0.1: # Use a small negative threshold
                    # Hit the back of the mirror, so the path ends here.
                    break
                # --- End of Culling ---

                # --- Update Angle UI ---
                # The angle to display is the angle between the incident ray and the reflected ray.
                var angle_of_deflection = current_direction.angle_to(reflected_direction)
                
                # a. Update the incident beam's UI.
                beam.update_angle_ui(rad_to_deg(angle_of_deflection), false)
                
                # b. Update the reflected beam's UI.
                if i + 1 < _beam_pool.size():
                    var reflected_beam = _beam_pool[i + 1]
                    reflected_beam.update_angle_ui(rad_to_deg(reflected_direction.angle()), true)
                # --- End of UI Update ---

                # The new origin is the exact collision point...
                var new_origin = hit_point
                # ...plus a tiny push in the new direction to prevent instant re-collision.
                new_origin += reflected_direction * 0.1

                # Update parameters for the next beam segment
                current_origin = new_origin
                current_direction = reflected_direction
                
                # Continue to the next iteration to cast the redirected beam
                continue
            else:
                # Hit a non-mirror, non-target object. Clean up the rest of the beam path.
                for j in range(i + 1, _beam_pool.size()):
                    if _beam_pool[j] in used:
                        continue
                    _beam_pool[j].is_casting = false
                break
        else:
            # The beam hit nothing. Clean up the rest of the beam path.
            for j in range(i + 1, _beam_pool.size()):
                if _beam_pool[j] in used:
                    continue
                _beam_pool[j].is_casting = false
            break

    # Any beams not used this frame should be turned off.
    for beam in _beam_pool:
        if beam not in used and beam.is_casting:
            beam.is_casting = false


func _on_mirror_rotated() -> void:
    # When a mirror is rotated, we recalculate the entire light path.
    update_light_path()
