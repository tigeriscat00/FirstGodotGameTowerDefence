extends AudioStreamPlayer
## One shared player preserves the loop and mute choice across scene changes.

signal mute_changed(is_muted: bool)

@export_range(-40.0, 0.0) var music_volume_db: float = -12.0
@export_file("*.wav") var music_path: String = "res://assets/audio/kingdom_theme.wav"
var is_muted: bool = false
var is_closing: bool = false


func _ready() -> void:
	# Load at runtime so a fresh editor import can register the autoload first.
	var source: AudioStreamWAV = load(music_path) as AudioStreamWAV
	if source == null:
		push_error("Background music could not be loaded: " + music_path)
		return
	var loop: AudioStreamWAV = source.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	stream = loop
	volume_db = music_volume_db
	get_tree().set_auto_accept_quit(false)
	get_tree().root.close_requested.connect(quit_game)
	play()


func toggle_mute() -> void:
	is_muted = not is_muted
	volume_db = -80.0 if is_muted else music_volume_db
	mute_changed.emit(is_muted)


func _exit_tree() -> void:
	stop()
	stream = null


func quit_game() -> void:
	if is_closing:
		return
	is_closing = true
	get_node("/root/Sfx").stop_all()
	stop()
	# Allow one mixer buffer to release the active WAV playback before shutdown.
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
