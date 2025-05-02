extends CharacterBody3D


#references to the other parts of the player
@onready var gun: MeshInstance3D = $Head/Camera3D/Gunstandin
@onready var pause_menu: Control = $Head/Camera3D/Phone/SubViewport/PauseMenu
@onready var resume: Button = $Head/Camera3D/Phone/SubViewport/PauseMenu/MarginContainer/VBoxContainer/Resume
@onready var viewport: SubViewport = $Head/Camera3D/Phone/SubViewport
@onready var phone: MeshInstance3D = $Head/Camera3D/Phone
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var pug_run_away: NavigationObstacle3D = $"../PugRunAway"

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
@export var can_shoot = true

#fov variables
const  BASE_FOV = 90.0
const FOV_CHANGE = -0.5

#Booleans
var menu_up = false
var pug_scared = false

#pug run stuff
var grow_rate = 0.2


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

func _input(event):
	#makes it so you can interact with the menu on the phone
	if menu_up:
		viewport.push_input(event)


func _physics_process(delta: float) -> void:
	if pug_scared:
		pug_run_away.radius += grow_rate
	#shoots the gun when clicked
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_gun()
	
	if Input.is_action_just_pressed("esc") and gun.is_aiming == false:
		_menu()
	
	if gun.is_aiming and menu_up:
		_force_menu_close()
	
	if can_shoot == true:
		gun.set_surface_override_material(0, BLUE)
	else:
		gun.set_surface_override_material(0, RED)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += (get_gravity() * delta)*5
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
	
	if velocity.x != 0 or velocity.z != 0 :
		gun._is_moving()
	else:
		gun._not_moving()
	
	#FOV is changed here when running (it becomes smaller)
	if gun.is_aiming == false:
		var velocity_clamped = clamp(velocity.length(), 0.0, SPEED * 2)
		var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	#the third variable decided the speed of the change
		camera.fov = lerp(camera.fov, target_fov, delta * 16.0)
	#this is important but idk really why I cant lie
	
	if PlayerGlobal.Health <= 0:
		print("YOU IS DEAD")
	move_and_slide()

#toggles pulling the menu up and putting it away
func _menu():
	if menu_up:
		phone._phone_toggle()
		viewport.set_process(true)
		pause_menu.hide()
	if !menu_up:
		phone._phone_toggle()
		pause_menu.show()
		resume.grab_focus()
	menu_up = !menu_up

#forces the menu to close, specifically when you aim and its open
func _force_menu_close():
	pause_menu.hide()
	menu_up = false
	phone._phone_toggle()

#controls the headbobbing 
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	#up and down bobbing
	pos.y = sin(time * BOB_FREQ / 2) * BOB_AMP
	#left and right bobbing
	pos.x = cos(time * BOB_FREQ / 4) * BOB_AMP
	return pos

#controls gun logic
func _shoot_gun():
	
	#sets it so the player has to wait to shoot
	can_shoot = false
	gun._shoot_toggle()
	
	#adds a bullethole when this is called
	var bullethole = BULLET_HOLE.instantiate()
	
	#puts the bullethole where it needs to be in the world
	var space_state = get_world_3d().direct_space_state
	
	#chooses where to shoot the bullet from
	var mousepos = get_viewport().get_mouse_position()
	
	#sets the mouse as where the bullet shoots from
	var origin = camera.project_ray_origin(mousepos)
	
	#shoots a raycast for where the bullet goes
	var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
	
	#makes the raycast
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	
	#makes sure the raycast hits the wall
	query.collide_with_areas = true
	
	#shows what is hit by the raycast
	var result = space_state.intersect_ray(query)
	
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	
	
	#makes it so a bullethole arrives on the area that was shot
	if collision != {  }:
		print(collision, result)
		if result.collider_id == 48754591233:
			PugGlobal.just_shot = true
			PugGlobal.pug_health -=1
	#Instantiates the bullet hole
		get_tree().root.add_child(bullethole)
		
		#puts the bullethole on the correct position
		bullethole.global_position = result.position
		
		#makes the bullethole face the direction that the thing its on is facing
		bullethole.look_at(bullethole.global_transform.origin + result.normal, Vector3.UP)
		#still doing that
		if result.normal != Vector3.UP and result.normal != Vector3.DOWN:
		#yea
			bullethole.rotate_object_local(Vector3(1,0,0), 90)
		
		#makes the player wait 3 seconds before they can shoot
	await get_tree().create_timer(3).timeout
	can_shoot = true
	gun._shoot_toggle()

func _scare_pug():
	pug_run_away.show()
	pug_scared = true

func _stop_scaring():
	pug_run_away.radius = 0
	pug_run_away.hide()
	pug_scared = false
