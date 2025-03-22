class_name PreparationPlayerState extends PlayerState
## Mouse movement is disabled in this state, reset player & camera (about X-Axis) rotation,
## set position (done via game manager possibly), and display cards
## NOTE: Will probably be nice to display some transition animation or whatever here so its not so abrupt

## NOTE: Since we are taking 3 steps maybe each step can server a purpose:
## First step play defensive cards
## Second step play movement card
## Third for offensive card
## Not sure if this viable but just a thought

var is_moving: = false
var start_position := Vector3.ZERO
var target_distance := 1.0  # Distance to travel in units
var speed := 5.0  # Speed in units per second
var distance_traveled := 0.0

func handle_input(event: InputEvent):
	if event.is_action_pressed(&"prep"):
		transition.emit(&"GroundedPlayerState")
	elif event.is_action_pressed(&"proceed"):
		start_movement()

func enter(msg: Dictionary = {}) -> void:
	PLAYER.rotation = Vector3.ZERO
	%PlayerCamera3D.rotation = Vector3.ZERO
	print(PLAYER.team)
	# Reset movement variables when entering this state
	is_moving = false
	distance_traveled = 0.0

func physics_update(delta: float) -> void:
	if is_moving:
		# Set velocity in the negative Z direction (forward in Godot's default orientation)
		var direction = -PLAYER.transform.basis.z
		PLAYER.velocity = direction * speed
		
		# Apply the movement using CharacterBody3D's move_and_slide
		PLAYER.move_and_slide()
		
		# Calculate how far we've traveled from the starting point
		distance_traveled = start_position.distance_to(PLAYER.global_position)
		
		# Check if we've reached or exceeded the target distance
		if distance_traveled >= target_distance:
			# Stop moving
			is_moving = false
			PLAYER.velocity = Vector3.ZERO
			
			# Optionally, snap to the exact end position for precision
			PLAYER.global_position = start_position + direction.normalized() * target_distance
			
			# You could emit a signal or transition to another state here if needed
			# transition.emit(&"SomeOtherState")
func start_movement():
	is_moving = true
	start_position = PLAYER.global_position
	distance_traveled = 0.0
