extends CharacterBody3D



@onready var gun: MeshInstance3D = $Head/Camera3D/Gunstandin

#materials
const BLUE = preload("res://Materials/Blue.tres")
const RED = preload("res://Materials/Red.tres")

#controls movement speed and mouse sensitivity
const SPEED = 20.0
const SENSITIVITY = 0.003

#headbob variables
const BOB_FREQ =2.0
const BOB_AMP = 0.08
var t_bob = 0.0

# Gun Constants
const RAY_LENGTH = 1000.0
const BULLET_HOLE = preload("res://Player/BulletHole.tscn")
var can_shoot = true

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = -0.5

#references to other parts of the player
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var shot: RayCast3D = $Head/Camera3D/GunCast



#Captures the mouse when the game is started (no mouse on screen)
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Controls the camera in reference to the mouse movement
#unhandled input means that this is called every time an input is done in game
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		#Rotates only the head, when the player turns left and right. 
		#important that the head is rotated seperately so that it doesnt get wiggly
		head.rotate_y(-event.relative.x * SENSITIVITY)
		#rotates the camera only up and down. same importance that its seperate as before
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		#Stops the player from doing flips with the mouse
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))




func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot") and can_shoot:
		can_shoot = false
		var bullethole = BULLET_HOLE.instantiate()
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		var origin = camera.project_ray_origin(mousepos)
		var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var result = space_state.intersect_ray(query)
		if result != {  }:
			get_tree().root.add_child(bullethole)
			bullethole.global_position = result.position
			bullethole.look_at(bullethole.global_transform.origin + result.normal, Vector3.UP)
			if result.normal != Vector3.UP and result.normal != Vector3.DOWN:
				bullethole.rotate_object_local(Vector3(1,0,0), 90)
		await get_tree().create_timer(3).timeout
		can_shoot = true
	
	#add something here so the gun is centered for ADS
	if Input.is_action_just_pressed("aim") and can_shoot:
		pass
	
	if can_shoot == true:
		gun.set_surface_override_material(0, BLUE)
	else:
		gun.set_surface_override_material(0, RED)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("A", "D", "W", "S")
	#makes sure that the direction the player moves is based off the camera position
	var direction := Vector3 (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#Moves the player, if the player isnt on the floor the player has less control
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
	# Makes sure the player isnt magically stopped on a dime
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 2.0)
	#Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	#FOV is changed here when running (it becomes smaller)
	var velocity_clamped = clamp(velocity.length(), 0.0, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	#the third variable decided the speed of the change
	camera.fov = lerp(camera.fov, target_fov, delta * 16.0)
	#this is important but idk really why I cant lie
	move_and_slide()


#controls the headbobbing 
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	#up and down bobbing
	pos.y = sin(time * BOB_FREQ / 2) * BOB_AMP
	#left and right bobbing
	pos.x = cos(time * BOB_FREQ / 4) * BOB_AMP
	return pos
