## A resource that defines hitscan weapon properties and behavior
class_name WeaponResource extends Resource

# ========= Signals ==========
# Add signals here if needed in the future.

# ========= Constants ==========
const RAYCAST_DIST: float = 9999.0

# ========= Exported Variables ==========
# --------------------------------------------------------------------
# Basic Properties
@export var name : String

# --------------------------------------------------------------------
# Models
## Used for first person perspective, when holding the gun. Will include hand models.
@export var view_model: PackedScene
## Third person perspective or when weapon is on ground
@export var world_model: PackedScene

# --------------------------------------------------------------------
# Model Orientation
# NOTE: All local to character
@export_category("Weapon Orientation")
## Local position (player's point of view)
@export var view_model_pos: Vector3
## Local rotation (player's point of view)
@export var view_model_rot: Vector3
## Local scale (player's point of view)
@export var view_model_scale: Vector3 = Vector3(1, 1, 1)

## Local position (other player's view)
@export var world_model_pos: Vector3
## Local rotation (other player's view)
@export var world_model_rot: Vector3
## Local scale (other player's view)
@export var world_model_scale: Vector3 = Vector3(1, 1, 1)

# --------------------------------------------------------------------
# Animations
@export_category("Weapon Animations")
## Weapon idle animation to play
@export var view_idle_anim: String
## Weapon equip animation to play
@export var view_equip_anim: String
## Weapon reload animation to play
@export var view_reload_anim: String
## Primary Weapon shoot animation to play
@export var view_primary_shoot_anim: String
## Secondary Weapon shoot animation to play
@export var view_secondary_shoot_anim: String

# --------------------------------------------------------------------
# Weapon Sway
## TODO: Code related to this is a bit buggy, fix later
@export_subgroup("Weapon Sway")
@export var sway_min : Vector2 = Vector2(-10.0, -10.0)
@export var sway_max : Vector2 = Vector2(10.0, 10.0)

@export_range(0, 20.2, 0.01) var sway_speed_position : float = 10.0
@export_range(0, 20.2, 0.01) var sway_speed_rotation : float = 10.0
@export_range(0, 0.2, 0.01) var sway_amount_position : float = 0.1
@export_range(0, 0.2, 0.01) var sway_amount_rotation : float = 30.0

@export_subgroup("Weapon Idle Sway")
@export var idle_sway_speed : float = 1.2
@export var idle_sway_adjustment : float = 10.0
@export var idle_sway_rotation_strength : float = 300.0
@export_range(0.1, 10.0, 0.1) var idle_random_sway_amount : float = 5.0

# --------------------------------------------------------------------
# Sound Effects
@export_category("Weapon Sound Effects")

## Sound to play during unholster animation if any
@export var unholster_sound : AudioStream
## Sound to play during primary shooting animation if any
@export var primary_shoot_sound : AudioStream
## Sound to play during secondary shooting animation if any
@export var secondary_shoot_sound : AudioStream

## Sound to play during reload animation if any
@export var primary_reload_sound : AudioStream
## Sound to play during reload animation if any
@export var secondary_reload_sound : AudioStream

@export_subgroup("Weapon Effects")
@export_range(2, 100, 1) var tracer_every_n_shots : int = 2

@export var tracer_effect : String

# --------------------------------------------------------------------
# Weapon Logic
@export_category("Weapon Logic")
@export_subgroup("Weapon Shooting")
## Damage each pellet will deal
@export var damage_per_pellet: int = 10

## The amount of pellets that will be fired out by the weapon.
## One pellet will always be sent out to the center of the screen regardless of pellet count.
@export var pellet_count: int = 0

## Rate of fire in milliseconds
@export var primary_max_fire_rate_ms: int = 50
## Rate of fire in milliseconds
@export var secondary_max_fire_rate_ms: int = 50

## Current ammo
@export var current_ammo: int = 999

## Mag capacity
@export var magazine_capacity: int = 999

