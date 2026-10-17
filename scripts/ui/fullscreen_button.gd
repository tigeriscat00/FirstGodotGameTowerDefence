extends Button
## Window state belongs to the game window and survives scene changes.


func _ready() -> void:
	pressed.connect(_toggle_fullscreen)
	get_window().size_changed.connect(_update_label)
	_update_label()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	if _is_editor_embedded():
		_show_embedded_help()
		return
	var window: Window = get_window()
	if _is_fullscreen():
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN
	_update_label()


func _is_fullscreen() -> bool:
	return get_window().mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]


func _update_label() -> void:
	text = "Windowed [F11]" if _is_fullscreen() else "Fullscreen [F11]"
	tooltip_text = "Press F11 to switch between fullscreen and windowed play"
	if _is_editor_embedded():
		tooltip_text = "For fullscreen, use Play-Game.cmd or disable Embed Game on Next Play in Godot's Game menu"


func _is_editor_embedded() -> bool:
	return Engine.is_embedded_in_editor()


func _show_embedded_help() -> void:
	if has_node("FullscreenHelp"):
		get_node("FullscreenHelp").popup_centered()
		return
	var dialog := AcceptDialog.new()
	dialog.name = "FullscreenHelp"
	dialog.title = "Fullscreen: use a separate game window"
	dialog.dialog_text = "Godot's embedded game window cannot enter fullscreen.\n\nStop this run, then double-click Play-Game.cmd in the project folder.\n\nOr in Godot: Game tab > top-right menu > turn off\nEmbed Game on Next Play, then stop and press F5 again."
	add_child(dialog)
	dialog.popup_centered(Vector2i(660, 220))
