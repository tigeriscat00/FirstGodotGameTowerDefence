extends Control
## UI scaffold only: no purchases, combat, or tutorial completion yet.

@export var guide_name: String = "Sphinx"

@onready var guide: Label = $Margin/Layout/Guide
@onready var shop: PanelContainer = $Margin/Layout/Shop


func _ready() -> void:
	$Margin/Layout/Actions/ShopToggle.pressed.connect(_toggle_shop)
	$Margin/Layout/Actions/Restart.pressed.connect(_restart)
	$Margin/Layout/Actions/Back.pressed.connect(_back_to_menu)
	_update_guide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shop"):
		_toggle_shop()
		get_viewport().set_input_as_handled()


func _toggle_shop() -> void:
	shop.visible = not shop.visible
	_update_guide()


func _update_guide() -> void:
	if shop.visible:
		guide.text = "%s: This is the tower shop. Press B again to close it." % guide_name
	else:
		guide.text = "%s: Welcome! Press B to open the tower shop." % guide_name


func _restart() -> void:
	get_tree().reload_current_scene()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
