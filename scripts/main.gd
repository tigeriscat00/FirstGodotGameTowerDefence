extends Control
## Entry point for the playable tutorial.


func _ready() -> void:
	get_node("/root/Sfx").stop_combat()
	get_window().min_size = Vector2i(1152, 648)
	print("FirstGodotGameTowerDefence: Godot + GDScript ready.")
	$Center/Menu/Start.pressed.connect(_start_tutorial)
	$Center/Menu/Quit.pressed.connect(Music.quit_game)


func _start_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
