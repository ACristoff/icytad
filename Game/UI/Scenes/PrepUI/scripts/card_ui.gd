extends CanvasLayer
#@export var resourcetype : WeaponResource
## Maybe make this an autoload or something?
## Player passes in the amount of cards they have
## Steps: Fade in blur + background, place cards, click to highlight cards

## move cards into place
## Bottom left corner, display cards in play
var cards : Dictionary[StringName, Array] = {}

## Set up a script to loop through the tree here and attach a signal listener to each
func _ready() -> void:
	%CardUIAnimationPlayer.play(&"fade_in")
	# Our children will be stuff like idle, walk, jump, fall, etc
	var index : int = 1
	for child in %Cards.get_children():
		## [int, Node, int]
		## [index, child_node, position]
		cards[child.name] = [index, child, index]
		# Connects signal to on_child_transition function, that will run when the signal is emitted
		child.mouse_entered.connect(_on_texture_button_mouse_entered.bind(child))
		child.mouse_exited.connect(_on_texture_button_mouse_exited.bind(child))
		index = index + 1
	

## Maybe have the type of cards available play here?
func _enter_tween() -> void:
	var tween : Tween = create_tween()
	# Every tween after this will run in parallel
	tween.set_parallel()
	# Connecting tween finish signal to function
	tween.finished.connect(_on_tween_finished.bind(&"enter"))
	
	for key in cards.keys():
		var position_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[key][0]))
		var target_node : Node = cards[key][1]
		var target_position : Vector2 = _center_element(position_node.global_position, target_node.size)
		tween.tween_property(target_node, "global_position", target_position, 0.75) \
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
	for key in cards.keys():
		var position_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[key][0]))
		if cards[key][2] % 2 != 0:
			tween.tween_property(cards[key][1], "global_position", Vector2.UP * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)
		else:
			tween.tween_property(cards[key][1], "global_position", Vector2.DOWN * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)


#region Helper Functions
func _center_element(target_position : Vector2, element_size : Vector2) -> Vector2:
	return target_position + Vector2.UP * (element_size.y/2) + Vector2.LEFT * element_size.x/2
#endregion


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

## We need to pass in the hovered node into this
func _on_texture_button_mouse_entered(textureButton : Node) -> void:
	print("Hover")
	var tween : Tween = create_tween()
	var target_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[textureButton.name][0]))
	tween.tween_property(textureButton, "global_position", _center_element(target_node.global_position, textureButton.size) + Vector2.UP * 20, 0.1)

func _on_texture_button_mouse_exited(textureButton : Node) -> void:
	print("No hover")
	var tween : Tween = create_tween()
	var target_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[textureButton.name][0]))
	tween.tween_property(textureButton, "global_position", _center_element(target_node.global_position, textureButton.size), 0.1)

#endregion
