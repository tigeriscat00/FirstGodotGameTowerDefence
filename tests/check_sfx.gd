extends SceneTree

var checks: int = 0
var failures: int = 0
var heard: Array[StringName] = []


func _initialize() -> void:
    _run.call_deferred()


func _check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(message)


func _run() -> void:
    await process_frame
    var sfx: Node = root.get_node("Sfx")
    sfx.effect_played.connect(func(effect: StringName) -> void: heard.append(effect))
    _check(sfx.voices.size() == 10, "Sound voices are bounded")
    for effect: StringName in sfx.streams:
        var stream: AudioStreamWAV = sfx.streams[effect]
        _check(stream != null and stream.get_length() > 0.05, "Playable WAV loaded for " + str(effect))
    change_scene_to_file("res://scenes/main.tscn")
    await process_frame
    await process_frame
    var music: AudioStreamPlayer = root.get_node("Music")
    var music_mute: bool = music.is_muted
    current_scene.get_node("Center/Menu/SfxToggle").pressed.emit()
    _check(sfx.is_muted and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX control mutes the effects bus")
    _check(music.is_muted == music_mute, "SFX mute leaves music choice unchanged")
    _check(not sfx.play(&"ballista"), "Muted effects do not start playback")
    current_scene.get_node("Center/Menu/SfxToggle").pressed.emit()
    _check(not sfx.is_muted, "SFX can be unmuted")
    sfx.last_played.clear()
    heard.clear()
    current_scene.get_node("Center/Menu/Start").pressed.emit()
    await process_frame
    await process_frame
    _check(heard.count(&"ui_click") == 1, "A button press emits exactly one click across a scene transition")
    var tutorial: Variant = current_scene
    tutorial.set_process(false)
    tutorial.board.set_process(false)
    _check(tutorial.get_node("SettingsOverlay/Card/Contents/SfxToggle").text == "Sound effects: On", "Settings reflects shared sound-effects state")
    tutorial._toggle_shop()
    _check(sfx.combat_paused, "Shop pauses combat audio")
    sfx.last_played.clear()
    _check(sfx.play(&"ui_click") and not sfx.play(&"ballista"), "UI clicks play while combat effects are paused")
    _check(not sfx.play(&"ui_click"), "Immediate duplicate clicks are rate limited")
    tutorial._buy()
    _check(not sfx.combat_paused, "Successful purchase resumes combat audio")
    tutorial._on_board_clicked(tutorial.board.cell_center(24))
    tutorial._on_board_clicked(tutorial.board.towers[0].position)
    sfx.last_played.clear()
    heard.clear()
    tutorial._upgrade()
    _check(heard.has(&"upgrade"), "Upgrading triggers its transformation sound")
    tutorial._on_board_clicked(tutorial.board.towers[0].position)
    tutorial._activate_skill(0)
    tutorial._on_board_clicked(tutorial.board.zombie.position)
    _check(heard.has(&"freeze"), "Successful Freeze cast triggers an icy effect")
    tutorial.board.towers[0].cooldown = 0.0
    tutorial.board.tick(0.1)
    _check(heard.has(&"ballista") and heard.has(&"impact"), "A tower shot produces both launch and hit effects")
    var zombie: TutorialZombie = tutorial.board.zombie
    zombie.freeze_left = 0.0
    zombie.groan_left = 0.0
    sfx.last_played.clear()
    heard.clear()
    zombie.tick(0.1, tutorial.board.towers, tutorial.board.GATE)
    _check(heard.has(&"groan_a"), "Active zombie groans on its interval")
    zombie.freeze(1.0)
    zombie.groan_left = 0.0
    sfx.last_played.clear()
    heard.clear()
    zombie.tick(0.1, tutorial.board.towers, tutorial.board.GATE)
    _check(heard.is_empty(), "Frozen zombie does not start another groan")
    tutorial._toggle_pause()
    _check(sfx.combat_paused, "Settings pauses combat effects")
    tutorial._back_to_menu()
    await process_frame
    await process_frame
    var combat_playing: bool = false
    for index: int in sfx.voices.size():
        if sfx.tags[index] != &"ui_click" and sfx.voices[index].playing:
            combat_playing = true
    _check(not combat_playing and not sfx.combat_paused, "Returning to menu clears combat sounds and pause state")
    print("SFX CHECKS: %d checks, %d failures" % [checks, failures])
    sfx.stop_all()
    music.stop()
    await create_timer(0.1).timeout
    quit(1 if failures else 0)
