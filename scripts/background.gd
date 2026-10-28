extends Control
## Shows a 320x180 pixel-art background (res://art/backgrounds/<ID>.png) scaled 2x.

var bg_id := "BG01"
var _tex: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_bg(bg_id)


func set_bg(id: String) -> void:
	bg_id = id
	var path := "res://art/backgrounds/%s.png" % id
	_tex = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size if size.x > 0.0 else Vector2(640, 360))
	if _tex:
		draw_texture_rect(_tex, r, false)
	else:
		draw_rect(r, Color("#10162a"))
