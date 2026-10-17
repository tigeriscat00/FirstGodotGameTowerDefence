extends SceneTree
## Shared playback survives scene changes; buttons keep one consistent mute state.

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)


func _run() -> void:
	await process_frame
	var player: AudioStreamPlayer = root.get_node("Music")
	var stream: AudioStreamWAV = player.stream as AudioStreamWAV
	_check(player.playing, "Music should start automatically")
	_check(is_equal_approx(stream.get_length(), 20.0), "Theme should be a 20-second loop")
	_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 0, "Full-track loop must be enabled")
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var button: Button = current_scene.get_node("Center/Menu/MusicToggle")
	button.pressed.emit()
	_check(player.is_muted and player.volume_db == -80.0 and button.text == "Music: Off", "Menu button should mute and update its label")
	change_scene_to_file("res://scenes/tutorial/tutorial.tscn")
	await process_frame
	await process_frame
	button = current_scene.get_node("SettingsOverlay/Card/Contents/MusicToggle")
	_check(root.get_node("Music") == player and player.playing, "Scene transition should preserve the existing player")
	_check(button.text == "Music: Off", "Tutorial should reflect the current mute choice")
	button.pressed.emit()
	_check(not player.is_muted and player.volume_db == -12.0, "Tutorial button should restore normal music volume")
	current_scene._toggle_pause()
	_check(player.playing and not player.stream_paused, "Music should continue during gameplay pause")
	reload_current_scene()
	await process_frame
	await process_frame
	_check(root.get_node("Music") == player and not player.is_muted, "Restart should preserve playback and mute state")
	player.seek(19.8)
	await create_timer(0.6).timeout
	_check(player.playing and player.get_playback_position() < 3.0, "Track should wrap and keep playing past its end")
	print("MUSIC CHECKS: %d checks, %d failures" % [checks, failures])
	root.get_node("Sfx").stop_all()
	player.stop()
	await create_timer(0.1).timeout
	quit(1 if failures > 0 else 0)
