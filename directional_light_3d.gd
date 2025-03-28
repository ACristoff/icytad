#@tool
extends DirectionalLight3D

@export var target : Node3D
@export var orbit_radius: float = 5.0  # The radius of the orbit
@export var orbit_speed: float = 1.0  # Speed of orbit (radians per second)
@export var orbit_axis: Vector3 = Vector3.UP  # Axis of rotation

var angle : float = 0.0

func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
	update_orbit(delta)

func update_orbit(delta: float) -> void:
	if target == null:
		return
	
	angle += orbit_speed * delta
	#var offset : Vector3 = Vector3(orbit_radius * cos(angle), 0, orbit_radius * sin(angle))
	var offset : Vector3 = Vector3(orbit_radius * cos(angle), orbit_radius * sin(angle), 0)
	
	var basis_t : Basis = Basis.looking_at(orbit_axis, Vector3.FORWARD)
	offset = basis_t * offset
	
	global_position = target.global_position + offset
	
	# Make the light face the target
	look_at(target.global_position, orbit_axis)
	
	#print(global_position)
