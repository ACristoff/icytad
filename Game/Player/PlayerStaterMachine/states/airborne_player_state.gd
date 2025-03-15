class_name AirebornePlayerState extends PlayerState

func handle_input(event: InputEvent):
	PLAYER.update_mouse_motion(event)
	
func enter(msg: Dictionary = {}) -> void:
	if msg.get("jumped", false):
		PLAYER.jump()

func process_update(_delta: float) -> void:
	PLAYER.update_input()

func physics_update(delta: float) -> void:
	PLAYER.handle_crouch(delta)
	PLAYER.handle_air_physics(delta)
	PLAYER.update_velocity(delta)
	
	if PLAYER.is_on_floor():
		transition.emit(&"GroundedPlayerState")
