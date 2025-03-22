extends CanvasLayer

func _ready() -> void:
	var tween : Tween = create_tween()
	# Every tween after this will run in parallel
	tween.set_parallel()
	# Connecting tween finish signal to function
	tween.finished.connect(_on_tween_finished)
	
	tween.tween_property($Control/TextureRect, "global_position", $Control/Marker2D.global_position, 1.0).set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Control/TextureRect2, "global_position", $Control/Marker2D2.global_position, 1.0).set_trans(Tween.TRANS_QUINT)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"proceed"):
		var tween : Tween = create_tween()
		tween.set_parallel()
		
		tween.tween_property($Control/TextureRect, "position", Vector2.LEFT * 5000, 1).as_relative().set_trans(Tween.TRANS_QUINT)
		tween.tween_property($Control/TextureRect2, "position", Vector2.RIGHT * 5000, 1).as_relative().set_trans(Tween.TRANS_QUINT)

func _on_tween_finished() -> void:
	print("test")