@export_subgroup("Weapon Recoil")
## Direction weapon will recoil (Static)
## X : +Left/-Right (Rotation about Y-Axis)
## Y : +Up/-Down (Rotation about X-Axis)
## Z : +/-Roll (Rotation about Z-Axis)
@export var weapon_recoil: Vector3 = Vector3.ZERO
## Weapon recoil random deviation (Dynamic)
## NOTE: Keep the values between 0-1.
@export var weapon_recoil_range: Vector3 = Vector3.ZERO
## Dampens the recoil
## NOTE: The editor shows 0.0 but the value is actually 0.0002
@export var weapon_recoil_dampener: float = 0.0002
## Dampens weapon recoil range
@export var weapon_recoil_range_dampener: float = 0.05

@export_subgroup("Weapon Spread")
## Direction bullets will deviate
## X : Displacement along X-AXis
## Y : Displacement along Y-Axis
@export var weapon_spread_range: Vector2 = Vector2.ZERO
## Dampens weapon spread range
@export var weapon_spread_dampener: float = 0.05
## Radius pellets will land in
@export_range(0.01, 0.2, 0.01) var pellet_spread_radius: float = 0.1

# ========= Variables ==========
var weapon_manager : WeaponManager



































var trigger_down: bool = false:
	set(value):
		if trigger_down != value:
			trigger_down = value
			if trigger_down:
				on_trigger_down()
			else:
				on_trigger_up()

var is_equipped: bool = false:
	set(value):
		if is_equipped != value:
			is_equipped = value
			if is_equipped:
				on_equip()
			else:
				on_unequip()

enum FireMode {
	PRIMARY = 0,
	SECONDARY = 1
}
var current_fire_mode: FireMode = FireMode.PRIMARY

var last_fire_time: int = -999999
var current_cooldown_ms: int = 0  # Stores the active cooldown duration

func on_process(_delta: float) -> void:
	# Get current time for consistency in calculations
	var current_time: int = Time.get_ticks_msec()
	
	# Calculate time since last fire of any type
	var time_since_last_fire: int = current_time - last_fire_time
	
	# If we're still in the cooldown period from the last shot, exit early
	if time_since_last_fire < current_cooldown_ms:
		return
		
	# If basic firing conditions aren't met, exit early
	if not trigger_down or current_ammo <= 0:
		return
	
	# We can fire now - handle based on current mode
	if current_fire_mode == 0:
		# Primary fire logic
		primary_fire(view_primary_shoot_anim, view_idle_anim, primary_shoot_sound, pellet_count)
		current_cooldown_ms = primary_max_fire_rate_ms  # Set next cooldown duration
	else:
		# Secondary fire logic
		secondary_fire()
		current_cooldown_ms = secondary_max_fire_rate_ms  # Set next cooldown duration
	
	# Update the last fire time after successful shot
	last_fire_time = current_time

func on_trigger_down() -> void:
	# Get current time for consistency
	var current_time: int = Time.get_ticks_msec()
	
	# Check if we're still in cooldown from the last shot
	var time_since_last_fire: int = current_time - last_fire_time
	if time_since_last_fire < current_cooldown_ms:
		return
	
	# Fire the appropriate mode and set its cooldown
	if current_fire_mode == 0:
		primary_fire(view_primary_shoot_anim, view_idle_anim, primary_shoot_sound, pellet_count)
		current_cooldown_ms = primary_max_fire_rate_ms
	else:
		secondary_fire()
		current_cooldown_ms = secondary_max_fire_rate_ms
	
	# Update the last fire time
	last_fire_time = current_time

func on_equip():
	weapon_manager.play_sound(unholster_sound)
	weapon_manager.play_anim(view_equip_anim)
	weapon_manager.queue_anim(view_idle_anim)

