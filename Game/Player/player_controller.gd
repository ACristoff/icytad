class_name Player extends CharacterBody3D

#region Constants
const CROUCH_TRANSLATE: float = 0.7
const CROUCH_JUMP_ADD: float = CROUCH_TRANSLATE * 0.9

## For setting visibility layer for view and world models
const WORLD_MODEL_LAYER = 2
const VIEW_MODEL_LAYER = 3
#endregion

#region Enums
enum PlayerTeam {
	RED,
	BLUE
}
#endregion

#region Exports
# Player Stats
@export_group("Player Stats")
@export var team: PlayerTeam = PlayerTeam.RED:
	set(v):
		team = v

@export var health: int = 100


# Camera Settings
@export_group("Camera Settings")
@export var PITCH_MIN: float = -90:
	get: return deg_to_rad(PITCH_MIN)
	set(value): PITCH_MIN = value

@export var PITCH_MAX: float = 90:
	get: return deg_to_rad(PITCH_MAX)
	set(value): PITCH_MIN = value
	
# Mouse Settings
@export_group("Mouse Settings")
@export_range(0.0001, 0.02, 0.0001) var MOUSE_SENSITIVITY: float = 0.004
#endregion

#region Regular Variables
# 1 =  no invert, -1 = invert
var invert_mouse : int = 1

# Movement State
var is_crouched : bool = false
#endregion

#region Onready Variables
@onready var original_capsule_height : float = %CharacterCollision.shape.height
@onready var jump_velocity: float = (2.0 * jump_height) / jump_time_to_peak
@onready var jump_gravity: float = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
#endregion

#region Default Functions
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_view_and_world_model_masks()

## NOTE: Debugging purposes
func _input(event) -> void:
	if event.is_action_pressed(&"exit"):
		get_tree().quit()

func _process(delta: float) -> void:
	# Get the smoothly interpolated transform of the player for this frame
	# This helps prevent jerky camera movement between physics updates
	# EX: Character moves at 60 FPS but a render rate of 240 would cause things to look jittery
	var global_interpolated_transform: Transform3D = get_global_transform_interpolated()
	
	# Update weapon recoil effects
	update_recoil(delta)
#endregion


#region State Machine Function and Variables
@export_group("Movement Settings")

@export_subgroup("Grounded (Walking)")
## Max speed we are allowed to walk while on the ground.
@export var walk_speed: float = 12.0
## How quickly to accelerate while on the ground.
@export var ground_accel: float = 20.0
## How quickly to decelerate while on the ground.
@export var ground_decel: float = 10.0

@export_subgroup("Airborne")
@export var air_acceleration: float = 800.0

@export_subgroup("Jumping and Gravity")
@export var gravity: float = 20.0
@export var jump_height: float = 1.5
@export var jump_time_to_peak: float = 0.45

## Controls how fast we can ascend
@export var max_ascension_speed : float = 5000

## Controls how fast we fall
@export var max_fall_speed : float = -50.0

var movement_direction : Vector3 = Vector3.ZERO

## Updates keyboard input
func update_input() -> void:
	var input_dir : Vector2 = Input.get_vector("left", "right", "up", "down").normalized()
	movement_direction = global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)

