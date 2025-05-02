extends Control

@onready var player: CharacterBody3D = $"../../../../.."

@onready var resume: Button = $MarginContainer/VBoxContainer/Resume



func _on_resume_pressed() -> void:
	player._menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
