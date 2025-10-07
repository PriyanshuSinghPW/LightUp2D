extends Area2D

## Signal emitted when the light beam hits this target.
signal unlocked

## Signal emitted when the player enters the unlocked target.
signal player_entered

var is_unlocked: bool = false


func _ready():
    add_to_group("light_target")
    body_entered.connect(_on_body_entered)


func unlock_target():
    """Called by another script (e.g., Levellightmanager) to unlock this target."""
    if not is_unlocked:
        is_unlocked = true
        print("LightTarget: Unlocked!")
        unlocked.emit()


func _on_body_entered(body):
    """Called when a body enters this area."""
    if is_unlocked and body.is_in_group("player"):
        print("LightTarget: Player has entered the unlocked target.")
        player_entered.emit()
