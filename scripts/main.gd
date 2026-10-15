extends Control
## Entry point for the tutorial project shell.


func _ready() -> void:
	print("FirstGodotGameTowerDefence: Godot + GDScript ready.")
	$Center/Menu/Start.pressed.connect(_start_tutorial)
	$Center/Menu/Quit.pressed.connect(get_tree().quit)


func _start_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
