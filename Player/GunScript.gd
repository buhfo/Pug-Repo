extends MeshInstance3D

var ads_lerp = 20
const ads_slow_lerp = 5
const ads_fast_lerp = 20

@onready var camera: Camera3D = $".."


@export var default_pos : Vector3
@export var aiming_pos : Vector3

var can_shoot = true
var is_aiming = false
var is_moving = false

var fview = {"Default": 90.0, "ADS": 50.0}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.a


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("aim") && can_shoot == true:
		is_aiming = true
		transform.origin = transform.origin.lerp(aiming_pos,ads_lerp * delta)
		camera.fov = lerp(camera.fov, fview["ADS"], ads_lerp * delta)
	else: 
		is_aiming = false
		transform.origin = transform.origin.lerp(default_pos,ads_lerp * delta)
		if is_moving == false:
			camera.fov = lerp(camera.fov, fview["Default"], ads_lerp * delta)


func _shoot_toggle():
	can_shoot = !can_shoot
	if can_shoot:
		ads_lerp = ads_fast_lerp
	else:
		ads_lerp = ads_slow_lerp

func _is_moving():
	is_moving = true

func _not_moving():
	is_moving= false
