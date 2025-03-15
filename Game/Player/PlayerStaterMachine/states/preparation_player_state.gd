class_name PreparationPlayerState extends PlayerState
## Mouse movement is disabled in this state, reset player & camera (about X-Axis) rotation,
## set position (done via game manager possibly), and display cards
## NOTE: Will probably be nice to display some transition animation or whatever here so its not so abrupt

## NOTE: Since we are taking 3 steps maybe each step can server a purpose:
## First step play defensive cards
## Second step play movement card
## Third for offensive card
## Not sure if this viable but just a thought


func handle_input(event: InputEvent):
	if event.is_action_pressed(&"prep"):
		transition.emit(&"GroundedPlayerState")
	elif event.is_action_pressed(&"proceed"):
		pass

func enter(msg: Dictionary = {}) -> void:
	PLAYER.rotation = Vector3.ZERO
	%PlayerCamera3D.rotation = Vector3.ZERO
	print(PLAYER.team)

func physics_update(delta: float) -> void:
	pass
