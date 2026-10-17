extends Control
## A mouse-transparent, gently pulsing outline with small travelling sparkles.

var focus_rect: Rect2
var focus_id: String = ""
var elapsed: float = 0.0
var outline := StyleBoxFlat.new()
var follow_target: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    outline.draw_center = false
    outline.set_border_width_all(2)
    outline.set_corner_radius_all(10)
    outline.shadow_color = Color(1, 0.7, 0.22, 0.18)
    outline.shadow_size = 8


func focus(id: String, rect: Rect2 = Rect2(), target: Control = null) -> void:
    if focus_id != id:
        elapsed = 0.0
    focus_id = id
    focus_rect = rect
    follow_target = target
    visible = not id.is_empty()
    queue_redraw()


func _process(delta: float) -> void:
    if visible:
        elapsed += delta
        queue_redraw()


func _draw() -> void:
    if focus_id.is_empty():
        return
    if is_instance_valid(follow_target):
        focus_rect = follow_target.get_global_rect()
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 3.0)
    outline.border_color = Color(1, 0.84, 0.38, 0.65 + pulse * 0.35)
    var rect: Rect2 = focus_rect.grow(4.0 + pulse * 2.0)
    draw_style_box(outline, rect)
    var perimeter: float = 2.0 * (rect.size.x + rect.size.y)
    for index: int in 4:
        var distance: float = fposmod(elapsed * 55.0 + index * perimeter / 4.0, perimeter)
        var point: Vector2 = rect.position
        if distance < rect.size.x:
            point += Vector2(distance, 0)
        elif distance < rect.size.x + rect.size.y:
            point += Vector2(rect.size.x, distance - rect.size.x)
        elif distance < rect.size.x * 2.0 + rect.size.y:
            point += Vector2(rect.size.x * 2.0 + rect.size.y - distance, rect.size.y)
        else:
            point += Vector2(0, perimeter - distance)
        var radius: float = 3.0 + 2.0 * sin(elapsed * 3.0 + index)
        draw_colored_polygon(PackedVector2Array([
            point + Vector2(0, -radius * 1.6), point + Vector2(radius, 0),
            point + Vector2(0, radius * 1.6), point + Vector2(-radius, 0)
        ]), Color(1, 0.93, 0.64, 0.9))
