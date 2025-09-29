extends Node

# This script provides a simple way to test the GameManager and LevelManager
# without needing a full UI.

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        match event.keycode:
            # Press 'S' to start a new game
            KEY_S:
                print("TestRunner: 'S' pressed. Calling GameManager.start_new_game()")
                GameManager.start_new_game()
                get_viewport().set_input_as_handled()

            # Press 'N' to load the next level
            KEY_N:
                # Only works if we are currently in a level
                if GameManager.current_state == GameManager.GameState.PLAYING:
                    print("TestRunner: 'N' pressed. Calling GameManager.load_next_level()")
                    GameManager.load_next_level()
                    get_viewport().set_input_as_handled()
                else:
                    print("TestRunner: 'N' pressed, but not in PLAYING state. Ignoring.")

            # Press 'R' to reload the current level
            KEY_R:
                if GameManager.current_state == GameManager.GameState.PLAYING:
                    print("TestRunner: 'R' pressed. Calling GameManager.reload_current_level()")
                    GameManager.reload_current_level()
                    get_viewport().set_input_as_handled()
                else:
                    print("TestRunner: 'R' pressed, but not in PLAYING state. Ignoring.")
            
            # Press 'M' to go to the main menu
            KEY_M:
                print("TestRunner: 'M' pressed. Calling GameManager.go_to_main_menu()")
                GameManager.go_to_main_menu()
                get_viewport().set_input_as_handled()
