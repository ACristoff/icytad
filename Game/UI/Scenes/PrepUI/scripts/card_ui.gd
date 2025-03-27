extends CanvasLayer
#@export var resourcetype : WeaponResource
## Maybe make this an autoload or something?
## Player passes in the amount of cards they have
## Steps: Fade in blur + background, place cards, click to highlight cards
## Use a button and a texture. Button same dimensions as texture, move texture up and down instead

## NOTE: Action Stack
## NOTE: 3 cards selected max, maybe increase actions per round

## move cards into place
## Bottom left corner, display cards in play
var cards : Dictionary[StringName, Array] = {}
var tween_stopped : bool = false
var max_card_selections : int = 3

## Set up a script to loop through the tree here and attach a signal listener to each
func _ready() -> void:
	SignalBus.test_prep.connect(_on_start_dealing)
	
	# Our children will be stuff like idle, walk, jump, fall, etc
	var index : int = 1
	for child in %Cards.get_children():
		## [int, Node, int, bool]
		## [index, child_node, position, selected]
		cards[child.name] = [index, child, index, false]
		# Connects signal to on_child_transition function, that will run when the signal is emitted
		child.mouse_entered.connect(_on_texture_button_mouse_entered.bind(child))
		child.mouse_exited.connect(_on_texture_button_mouse_exited.bind(child))
		child.toggled.connect(_on_texture_button_toggled.bind(child))
		
		#var notifier : Node = child.get_node("VisibleOnScreenNotifier2D")
		#notifier.screen_entered.connect(_on_screen_entered.bind(child))
		#notifier.screen_exited.connect(_on_screen_exited.bind(child))
		
		index = index + 1
	
	# Debug
	SignalBus.test_prep.emit()



func _physics_process(delta: float) -> void:
	pass

## Should be called only once
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"proceed"):
		_exist_tween()

func _on_start_dealing() -> void:
	%CardUIAnimationPlayer.play(&"fade_in")

## Maybe have the type of cards available play here?
## enable them all, on exit
func _enter_tween() -> void:
	tween_stopped = false
	var tween : Tween = create_tween()
	# Every tween after this will run in parallel
	tween.set_parallel()
	# Connecting tween finish signal to function
	tween.finished.connect(_on_tween_finished.bind(&"enter"))
	
	for key in cards.keys():
		cards[key][1].disabled = true
		var position_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[key][0]))
		var target_node : Node = cards[key][1]
		var target_position : Vector2 = _center_element(position_node.global_position, target_node.size)
		tween.tween_property(target_node, "global_position", target_position, 0.75) \
		.set_trans(Tween.TRANS_QUINT)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## I would like for this to make the first card go up, the next one go down, and repeat
## We can create multiple tweens if need be
## Disable them all, on exit
func _exist_tween() -> void:
	tween_stopped = false
	var tween : Tween = create_tween()
	tween.set_parallel()
	tween.finished.connect(_on_tween_finished.bind(&"exit"))
	
	#print(owner.action_stack)
	#print(selectedCard in owner.action_stack)
	
	for card in %Cards.get_children():
		## Disable all cards when they are exiting
		card.disabled = true
		
		if card in owner.action_stack:
			## Cards in the stack go up
			tween.tween_property(card, "global_position", Vector2.UP * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)
		else:
			## Cards not in the stack go down
			tween.tween_property(card, "global_position", Vector2.DOWN * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)
	
	#for key in cards.keys():
	#	var position_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[key][0]))
	#	if cards[key][2] % 2 != 0:
	#		tween.tween_property(cards[key][1], "global_position", Vector2.UP * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)
	#	else:
	#		tween.tween_property(cards[key][1], "global_position", Vector2.DOWN * 5000, 0.75).as_relative().set_trans(Tween.TRANS_QUINT)


#region Helper Functions
## Center Card elements to look nice
func _center_element(target_position : Vector2, element_size : Vector2) -> Vector2:
	return target_position + Vector2.UP * (element_size.y/2) + Vector2.LEFT * element_size.x/2
	
## Disables all the cards that are unselected
func _disable_unselected_cards() -> void:
	for card in %Cards.get_children():
		if card not in owner.action_stack:
			card.disabled = true
			
func _enable_or_disable_all_cards(selection : bool) -> void:
	# True = enabled, False = disable
	# Enable all cards
	if selection:
		for card in %Cards.get_children():
			card.disabled = false
	# Disable all cards
	else:
		for card in %Cards.get_children():
			card.disabled = true
#endregion


#region Signal Listeners

# Decicding what to do when our tweens finish
func _on_tween_finished(_message: StringName = &"Empty") -> void:
	if _message == &"exit":
		# There are no card tweens playing
		tween_stopped = true
		
		## Reset cards to spawn position
		#for key in cards.keys():
		#	cards[key][1].global_position = %Spawn.global_position
		
		%CardUIAnimationPlayer.play(&"fade_out")
		
	elif _message == &"enter":
		# There are no card tweens playing
		tween_stopped = true
		
		# After cards are in place, enable them all
		_enable_or_disable_all_cards(true)

## Fade out animation
func _on_card_ui_animation_player_animation_finished(anim_name: StringName) -> void:
	# Will move this to state machine later
	if anim_name == &"fade_out":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## We need to pass in the hovered node into this
## Shifts cards up a tad bit when hovered
func _on_texture_button_mouse_entered(textureButton : Node) -> void:
	if !textureButton.disabled:
		if tween_stopped == true:
			var tween : Tween = create_tween()
			var target_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[textureButton.name][0]))
			tween.tween_property(textureButton, "global_position", _center_element(target_node.global_position, textureButton.size) + Vector2.UP * 20, 0.1)

## Returns cards to original position after we stop hovering
func _on_texture_button_mouse_exited(textureButton : Node) -> void:
	if !textureButton.disabled:
		if tween_stopped == true:
			var tween : Tween = create_tween()
			var target_node : Node = get_node("Control/CenterContainer/CardPositionHbox/Position" + str(cards[textureButton.name][0]))
			tween.tween_property(textureButton, "global_position", _center_element(target_node.global_position, textureButton.size), 0.1)

# Populating action stack here
func _on_texture_button_toggled(toggled: bool, selectedCard : Node) -> void:
	# When we toggle a card
	if toggled:
		# Add it to the stack
		owner.action_stack.append(selectedCard)
		# If we have too many
		if owner.action_stack.size() >= max_card_selections:
			_disable_unselected_cards()
			
	# Remove selected card from action stack
	else:
		owner.action_stack.erase(selectedCard)
		# Enable all cards
		if owner.action_stack.size() < max_card_selections:
			_enable_or_disable_all_cards(true)
			
func _on_confirm_button_pressed() -> void:
	pass # Replace with function body.
	
#endregion
