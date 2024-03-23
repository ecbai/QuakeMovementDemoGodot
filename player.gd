extends CharacterBody3D

## Controls the strength of gravity seperate from the global value
@export var gravity_multiplier := 3.0

## Air acceleration limit for air strafing
@export var air_speed : float = 1.0

## Magnitude of the acceleration vector on the ground
@export var ground_acceleration : float = 200.0

## Magnitude of the acceleration vector in the air
@export var air_acceleration : float = 120.0

## Controls the max ground speed and rate of decleration when above max speed
@export var friction : float = 10.0

## +Y speed applied on jump
@export var jump_height : float = 10.0

## Force applied by firing at a surface
@export var force : float = 30.0

## Force applied by firing at a surface
@export var blast_radius : float = 8.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_multiplier

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add gravity to y velocity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Sets x and z velocity based on input direction
	velset(delta)
	
	# Moves the player while accounting for collision
	move_and_slide()
	
	# Makes collisions with walls and surfable surfaces more in line with Source
	if is_on_wall():
		velocity = velocity.slide(get_wall_normal())

# Sets the player's velocity based on their current speed and their input direciton
# Requires delta for framerate-independent movement
func velset(delta: float) -> void:
	var horivel := Vector2(velocity.x, velocity.z) # Current velocity
	var input_dir = Input.get_vector("back", "forward", "left", "right")
	var aim: Basis = get_global_transform().basis
	var direction = aim.z * -input_dir.x + aim.x * input_dir.y
	var target := Vector2(direction.x, direction.z) # Current input direction
	
	# Depending on whether or not the player is grounded,
	# use different funcitons to get new velocity
	if !is_on_floor():
		horivel = move_air(delta, target, horivel)
	else:
		# Change to Input.is_action_just_pressed("jump") to disable auto bhop
		if Input.is_action_pressed("jump"):
			velocity.y = jump_height
			horivel = move_air(delta, target, horivel)
		else: horivel = move_ground(delta, target, horivel)
	
	# Apply horivel to velocity
	velocity.x = horivel.x
	velocity.z = horivel.y

# Returns a new horizontal velocity after applying friction
# target: Current input direction
# horivel: Current velocity
func move_ground(delta: float, target: Vector2, horivel: Vector2) -> Vector2:
	var speed := horivel.length()
	# Apply friction to horivel
	if speed != 0:
		var drop := speed * friction * delta
		horivel *= max(speed - drop, 0) / speed
	return accelerate(delta, target, horivel, ground_acceleration)

# Returns a new horizontal velocity
# target: Current input direction
# horivel: Current velocity
func move_air(delta: float, target: Vector2, horivel: Vector2) -> Vector2:
	return accelerate(delta, target, horivel, air_acceleration)

# Applies acceleration to player velocity
# target: Current input direction
# horivel: Current horizontal velocity
# acceleration: Acceleration value based on whether the player is grounded or not
func accelerate(delta: float, target: Vector2, horivel: Vector2, acceleration: float) -> Vector2:
	var accel_velocity := acceleration * delta
	var projected_velocity := target.dot(horivel)
	
	# Checks if the dot product exceeds the air speed limit when in the air,
	# and allows the acceleration if it doesn't
	if !is_on_floor() && projected_velocity >= air_speed:
		return horivel
	else:
		return horivel + (target * accel_velocity)

# If fire is pressed, apply knockback to the player if they're
# close enough to the fire destination
func fire():
	if Input.is_action_just_pressed("fire"):
		if %RayCast3D.is_colliding():
			var mag = global_position.distance_to(%RayCast3D.get_collision_point())
			if mag < blast_radius:
				velocity += (%RayCast3D.get_collision_point().direction_to(global_position) * force) * (1 - (mag / (blast_radius * 2)))

func _unhandled_input(event):
	if event.is_action_pressed("mouse_mode"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("quit"):
		get_tree().quit()
