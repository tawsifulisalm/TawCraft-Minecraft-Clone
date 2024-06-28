extends CharacterBody3D

const SPEED = 16.0
const JUMP_VELOCITY = 14.0
var sensitivity = 0.002
var selected = 6

@onready var camera_3d = $Camera3D
@onready var ray_cast_3d = $Camera3D/RayCast3D
@onready var hot_bar = $HotBar
@onready var player = $"."

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 24.0

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hot_bar.select(0)

func _unhandled_input(event):
	if Input.is_action_just_pressed("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.is_action_just_pressed("resume"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * sensitivity
		camera_3d.rotation.x -= event.relative.y * sensitivity
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Handle block destruction and placement.
	if Input.is_action_just_pressed("LEFT_CLICK"):
		if ray_cast_3d.is_colliding():
			if ray_cast_3d.get_collider().has_method("destroy_block"):
				ray_cast_3d.get_collider().destroy_block(ray_cast_3d.get_collision_point() - ray_cast_3d.get_collision_normal())

	if Input.is_action_just_pressed("RIGHT_CLICK"):
		if ray_cast_3d.is_colliding():
			if ray_cast_3d.get_collider().has_method("place_block"):
				ray_cast_3d.get_collider().place_block(ray_cast_3d.get_collision_point() + ray_cast_3d.get_collision_normal(), selected)

	# Handle hotbar selection.
	if Input.is_action_just_pressed("one"):
		selected = 6
		hot_bar.select(0)

	if Input.is_action_just_pressed("two"):
		selected = 5
		hot_bar.select(1)

	if Input.is_action_just_pressed("three"):
		selected = 1
		hot_bar.select(2)

	if Input.is_action_just_pressed("four"):
		selected = 0
		hot_bar.select(3)

	if Input.is_action_just_pressed("five"):
		selected = 7
		hot_bar.select(4)

	if Input.is_action_just_pressed("six"):
		selected = 4
		hot_bar.select(5)

	if Input.is_action_just_pressed("seven"):
		selected = 9
		hot_bar.select(6)

	if Input.is_action_just_pressed("eight"):
		selected = 2
		hot_bar.select(7)

	if Input.is_action_just_pressed("nine"):
		selected = 3
		hot_bar.select(8)

	move_and_slide()