## Handles mouse motion input
func update_mouse_motion(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the character left or right about the Y-AXIS
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Calculate the potential new rotation before applying it
		var new_rotation_x : float = %PlayerCamera3D.rotation.x - event.relative.y * MOUSE_SENSITIVITY * invert_mouse
		## TODO: Apply this up and down rotation to character spine so it makes it look like they are looking up
		# Clamp the new rotation.
		# Rotating camera up and down about the X-Axis
		new_rotation_x = clamp(new_rotation_x, PITCH_MIN, PITCH_MAX)
		# Apply the clamped rotation
		%PlayerCamera3D.rotation.x = new_rotation_x

	
func update_velocity(delta) -> void:
	_push_away_rigid_bodies()
	move_and_slide()

func handle_ground_physics(delta : float) -> void:
	if movement_direction:
		velocity = velocity.lerp(movement_direction * 5, 5 * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 5 * delta)
	
func handle_air_physics(delta : float) -> void:
	# Apply gravity by reducing vertical velocity over time
	# This creates the falling effect
	velocity.y -= gravity * delta
	velocity.y = clamp(velocity.y, max_fall_speed, max_ascension_speed)

# We can always have a default fall gravity
func jump(new_jump_height: float = jump_height, new_jump_time_to_peak: float = jump_time_to_peak) -> void:
	# Update jump parameters
	jump_height = new_jump_height
	jump_time_to_peak = new_jump_time_to_peak
	
	# Calculate jump physics
	jump_velocity = (2.0 * jump_height) / jump_time_to_peak
	jump_gravity = (-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	
	# Apply jump velocity
	velocity.y = jump_velocity

func take_damage(damage : int) -> void:
	health -= damage

func handle_crouch(delta: float) -> void:
	# Keep track of the previous frame's crouch state to detect state changes
	# This is important for handling crouch jumps
	var was_crouched_last_frame: bool = is_crouched
	
	# Enter crouch state when the crouch button is held
	if Input.is_action_pressed(&"crouch"):
		is_crouched = true
	# Try to stand up if we're crouched and there's nothing above us
	# test_move checks if we can move up by CROUCH_TRANSLATE units without hitting anything
	elif is_crouched and not test_move(transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouched = false
	
	# Handle special case of changing crouch state while in the air (crouch jumping)
	var translate_y_if_possible: float = 0.0
	# Only apply crouch jump if the crouch state changed this frame, we're in the air,
	# and we haven't just snapped to stairs
	if was_crouched_last_frame != is_crouched and not is_on_floor():
		# Add upward force when crouching, downward when uncrouching
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
		
	# Apply the crouch jump movement if needed
	if translate_y_if_possible != 0.0:
		# Test how far we can actually move without hitting something
		var result: KinematicCollision3D = KinematicCollision3D.new()
		test_move(transform, Vector3(0, translate_y_if_possible, 0), result)
		# Move the character's position by the allowed amount
		position.y += result.get_travel().y
		# Move the head in the opposite direction to maintain camera height
		%Head.position.y -= result.get_travel().y
		# Ensure head position stays within valid crouch range
		%Head.position.y = clampf(%Head.position.y, -CROUCH_TRANSLATE, 0)
		
	# Smoothly interpolate the head position between standing and crouching heights
	# move_toward provides smooth transition at a rate of 7.0 units per second
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouched else 0.0, 7.0 * delta)
	
	# Update collision shape heights based on crouch state
	# Subtract CROUCH_TRANSLATE from original height when crouched
	%CharacterCollision.shape.height = original_capsule_height - (CROUCH_TRANSLATE if is_crouched else 0.0)
	
	# Move collision shapes to their new centers after height change
	# This ensures the character stays grounded and collision detection remains accurate
	%CharacterCollision.position.y = %CharacterCollision.shape.height / 2
	
#endregion

#region Recoil and Spread
const RECOIL_APPLY_SPEED : float = 10.0     # The rate at which current rotation/spread approaches the target.
const RECOIL_RECOVER_SPEED : float = 7.0    # The rate at which target rotation/spread returns to neutral.

var target_rotation : Quaternion = Quaternion.IDENTITY  ## The desired rotational state caused by recoil, starting with no rotation.
var current_rotation : Quaternion = Quaternion.IDENTITY ## Tracks the current rotational state, starting with no rotation.
var target_spread : Vector2 = Vector2.ZERO              ## The desired spread (e.g., bullet inaccuracy) caused by recoil, starting at zero.
var current_spread : Vector2 = Vector2.ZERO             ## Tracks the current spread value being applied, starting at zero.

var target_position : Vector3 = Vector3.ZERO
var current_position : Vector3 = Vector3.ZERO

# He makes a good point on keeping this recoil stuff here in the player controller
# I want to Probably just keep it here for now
# For now just get weapon_manager. current weapon.cam recoil
func add_recoil_spread(pitch: float, yaw: float, roll: float, sx: float, sy: float, kx: float, ky: float, kz: float) -> void:
	# Create a quaternion from Euler angles (in radians).
	# Converts pitch (x-axis), yaw (y-axis), and roll (z-axis) into a rotation quaternion.
	# var recoil_rotation : Quaternion = Quaternion.from_euler(Vector3(pitch, yaw, roll))
	
	# Multiply the current target rotation quaternion with the new recoil quaternion.
	# This combines the new recoil rotation with the existing target rotation.
	target_rotation = target_rotation * Quaternion.from_euler(Vector3(pitch, yaw, roll))
	
	# Add the new spread values (x and y) to the current target spread.
	# Increases bullet inaccuracy caused by recoil.
	target_spread.x += sx
	target_spread.y += sy
	
	target_position.x += kx
	target_position.y += ky
	target_position.z += kz

func update_recoil(delta: float) -> void:
	# Smoothly interpolate the target rotation back to the identity quaternion (no rotation).
	# This simulates recoil recovery over time, reducing the target rotation to neutral.
	target_rotation = target_rotation.slerp(Quaternion.IDENTITY, RECOIL_RECOVER_SPEED * delta)
	
	# For kick back calculation
	# Could probably just set the weapon to that position whenever you fire, and then lerp back immediately if we are doing it for a slow rate of fire weapon
	# idk
	target_position = target_position.lerp(Vector3.ZERO, RECOIL_RECOVER_SPEED * delta)
	current_position = current_position.lerp(target_position, RECOIL_APPLY_SPEED * delta)
	
	# Smoothly interpolate the target spread back to Vector2.ZERO.
	# This simulates the spread reduction over time, returning it to a neutral state.
	target_spread = target_spread.lerp(Vector2.ZERO, RECOIL_RECOVER_SPEED * delta)
	
	# Store the previous current rotation for later comparison.
	# This is used to calculate how much the rotation changes this frame.
	#var prev_rotation : Quaternion = current_rotation
	
	# Smoothly interpolate the current rotation towards the target rotation.
	# This creates a gradual recoil effect as the current rotation catches up with the target rotation.
	current_rotation = current_rotation.slerp(target_rotation, RECOIL_APPLY_SPEED * delta)
	
	# Smoothly interpolate the current spread towards the target spread.
	# This creates a gradual adjustment in bullet spread.
	current_spread = current_spread.lerp(target_spread, RECOIL_APPLY_SPEED * delta)
	
	# Apply the current rotation quaternion to the CameraRecoil node.
	# This directly affects the camera's rotation, simulating the recoil visually.
	%CameraRecoil.quaternion = current_rotation
	%Kickback.position = current_position

func get_current_spread() -> Vector2:
	return current_spread
	
#endregion

#region Physics pushing
#TODO : Need to fix for when on top of objects, maybe check how half life does it
# This function applies an impulse to RigidBody3D objects that collide 
# with the character, effectively "pushing them away."
func _push_away_rigid_bodies() -> void:
	# Iterate through all slide collisions that occurred during the last frame
	for i in get_slide_collision_count():
		# Get the collision information at index `i`
		var c : KinematicCollision3D = get_slide_collision(i)
		# Check if the collided object is a RigidBody3D
		var collider = c.get_collider()
		if collider is RigidBody3D:
			# Approximate the character's mass for physics calculations
			const MY_APPROX_MASS_KG: float = 80.0
			# Calculate the mass ratio (lower ratios mean heavier objects)
			var mass_ratio: float = min(1.0, MY_APPROX_MASS_KG / collider.mass)
			# Skip pushing objects that are 4x heavier or more than the character
			if mass_ratio < 0.25:
				continue
				
			# Determine the push direction (away from the collision normal)
			var push_dir: Vector3 = -c.get_normal()
				
			# Neutralize vertical components to ensure horizontal-only pushes
			push_dir.y = 0
			push_dir = push_dir.normalized()  # Re-normalize after modifying

			# Compute the velocity difference in the push direction
			# - Project both the character's velocity and the collider's velocity onto the push direction
			var velocity_diff_in_push_dir: float = velocity.dot(push_dir) - collider.linear_velocity.dot(push_dir)

			# Clamp velocity difference to avoid pulling or pushing objects unnecessarily
			velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
			
			# Compute the push force using a scaling factor
			# - Adjust `5.0` as needed to control the strength of the push
			const PUSH_FORCE_MULTIPLIER: float = 5.0
			#var impulse : Vector3 = push_dir * mass_ratio * PUSH_FORCE_MULTIPLIER * velocity_diff_in_push_dir
			var speed : float = clamp(velocity.length(), 1.0, 5.0)
			# Apply the impulse to the collided object
			# - The impulse is proportional to the velocity difference, push force, and direction
			# - The application point is the collision position relative to the collider's global position
			collider.apply_impulse(
				push_dir * mass_ratio * PUSH_FORCE_MULTIPLIER * velocity_diff_in_push_dir * speed,
				c.get_position() - collider.global_position
			)
#endregion

#region World Model Handling
func update_view_and_world_model_masks():
	for child in %WorldModel.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(WORLD_MODEL_LAYER, true)
		
	for child in %ViewModel.find_children("*", "VisualInstance3D", true, false):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(VIEW_MODEL_LAYER, true)
		if child is GeometryInstance3D:
			child.cast_shadow = false
			
	%PlayerCamera3D.set_cull_mask_value(WORLD_MODEL_LAYER, false)
	#%ThirdPersonCamera3D.set_cull_mask_value(VIEW_MODEL_LAYER, false)
#endregion
