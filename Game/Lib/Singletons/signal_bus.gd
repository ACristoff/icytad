extends Node
# Prep, draw, combat
#Turn off unused signal warning in project to get rid of the dumb warnings
#I KNOW WHAT IM DOING GODOT HECK OFF

var difficulty : String

# Signal that will be triggered when game pauses
signal pause_game

# Signal that will be triggered when game pauses
## Lets use this to test card prep phase really quick
signal game_state_changed(new_state)
signal test_prep()

# Signal that will be triggered when dialogue starts
signal dialogue_triggered(dialogue_data : Dictionary)

# Signal that will be emitted when dialogue is complete
signal dialogue_finished

#signal difficulty_selected(diff)
signal transition_start

signal transition_finished

signal finish_transition
