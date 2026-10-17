extends Button


func _ready() -> void:
    pressed.connect(get_node("/root/Sfx").toggle_mute)
    get_node("/root/Sfx").mute_changed.connect(_update_label)
    _update_label(get_node("/root/Sfx").is_muted)


func _update_label(muted: bool) -> void:
    text = "Sound effects: Off" if muted else "Sound effects: On"
