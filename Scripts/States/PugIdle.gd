extends State
class_name EnemyIdle

@export var enemy: CharacterBody3D
@export var move_speed := 10.0

var move_direction : Vector3
var wander_time : float

##Its not looking at where it needs to be and IDK how to fix that lol
func randomize_wander():
	move_direction = Vector3(randf_range(-1, 1), -0.1, randf_range(-1, 1)).normalized()
	wander_time = randf_range(1,3)
	enemy.look_at(enemy.global_transform.origin - enemy.velocity)

func Enter():
	randomize_wander()

func Update(delta: float):
	if wander_time > 0:
		wander_time -= delta
	
	else:
		randomize_wander()

func Physics_Update(delta: float):
	if enemy:
		enemy.velocity = move_direction * move_speed
