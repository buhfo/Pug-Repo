extends CharacterBody3D


#references to the other parts of the player
@onready var gun: MeshInstance3D = $Head/Camera3D/Gunstandin

##PAUSE HERE
@onready var pause_menu: Control = $Head/Camera3D/Phone/SubViewport/PauseMenu
@onready var resume: Button = $Head/Camera3D/Phone/SubViewport/PauseMenu/MarginContainer/VBoxContainer/Resume
@onready var viewport: SubViewport = $Head/Camera3D/Phone/SubViewport
@onready var phone: Node3D = $Head/Camera3D/Phone
@onready var menu: MarginContainer = $Head/Camera3D/Phone/SubViewport/PauseMenu/MarginContainer
var phone_turned = false
var menu_up = false



@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var anims: AnimationTree = $Head/Camera3D/Phone/AnimationTree
@onready var subview_cam: Camera3D = %Subview_cam

@onready var anim_tree: AnimationTree = $Head/Camera3D/Phone/AnimationTree



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
var can_go = true
var pug_scared = false


#pug run stuff
var grow_rate = 0.2


#Captures the mouse when the game is started (no mouse on screen)
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.animation_finished.connect(_on_animation_tree_animation_finished)
	anim_tree.animation_started.connect(_on_animation_tree_animation_started)

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


###USED FOR PAUSE
func _input(event):
	#makes it so you can interact with the menu on the phone
	if menu_up:
		viewport.push_input(event)

func _process(_delta):
	subview_cam.set_global_transform(camera.get_global_transform())
	print(can_go)

func _physics_process(delta: float) -> void:
	#shoots the gun when clicked
	if Input.is_action_just_pressed("shoot") and can_shoot:
		_shoot_gun()
	
	if Input.is_action_just_pressed("esc") and gun.is_aiming == false:
		_menu()
	if Input.is_action_just_pressed("turn") and menu_up:
		_turn_phone()
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
	if menu_up and phone.is_ready == true and can_go:
		if !phone_turned:
			anims["parameters/conditions/close_phone"] = true
			anims["parameters/conditions/open_phone"] = false
		if phone_turned:
			menu.rotation = 0
			anims["parameters/conditions/turn_up"] = true
			anims["parameters/conditions/turn_side"] = false
			anims["parameters/conditions/close_phone"] = true
			anims["parameters/conditions/open_phone"] = false
		#phone._phone_toggle()
		viewport.set_process(true)
	if !menu_up and phone.is_ready == true and can_go:
		anims["parameters/conditions/open_phone"] = true
		anims["parameters/conditions/close_phone"] = false
		phone._phone_toggle()
		resume.grab_focus()
	menu_up = !menu_up

func _turn_phone():
	if menu_up and phone.is_ready == true and can_go:
		anims["parameters/conditions/close_phone"] = false
		anims["parameters/conditions/open_phone"] = false
		if phone_turned:
			menu.rotation = 0
			anims["parameters/conditions/turn_up"] = true
			anims["parameters/conditions/turn_side"] = false
		if !phone_turned:
			menu.rotation_degrees = -90
			anims["parameters/conditions/turn_up"] = false
			anims["parameters/conditions/turn_side"] = true
	phone_turned = !phone_turned

#forces the menu to close, specifically when you aim and its open
func _force_menu_close():
	if phone_turned and phone.is_ready == true:
		menu.rotation = 0
		anims["parameters/conditions/turn_up"] = true
		anims["parameters/conditions/turn_side"] = false
		anims["parameters/conditions/close_phone"] = true
		anims["parameters/conditions/open_phone"] = false
	if !phone_turned:
		anims["parameters/conditions/turn_up"] = false
		anims["parameters/conditions/turn_side"] = false
		anims["parameters/conditions/close_phone"] = true
		anims["parameters/conditions/open_phone"] = false
	menu_up = false

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






func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Close":
		can_go = true
		print("CLOSEDDD!!!!!!")
		phone._phone_toggle()
	if anim_name == "Open":
		can_go = true
	if anim_name == "Turn":
		can_go = true
	if anim_name == "Return":
		can_go = true


func _on_animation_tree_animation_started(anim_name: StringName) -> void:
	can_go = false
