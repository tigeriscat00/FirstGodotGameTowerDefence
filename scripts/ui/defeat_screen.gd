extends Control
## Defeat screen with brief, repeating drawn lightning strikes.

signal restart_requested
signal menu_requested

@export_range(1.0, 8.0) var strike_interval: float = 2.8
var elapsed: float = 0.0
var entrance: Tween

func _ready() -> void:
	$Effects.draw.connect(_draw_lightning)
	$Content/Restart.pressed.connect(func() -> void: restart_requested.emit())
	$Content/Menu.pressed.connect(func() -> void: menu_requested.emit())
	set_process(false)

func show_defeat() -> void:
	if visible:
		return
	elapsed = 0.0
	show()
	set_process(true)
	$Content.scale = Vector2.ONE * 0.82
	$Content.modulate.a = 0.0
	entrance = create_tween().set_parallel(true)
	entrance.tween_property($Content, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property($Content, "modulate:a", 1.0, 0.28)
	$Content/Restart.grab_focus()
	$Effects.queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	$Effects.queue_redraw()

func _draw_lightning() -> void:
	var age: float = fposmod(elapsed, maxf(strike_interval, 0.1))
	if age > 0.42:
		return
	# A short double flash gives the lightning a strike rather than a steady glow.
	var brightness: float = 1.0 - age / 0.42
	if age > 0.12 and age < 0.20:
		brightness *= 0.3
	var canvas: Control = $Effects
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.42, 0.62, 1.0, 0.12 * brightness))
	var bolts: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(160, 0), Vector2(205, 84), Vector2(167, 145), Vector2(237, 218), Vector2(203, 277), Vector2(286, 360)]),
		PackedVector2Array([Vector2(990, 0), Vector2(946, 71), Vector2(976, 132), Vector2(919, 195), Vector2(953, 249), Vector2(875, 343)])
	]
	for bolt: PackedVector2Array in bolts:
		canvas.draw_polyline(bolt, Color(0.32, 0.58, 1.0, 0.32 * brightness), 16.0, true)
		canvas.draw_polyline(bolt, Color(0.65, 0.85, 1.0, 0.75 * brightness), 7.0, true)
		canvas.draw_polyline(bolt, Color(0.95, 0.98, 1.0, brightness), 2.5, true)
		var branch := PackedVector2Array([bolt[2], bolt[2] + Vector2(-42, 24), bolt[2] + Vector2(-65, 70)])
		canvas.draw_polyline(branch, Color(0.75, 0.89, 1.0, 0.7 * brightness), 3.0, true)
