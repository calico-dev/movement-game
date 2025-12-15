extends CharacterBody3D

var speed
var walljump := 0
var is_on_ledge = false
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.001


# Headbob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
var original_camera_y

# Camera and Raycast variables
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var below_ledge = $Head/ledge_check/below_ledge
@onready var above_ledge = $Head/ledge_check/above_ledge

# Capture mouse in game window
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	original_camera_y = camera.transform.origin
	
	# Aim raycast foward in direction of camera
	above_ledge.target_position = Vector3. FORWARD
	below_ledge.target_position = Vector3. FORWARD 

# Allow player to use mouse to look around
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
	# Unlock and lock mouse/physics when pressing esc 
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event.is_action_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		set_physics_process(false)
	elif event.is_action_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		set_physics_process(true)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Handle sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction to handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle Inertia
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 9.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 9.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 1.3)
	var target_fov = BASE_FOV + FOV_CHANGE + velocity_clamped
	if Input.is_action_pressed("sprint"):
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# "Climb" up ledge using raycast
	if above_ledge.is_colliding() == false and below_ledge.is_colliding():
		is_on_ledge = true
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY * 1.1
	else:
		is_on_ledge = false
	
	move_and_slide()
	
	# Handle wall jump
	if is_on_floor():
		walljump = 2
	
	if is_on_wall() and is_on_ledge == false:
		if walljump > 0 and Input.is_action_just_pressed("jump"):
			walljump -= 1
			velocity.y = JUMP_VELOCITY * 1.2
			print(walljump) 
