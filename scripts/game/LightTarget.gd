extends Area2D

var is_unlocked: bool = false

func _ready():
    # It's good practice to connect signals via code if you are manually changing node types
    # to avoid connections breaking in the editor.
    body_entered.connect(_on_body_entered)

func unlock_target():
    """Called by Levellightmanager when the light beam hits this target."""
    if not is_unlocked:
        is_unlocked = true
        print("LightTarget: Unlocked! Player can now proceed to the target.")
        # You could add a visual effect here, like an animation or color change,
        # to let the player know the target is active.

func _on_body_entered(body):
    """Called when another body enters this area."""
    # Check if the target is unlocked and if the body is the player.
    if is_unlocked and body.is_in_group("player"):
        print("LightTarget: Player has entered the unlocked target. Loading next level.")
        GameManager.load_next_level()
