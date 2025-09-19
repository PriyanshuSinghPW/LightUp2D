# GameHUD.gd - FINAL CORRECTED VERSION
# This version correctly gets formatted text from the sequence object.
extends Control

@onready var score_label: RichTextLabel = $ScoreLabel/Score
@onready var pause_button: TextureButton = $PauseButton
@onready var sequence_label: RichTextLabel = $SequenceContainer/Sequence

var _display_sequence: Array = []

func _ready():
    GameManager.score_updated.connect(_on_score_updated)
    SequenceManager.sequence_started.connect(_on_sequence_started)
    SequenceManager.correct_number_collected.connect(_on_correct_number_collected)
    pause_button.pressed.connect(GameManager.toggle_pause)

func _on_score_updated(new_score: int):
    score_label.text = str(new_score)

func _on_sequence_started(data: Dictionary):
    score_label.text = "0"
    # This `preview` from the signal contains raw numbers (e.g., [1, 2, 3, 4])
    _display_sequence = data.get("preview", [])
    update_sequence_display()

func _on_correct_number_collected(number_value: int):
    # The signal sends the raw number collected (e.g., 5)
    _display_sequence.append(number_value)
    update_sequence_display()

func update_sequence_display():
    if _display_sequence.is_empty():
        sequence_label.text = "Sequence: ..."
        return
        
    # Safety check: make sure the sequence logic is ready before we ask for text.
    if not SequenceManager or not SequenceManager.current_sequence:
        return

    var display_items = _display_sequence.slice(max(0, _display_sequence.size() - 5))
    var string_items = []
    
    # --- THIS IS THE FIX ---
    # Instead of formatting the numbers ourselves, we ask the sequence object for the correct text.
    for item in display_items:
        var number_value = int(item) # Ensure we have a clean integer.
        
        # 1. Ask the current sequence for the correct display text for this number.
        var formatted_text = SequenceManager.current_sequence.get_display_text_for_value(number_value)
        
        # 2. Add the final text (e.g., "1H", or just "15") to our list.
        string_items.append(formatted_text)
    # --- END OF FIX ---
        
    var history_string = ", ".join(string_items)
    sequence_label.text = "Sequence: %s..." % history_string
