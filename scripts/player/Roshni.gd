extends CharacterBody2D

# This script will control the character Roshni.
# For now, it will be a simple placeholder.

# We can add movement logic here later if Roshni needs to move,
# or logic to react when she is guided by the light.

func _physics_process(delta: float) -> void:
	# Placeholder for physics-based movement
	pass

func on_light_path_cleared() -> void:
	# This function could be called when a level is complete,
	# triggering an animation or dialogue from Roshni.
	print("Roshni: 'Thank you for lighting the way!'")
