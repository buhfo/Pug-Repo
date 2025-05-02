extends MeshInstance3D

var ads_lerp = 20
const ads_slow_lerp = 5
const ads_fast_lerp = 20

@onready var camera: Camera3D = $".."



@export var default_pos : Vector3
@export var holding_pos : Vector3

var phone_up = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if phone_up:
		transform.origin = transform.origin.lerp(holding_pos,ads_lerp * delta)
	else: 
		transform.origin = transform.origin.lerp(default_pos,ads_lerp * delta)

func _phone_toggle():
	phone_up = !phone_up
	if phone_up:
		ads_lerp = ads_fast_lerp
	else:
		ads_lerp = ads_slow_lerp
