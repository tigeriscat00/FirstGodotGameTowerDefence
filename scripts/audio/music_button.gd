extends Button
## Reusable scene-local control for the shared music player.


func _ready() -> void:
	pressed.connect(Music.toggle_mute)
	Music.mute_changed.connect(_update_label)
	_update_label(Music.is_muted)


func _update_label(is_muted: bool) -> void:
	text = "Music: Off" if is_muted else "Music: On"
	tooltip_text = "Click to unmute background music" if is_muted else "Click to mute background music"
