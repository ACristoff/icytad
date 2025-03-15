## A resource that defines projectile-based weapon properties and behavior
class_name ProjectileWeaponResource extends WeaponResource

# Maybe resource pool for projectiles for enemies
# TODO: Modular muzzle flash
@export var projectile : PackedScene  # Reference to the projectile scene to instantiate.
@export var projectile_relative_velocity : float = 15.0  # Initial velocity of the projectile relative to its spawn point.
@export var projectile_y_velocity : float = 0.0
@export var player_velocity_influence : float = .75
@export var consider_player_velocity : bool = false

# Spawn projectile from muzzle location?
## Local space spawn location of projectile
@export var projectile_relative_spawn_pos : Vector3 = Vector3(0, 0, -2)  # Relative position offset for spawning the projectile.

# Maybe rotate projectile to center of screen
# Best to leave this at default unless you wanna try some weird wonky stuff
## Rotation of projectile
@export var projectile_relative_spawn_rotation : Vector3 = Vector3(0, 0, 0)  # Relative rotation for the projectile upon spawn.

# Function to handle the shooting of the weapon.
func primary_fire(shoot_animation : String, idle_animation : String, shoot_sound : AudioStream, pellet_count : int = 0):
	# Play the shoot animation and sound through the weapon manager.
	# weapon_manager.trigger_weapon_shoot_world_anim()  # Commented out, but could be used for additional effects.
	weapon_manager.play_anim(view_primary_shoot_anim)  # Plays the shooting animation.
	weapon_manager.play_sound(primary_shoot_sound)  # Plays the sound effect for shooting.
	weapon_manager.queue_anim(view_idle_anim)  # Queues the idle animation after the shot.
	
	# Apply recoil effects to the raycast's rotation.
	var current_spread : Vector2 = weapon_manager.get_current_spread()
	weapon_manager.bullet_raycast.rotation.x = current_spread.x
	weapon_manager.bullet_raycast.rotation.y = current_spread.y
	
	# Set the target position for the raycast relative to the weapon. Spawn location
	weapon_manager.bullet_raycast.target_position = projectile_relative_spawn_pos
	
	# Get base transform and calculate all shot transforms (for pellets if any)
	var base_transform : Transform3D = weapon_manager.bullet_raycast.global_transform
	var transforms_to_check : Array[Transform3D] = [base_transform]
	if pellet_count > 0:
		transforms_to_check.append_array(calculate_pellet_spread(base_transform, pellet_spread_radius, pellet_count))
		
	# Get the point where the player is aiming
	var aim_point : Vector3 = weapon_manager.camera_ray_cast()
	
	# Process each projectile (base shot + any pellets)
	for i in range(transforms_to_check.size()):
		# Determine the projectile's spawn position, adjusted for collision.
		weapon_manager.bullet_raycast.global_transform = transforms_to_check[i]
		# Force the raycast to update its collision detection immediately.
		weapon_manager.bullet_raycast.force_raycast_update()
		
		# Determine spawn position, adjusting if there's a wall in the way
		var rel_spawn_pos : Vector3 = projectile_relative_spawn_pos
		if weapon_manager.bullet_raycast.is_colliding():
			# If the raycast collides, adjust the spawn position to avoid spawning inside a wall.
			rel_spawn_pos = weapon_manager.bullet_raycast.global_transform.affine_inverse() * weapon_manager.bullet_raycast.get_collision_point()
			# Move the spawn position slightly back to ensure the projectile doesn't clip.
			rel_spawn_pos = rel_spawn_pos.limit_length(rel_spawn_pos.length() - 0.5)

		# Instantiate the projectile and add it to the player's siblings in the scene tree.
		var obj := projectile.instantiate()
		weapon_manager.player.add_sibling(obj)

		# Set the global transform for the projectile, combining raycast and relative settings.
		obj.global_transform = weapon_manager.bullet_raycast.global_transform * Transform3D(
			Basis.from_euler(projectile_relative_spawn_rotation), rel_spawn_pos
		)
		var projectile_velocity : Vector3
		if i == 0:  # This is the center/base projectile
			
			# Calculate direction FROM spawn position TO aim point for center shot only
			var spawn_to_target : Vector3 = (aim_point - obj.global_position).normalized()
			obj.look_at(obj.global_position + spawn_to_target)
			
			projectile_velocity = spawn_to_target * projectile_relative_velocity
			
		else:  # These are the spread projectiles
			# Use the transform's forward direction for spread shots
			var forward_direction : Vector3 = -obj.global_transform.basis.z
			obj.look_at(obj.global_position + forward_direction)
			
			projectile_velocity = forward_direction * projectile_relative_velocity
		
		projectile_velocity += Vector3.UP * projectile_y_velocity
		
		if consider_player_velocity:
			projectile_velocity += weapon_manager.player.velocity * player_velocity_influence
			
		# Set the projectile's velocity, combining player's current velocity and the relative velocity.
		if obj is RigidBody3D:
			obj.linear_velocity = projectile_velocity
			
		elif obj is CharacterBody3D:
			obj.velocity = projectile_velocity
			
	# Reset raycast to original transform
	weapon_manager.bullet_raycast.global_transform = base_transform
	
	# Display visual effects and apply recoil to the weapon.
	weapon_manager.show_muzzle_flash()  # Displays a flash effect at the muzzle.
	weapon_manager.apply_recoil_and_spread()  # Applies recoil to the weapon.

	# Update weapon's fire timing and ammo count.
	last_fire_time = Time.get_ticks_msec()
	current_ammo -= 1

	# Explanation of affine_inverse():
	# The affine_inverse() method is used to invert the transformation matrix of the raycast.
	# This effectively maps the global collision point back to the local coordinate space of the raycast.
	# It ensures the spawn position is accurate and adjusted for any collision effects in world space.
