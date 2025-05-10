extends CharacterBody3D


#references the other parts of the pug
@onready var dog_body: MeshInstance3D = $MeshInstance3D
@onready var nav: NavigationAgent3D = $NavigationAgent3D

#Finds the player when the scene starts
@onready var player = get_tree().get_first_node_in_group("Player")

# the various states the pug controls
var isChasing: bool
var isSearching: bool
var isStuck: bool
var canFind: bool
var isEscaping: bool

#handles the pathfinding for the pug(before he finds you)
@onready var randomPos = Vector3(randf_range(-50, 50), position.y, randf_range(-50,50))

#sets the timers for each state#
@onready var wanderTimer = 5.0
var findTimer = 3.0
@export var escapeTimer = 10.0


#controls the speed the pug goes while navigating
@onready var walkingSpeed = 10.0
@onready var runningSpeed = 20.0
@onready var escapingSpeed = 30.0
var speed = 10.0

#Loads the colors in for the pugs bean body
const GREEN = preload("res://Materials/Green.tres")
const RED = preload("res://Materials/Red.tres")

#Booleans
var has_seen = false
var found_escape = false

#Escape Point References
@onready var escape_1: Node3D = $"../EscapePoints/Escape1"
@onready var escape_2: Node3D = $"../EscapePoints/Escape2"
@onready var escape_3: Node3D = $"../EscapePoints/Escape3"
@onready var escape_4: Node3D = $"../EscapePoints/Escape4"
@onready var escape_5: Node3D = $"../EscapePoints/Escape5"
@onready var escape_6: Node3D = $"../EscapePoints/Escape6"
@onready var escape_7: Node3D = $"../EscapePoints/Escape7"
@onready var escape_8: Node3D = $"../EscapePoints/Escape8"

#Puts the coordinates to run to in an array
@onready var escapes: Array = [
	escape_1.transform.origin,
	escape_2.transform.origin,
	escape_3.transform.origin,
	escape_4.transform.origin,
	escape_5.transform.origin,
	escape_6.transform.origin,
	escape_7.transform.origin,
	escape_8.transform.origin,
]
#Makes it so you can calculate where to run to after being shot
var furthest_point: Vector3

func _ready() -> void:
	canFind = true

func _physics_process(delta: float) -> void:
	
	
	if isChasing:
		chase()
	elif isEscaping:
		escaping(delta)
	else:
		wandering(delta)
	if PugGlobal.just_shot == true:
		_swap_state_to_escape()
	if canFind == false:
		findTimer-= delta
	if canFind == false and findTimer <= 0:
		canFind = true
	var direction = nav.get_next_path_position()-global_position
	direction = direction.normalized()
	velocity = velocity.lerp(direction * speed, delta * 10)
	if PugGlobal.pug_health <= 0:
		self.queue_free()
	move_and_slide()

func chase():
	found_escape= false
	player._stop_scaring()
	dog_body.set_surface_override_material(0, GREEN)
	speed = runningSpeed
	look_at(player.position)
	nav.target_position = player.global_position

func wandering(delta):
	found_escape = false
	speed = walkingSpeed
	dog_body.set_surface_override_material(0, GREEN)
	if (global_transform.origin + velocity) != self.position:
		look_at(global_transform.origin + velocity)
		isStuck = false
	if (global_transform.origin + velocity) == self.position: 
		isStuck = true
	has_seen = false
	nav.target_position = randomPos
	if(abs(randomPos.x - global_position.x) <= 5 and abs(randomPos.z - global_position.z) <= 5) or wanderTimer <= 0 or isStuck:
		randomPos = Vector3(randf_range(player.global_position.x-40, player.global_position.x+40),position.y, randf_range(player.global_position.z-40, player.global_position.z+40))
		clamp(randomPos.x, -50, 50)
		clamp(randomPos.z, -50, 50)
		wanderTimer = 5.0
	wanderTimer -= delta

func escaping(delta):
	if found_escape == false:
		get_furthest_point(player.global_position)
		found_escape = true
	player._scare_pug()
	speed = escapingSpeed
	has_seen = false
	dog_body.set_surface_override_material(0, RED)
	if (global_transform.origin + velocity) != self.position:
		look_at(global_transform.origin + velocity)
		isStuck = false
	if (global_transform.origin + velocity) == self.position: 
		isStuck = true
	
	
	nav.target_position = Vector3(randf_range(furthest_point.x-20, furthest_point.x+20),position.y,randf_range(furthest_point.z-20, furthest_point.z+20))
	
	if(abs(furthest_point.x - global_position.x) <= 5 and abs(furthest_point.z - global_position.z) <= 5) or wanderTimer <= 0 or isStuck:
		randomPos = Vector3(randf_range(global_position.x-40, global_position.x+40),position.y, randf_range(global_position.z-40, global_position.z+40))
		clamp(furthest_point.x, -50, 50)
		clamp(furthest_point.z, -50, 50)
		nav.target_position = randomPos
		wanderTimer = 5.0
	
	wanderTimer -= delta
	escapeTimer-=delta
	#resets the escape timer after escape state ends
	if escapeTimer <= 0:
		player._stop_scaring()
		isEscaping = false
		escapeTimer = 10.0

func _on_finder_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and canFind == true:
		isChasing = true

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		PlayerGlobal.Health -= 1

func _swap_state_to_escape():
	isChasing = false
	isEscaping = true
	findTimer = escapeTimer - (escapeTimer/2)
	canFind = false
	PugGlobal.just_shot = false

func get_furthest_point(player_pos: Vector3) -> Vector3:
	var max_distance = -1.0
	
	for point in escapes:
		var distance = player_pos.distance_to(point)
		if distance > max_distance:
			max_distance = distance
			furthest_point = point
	return furthest_point
