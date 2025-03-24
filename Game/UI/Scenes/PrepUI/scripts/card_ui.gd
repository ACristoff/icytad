extends CanvasLayer
## Maybe make this an autoload or something?
## Player passes in the amount of cards they have
## Steps: Fade in blur + background, place cards, click to highlight cards

## move cards into place
## Bottom left corner, display cards in play
func _ready() -> void:
	%CardUIAnimationPlayer.play(&"fade_in")

## Maybe have the type of cards available play here?
func _enter_tween() -> void:
	var tween : Tween = create_tween()
	# Every tween after this will run in parallel
	tween.set_parallel()
	# Connecting tween finish signal to function
	tween.finished.connect(_on_tween_finished.bind(&"enter"))
	
	tween.tween_property($Control/TextureButton, "global_position", _center_element($Control/CenterContainer/CardPositionHbox/Position1.global_position, $Control/TextureButton.size), 0.75)\
	.set_trans(Tween.TRANS_QUINT)
	
	tween.tween_property($Control/TextureButton2, "global_position", _center_element($Control/CenterContainer/CardPositionHbox/Position2.global_position, $Control/TextureButton2.size), 0.75)\
	.set_trans(Tween.TRANS_QUINT)
	
	tween.tween_property($Control/TextureButton3, "global_position", _center_element($Control/CenterContainer/CardPositionHbox/Position3.global_position, $Control/TextureButton3.size), 0.75)\
	.set_trans(Tween.TRANS_QUINT)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Should be called only once
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"proceed"):
		_exist_tween()

## I would like for this to make the first card go up, the next one go down, and repeat
## We can create multiple tweens if need be
func _exist_tween() -> void:
	var tween : Tween = create_tween()
	tween.set_parallel()
	tween.finished.connect(_on_tween_finished.bind(&"exit"))
		
	tween.tween_property($Control/TextureButton, "global_position", Vector2.UP * 5000, .75).as_relative().set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Control/TextureButton2, "global_position", Vector2.DOWN * 5000, .75).as_relative().set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Control/TextureButton3, "global_position", Vector2.UP * 5000, .75).as_relative().set_trans(Tween.TRANS_QUINT)

func _center_element(target_position : Vector2, element_size : Vector2) -> Vector2:
	return target_position + Vector2.UP * (element_size.y/2) + Vector2.LEFT * element_size.x/2


#region Signal Listeners
func _on_tween_finished(_message: StringName = &"Empty") -> void:
	if _message == &"exit":
		%CardUIAnimationPlayer.play(&"fade_out")

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	print("on_screen")

func _on_card_ui_animation_player_animation_finished(anim_name: StringName) -> void:
	# Will move this to state machine later
	if anim_name == &"fade_out":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#endregion
