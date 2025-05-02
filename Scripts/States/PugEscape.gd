extends State
class_name EnemyRunASway

func Enter():
	PugGlobal.just_shot = false

func Exit():
	pass

func Update(_delta: float):
	await get_tree().create_timer(3).timeout
	Transitioned.emit(self, "Idle")
	

func Physics_Update(_delta: float):
	pass
