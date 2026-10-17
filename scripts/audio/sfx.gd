extends Node
## Shared bounded voice pool: UI survives transitions; combat can pause/mute.

signal effect_played(effect: StringName)
signal mute_changed(is_muted: bool)

const GAINS: Dictionary = {&"ui_click": -15.0, &"ballista": -15.0, &"impact": -18.0,
    &"freeze": -12.0, &"upgrade": -14.0, &"groan_a": -14.0, &"groan_b": -14.0}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var tags: Array[StringName] = []
var last_played: Dictionary = {}
var is_muted: bool = false
var combat_paused: bool = false


func _ready() -> void:
    if AudioServer.get_bus_index("SFX") < 0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
    for effect: StringName in GAINS:
        streams[effect] = load("res://assets/audio/sfx/%s.wav" % effect)
    for index: int in 10:
        var voice := AudioStreamPlayer.new()
        voice.bus = "SFX"
        add_child(voice)
        voices.append(voice)
        tags.append(&"")
    get_tree().node_added.connect(_node_added)
    _bind_tree(get_tree().root)


func _bind_tree(node: Node) -> void:
    _node_added(node)
    for child: Node in node.get_children():
        _bind_tree(child)


func _node_added(node: Node) -> void:
    if node is BaseButton:
        _bind_button.call_deferred(node)


func _bind_button(button: Variant) -> void:
    if is_instance_valid(button) and not button.pressed.is_connected(_button_clicked):
        button.pressed.connect(_button_clicked)


func _button_clicked() -> void:
    play(&"ui_click")


func play(effect: StringName) -> bool:
    if is_muted or not streams.has(effect) or (combat_paused and effect != &"ui_click"):
        return false
    var group: StringName = &"groan" if str(effect).begins_with("groan") else effect
    var now: int = Time.get_ticks_msec()
    var gap: int = 1800 if group == &"groan" else (35 if group == &"ui_click" else 55)
    if now - int(last_played.get(group, -10000)) < gap:
        return false
    for index: int in voices.size():
        var voice: AudioStreamPlayer = voices[index]
        if voice.playing:
            continue
        voice.stream_paused = false
        voice.stream = streams[effect]
        voice.volume_db = GAINS[effect]
        voice.pitch_scale = randf_range(0.93, 1.04) if group == &"groan" else 1.0
        tags[index] = effect
        last_played[group] = now
        voice.play()
        effect_played.emit(effect)
        return true
    return false


func set_combat_paused(value: bool) -> void:
    combat_paused = value
    for index: int in voices.size():
        if tags[index] != &"ui_click":
            voices[index].stream_paused = value


func toggle_mute() -> void:
    is_muted = not is_muted
    AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), is_muted)
    mute_changed.emit(is_muted)


func stop_combat() -> void:
    for index: int in voices.size():
        if tags[index] != &"ui_click":
            voices[index].stop()
            voices[index].stream = null
    set_combat_paused(false)


func stop_all() -> void:
    for voice: AudioStreamPlayer in voices:
        voice.stop()
        voice.stream = null


func _exit_tree() -> void:
    stop_all()
