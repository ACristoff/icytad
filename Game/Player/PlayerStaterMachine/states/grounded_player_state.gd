class_name GroundedPlayerState extends PlayerState

func handle_input(event: InputEvent):
	PLAYER.update_mouse_motion(event)
	
	if event.is_action_pressed(&"jump"):
		transition.emit(&"AirbornePlayerState", {"jumped": true})
		
	elif event.is_action_pressed(&"prep"):
		transition.emit(&"PreparationPlayerState")
		
	
func process_update(_delta: float) -> void:
	PLAYER.update_input()

func physics_update(delta: float) -> void:
	PLAYER.handle_crouch(delta)
	PLAYER.handle_ground_physics(delta)
	PLAYER.update_velocity(delta)
	
	if !PLAYER.is_on_floor():
		transition.emit(&"AirbornePlayerState")
