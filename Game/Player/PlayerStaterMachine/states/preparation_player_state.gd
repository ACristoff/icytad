class_name PreparationPlayerState extends PlayerState
## Mouse movement is disabled in this state, reset player & camera (about X-Axis) rotation,
## set position (done via game manager possibly), and display cards
## NOTE: Will probably be nice to display some transition animation or whatever here so its not so abrupt

func handle_input(event: InputEvent):
	if event.is_action_pressed(&"prep"):
		transition.emit(&"GroundedPlayerState")

func enter(msg: Dictionary = {}) -> void:
	PLAYER.rotation = Vector3.ZERO
	%PlayerCamera3D.rotation = Vector3.ZERO
	print(PLAYER.team)

func physics_update(delta: float) -> void:
	pass
