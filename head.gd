extends Node3D

@export var sensitivity := 0.5
@export var y_limit := 90.0

func _ready():
	sensitivity = sensitivity / 1000
	y_limit = deg_to_rad(y_limit)

func _input(event):
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_axis = event.relative
		
		# Horizontal mouse look.
		get_owner().rotation.y -= mouse_axis.x * sensitivity
		
		# Vertical mouse look.
		rotation.x = clamp(rotation.x - mouse_axis.y * sensitivity, -y_limit, y_limit)
	
	if event.is_action_pressed("fire"):
		get_owner().fire()
