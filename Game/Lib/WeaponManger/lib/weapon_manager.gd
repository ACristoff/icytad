class_name WeaponManager extends Node3D

# Weapon Manager Script

# --------------------------------------------------------------------
# Exported Variables
# --------------------------------------------------------------------
@export_group("General Settings")
@export var player: Player
@export var current_weapon: WeaponResource:
	set(value):
		if value != current_weapon:
			if current_weapon:
				current_weapon.is_equipped = false
			current_weapon = value
			#if is_inside_tree():
			#	update_weapon_model()
@export var equipped_weapons: Array[WeaponResource]

@export var allow_shoot: bool = true

@export_group("Raycast Settings")
## Raycast for projectile
@export var projectile_raycast: RayCast3D
## Raycast for hitscan bullets
@export var bullet_raycast: RayCast3D
## Testing purposes
@export var debug_raycast: RayCast3D

@export_group("Weapon Model Settings")
@export var view_model_container: Node3D
@export var world_model_container: Node3D
@export var sway_noise: NoiseTexture2D
@export var weapon_bob: bool = true
@export var idle_weapon_sway_enable: bool = true

@export_group("Camera Settings")
@export var cam_3d: Camera3D
@export_range(75.0, 120.0, 0.1) var c_fov : float = 105.0:
	get:
		return c_fov
	set(value):
		c_fov = value
		# When the value changes, call our function
		#if is_inside_tree():
		#	apply_clip_and_fov_shader_to_view_model(current_weapon_view_model, c_fov)

@export_group("Weapon Bob Settings")
@export var bob_speed: float = 5.55
@export var hbob_amount: float = 3.30
@export var vbob_amount: float = 0.35

# --------------------------------------------------------------------
# Onready Variables
# --------------------------------------------------------------------
@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# --------------------------------------------------------------------
# Regular Variables
# --------------------------------------------------------------------
var current_weapon_view_model: Node3D
var current_weapon_view_model_muzzle: Node3D
var current_weapon_world_model: Node3D
var mouse_movement: Vector2
