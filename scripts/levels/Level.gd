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


func update_light_path() -> void:
    # Deactivate all beams in the pool to start fresh
    for beam in _beam_pool:
        beam.is_casting = false

    # Initial parameters for the first beam
    var current_origin = light_source.global_position
    var current_direction = light_source.global_transform.x # The red axis (right) is our forward direction

    for i in range(max_reflections):
        if i >= _beam_pool.size():
            break # Stop if we run out of beams in the pool

        var beam = _beam_pool[i]
        
        # Position and configure the current beam segment
        beam.global_position = current_origin
        beam.rotation = current_direction.angle()
        
        # IMPORTANT: Reset target_position before casting.
        # This ensures the raycast checks along its full potential length.
        beam.target_position.x = beam.max_length
        
        # Force an immediate physics update for the raycast
        beam.force_raycast_update()

        # Now that the collision is updated, we can activate the beam
        beam.is_casting = true

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
                var redirect_direction = mirror_node.get_redirect_direction()
                
                # --- Back-face Culling Logic ---
                # Use the dot product to see if the incoming beam is hitting the "back" of the mirror.
                # A dot product > 0 means the angles are similar (hitting the back).
                var dot_product = current_direction.dot(redirect_direction)
                if dot_product > 0.1: # Using a small threshold to avoid floating point errors
                    # Hit the back of the mirror, so the path ends here.
                    break
                # --- End of Logic ---

                # The new origin is the exact collision point...
                var new_origin = hit_point
                # ...plus a tiny push in the new direction to prevent instant re-collision.
                new_origin += redirect_direction * 0.1

                # Update parameters for the next beam segment
                current_origin = new_origin
                current_direction = redirect_direction
                
                # Continue to the next iteration to cast the redirected beam
                continue
            else:
                # Hit a non-mirror, non-target object, so the path ends
                break
        else:
            # The beam hit nothing, so the path ends
            break


func _on_mirror_rotated() -> void:
    # When a mirror is rotated, we recalculate the entire light path.
    update_light_path()
