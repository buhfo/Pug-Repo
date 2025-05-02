extends State
class_name EnemyChase

@export var enemy: CharacterBody3D
@export var move_speed := 10.0

var player: CharacterBody3D


func Enter():
	player = get_tree().get_first_node_in_group("Player")

func Exit():
	pass

func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	var direction = player.global_position - enemy.global_position
	
	enemy.look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), Vector3.UP)
	if direction.length() > 2:
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = Vector3()
	if direction.length() > 20:
		Transitioned.emit(self, "Idle")
	
	if PugGlobal.just_shot == true:
		Transitioned.emit(self, "Escape")