# TODO: change signature to allow for different sound effects
func primary_fire(shoot_animation : String, idle_animation : String, shoot_sound : AudioStream, fire_pellet_count : int = 0):
	# Play animations and sounds first
	weapon_manager.play_anim(shoot_animation)
	weapon_manager.play_sound(shoot_sound)
	weapon_manager.queue_anim(idle_animation)
	
	# Apply the base spread from player movement/recoil
	var current_spread : Vector2 = weapon_manager.get_current_spread()
	weapon_manager.bullet_raycast.rotation.x = current_spread.x
	weapon_manager.bullet_raycast.rotation.y = current_spread.y
	
	# Store the base transform that includes player's aim and recoil
	var base_transform : Transform3D = weapon_manager.bullet_raycast.global_transform
	
	# We'll always start with the base shot transform
	var transforms_to_check: Array[Transform3D] = [base_transform]
	
	# If we have pellets, add their transforms to our check array
	if fire_pellet_count > 0:
		# Calculate additional pellet spreads and extend our transforms array
		transforms_to_check.append_array(
			calculate_pellet_spread(base_transform, pellet_spread_radius, fire_pellet_count)
		)
	
	# Process each transform (base shot plus any pellets)
	for i in range(transforms_to_check.size()):
		var pellet_transform = transforms_to_check[i]
		weapon_manager.bullet_raycast.global_transform = pellet_transform
		weapon_manager.bullet_raycast.target_position = Vector3(0, 0, -RAYCAST_DIST)
		weapon_manager.bullet_raycast.force_raycast_update()
		
		var bullet_target_pos : Vector3 = weapon_manager.bullet_raycast.global_transform * weapon_manager.bullet_raycast.target_position
		
		if weapon_manager.bullet_raycast.is_colliding():
			var obj := weapon_manager.bullet_raycast.get_collider()
			var nrml : Vector3 = weapon_manager.bullet_raycast.get_collision_normal()
			var pt : Vector3 = weapon_manager.bullet_raycast.get_collision_point()
			
			bullet_target_pos = pt
			
			#if obj is not CharacterBody3D:
			#	BulletDecalPool.spawn_bullet_decal(pt, nrml, obj, weapon_manager.bullet_raycast.global_basis)
				
			if obj is RigidBody3D:
				obj.apply_impulse(-nrml * 5.0 / obj.mass, pt - obj.global_position)
				
			if obj.has_method("take_damage"):
				obj.take_damage(damage_per_pellet)
		
		# Show trail for base shot and every other pellet
		if i % tracer_every_n_shots == 0:
			weapon_manager.make_bullet_trail(bullet_target_pos)
	
	# Reset raycast to original transform
	weapon_manager.bullet_raycast.global_transform = base_transform
	
	weapon_manager.show_muzzle_flash()
	weapon_manager.apply_recoil_and_spread()
	
	current_ammo -= 1


# Can also be used for spread by slighting increasing radius over time
# This function calculates spread positions for multiple pellets within a circular pattern
func calculate_pellet_spread(base_transform: Transform3D, spread_radius: float, num_pellets: int) -> Array[Transform3D]:
	# Pre-allocate the array to avoid reallocations during push_back
	var pellet_transforms: Array[Transform3D] = []
	pellet_transforms.resize(num_pellets)
	
	# Cache the doubled radius for our square bounds
	var double_radius : float = spread_radius * 2.0
	# Cache radius squared for comparison - avoiding square root calculations
	var radius_squared : float = spread_radius * spread_radius
	
	var i : int = 0
	while i < num_pellets:
		# Generate random point in square (-radius, radius) for both x and y
		var x := (randf() * double_radius) - spread_radius
		var y := (randf() * double_radius) - spread_radius
		
		# Check if point lies within our circle using squared distance
		# This avoids expensive square root calculation
		if x * x + y * y <= radius_squared:
			# Create spread rotation directly from our x,y coordinates
			# This is more efficient than generating angle + radius and converting
			var spread_rotation : Transform3D = Transform3D()
			spread_rotation = spread_rotation.rotated(Vector3.RIGHT, x)
			spread_rotation = spread_rotation.rotated(Vector3.UP, y)
			
			# Store transform directly in pre-allocated array
			pellet_transforms[i] = base_transform * spread_rotation
			i += 1
	
	return pellet_transforms

func secondary_fire() -> void:
	# Base implementation does nothing
	pass
	
func on_trigger_up():
	pass
	
func on_unequip():
	pass
