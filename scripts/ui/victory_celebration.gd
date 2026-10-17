extends Control
## Original engine-drawn crown, fireworks and confetti; no external assets.

signal quit_requested

const COLORS: Array[Color] = [Color("ffd474"), Color("70e6cc"), Color("90c8ff"), Color("ff9cab")]
var elapsed: float = 0.0
var entrance: Tween


func _ready() -> void:
    $Effects.draw.connect(_draw_effects)
    $Content.draw.connect(_draw_crown)
    $Content/Quit.pressed.connect(func() -> void: quit_requested.emit())
    set_process(false)


func celebrate() -> void:
    if visible:
        return
    elapsed = 0.0
    show()
    set_process(true)
    $Content.scale = Vector2.ONE * 0.75
    $Content.modulate.a = 0.0
    $Content/Quit.visible = false
    entrance = create_tween().set_parallel(true)
    entrance.tween_property($Content, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    entrance.tween_property($Content, "modulate:a", 1.0, 0.45)


func _process(delta: float) -> void:
    elapsed += delta
    if elapsed >= 1.2 and not $Content/Quit.visible:
        $Content/Quit.show()
        $Content/Quit.grab_focus()
    $Effects.queue_redraw()
    $Content.queue_redraw()


func _draw_crown() -> void:
    var center := Vector2(280, 110 + sin(elapsed * 2.0) * 5.0)
    for index: int in 32:
        var angle: float = index * TAU / 32.0 + elapsed * 0.07
        var direction := Vector2.from_angle(angle)
        $Content.draw_line(center + direction * 95.0, center + direction * (135.0 + 12.0 * sin(elapsed + index)), Color(1, 0.8, 0.35, 0.16), 3.0, true)
    $Content.draw_circle(center, 92.0, Color(1, 0.75, 0.25, 0.06))
    $Content.draw_arc(center, 98, 0, TAU, 80, Color(1, 0.83, 0.4, 0.55), 2, true)
    var shape := PackedVector2Array([
        center + Vector2(-74, -35), center + Vector2(-40, -8),
        center + Vector2(0, -65), center + Vector2(40, -8),
        center + Vector2(74, -35), center + Vector2(58, 48), center + Vector2(-58, 48)
    ])
    $Content.draw_colored_polygon(shape, Color("f5c45b"))
    $Content.draw_polyline(shape + PackedVector2Array([shape[0]]), Color("fff0b3"), 3, true)
    $Content.draw_line(center + Vector2(-58, 30), center + Vector2(58, 30), Color("996b30"), 7, true)
    $Content.draw_colored_polygon(PackedVector2Array([
        center + Vector2(0, -12), center + Vector2(12, 4),
        center + Vector2(0, 20), center + Vector2(-12, 4)
    ]), Color("39bda8"))


func _draw_effects() -> void:
    var canvas: Control = $Effects
    # Repeating bursts frame the central message, keeping the Quit button clear.
    for burst: int in 5:
        var age: float = fposmod(elapsed + burst * 0.67, 3.5)
        if age > 1.8:
            continue
        var origin := Vector2(150 + burst * 210, 130 + (burst % 2) * 110)
        for ray: int in 18:
            var direction := Vector2.from_angle(ray * TAU / 18.0 + burst)
            var position: Vector2 = origin + direction * age * 95.0 + Vector2(0, age * age * 24.0)
            var color: Color = COLORS[burst % COLORS.size()]
            color.a = (1.0 - age / 1.8) * 0.85
            canvas.draw_line(position - direction * 8, position, color, 3, true)
    for index: int in 110:
        var x: float = fposmod(index * 97.0 + sin(elapsed + index) * 35.0, size.x)
        var y: float = fposmod(index * 73.0 + elapsed * (48.0 + index % 7 * 7.0), size.y + 40.0) - 20.0
        var color: Color = COLORS[index % COLORS.size()]
        color.a = 0.75
        var direction := Vector2.from_angle(elapsed * 2.0 + index) * 4.0
        canvas.draw_line(Vector2(x, y) - direction, Vector2(x, y) + direction, color, 3, true)
