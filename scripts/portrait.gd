extends Control
## Placeholder character bust, drawn in code (no art assets yet).
## Mouth flaps while speaking, eyes blink, inactive characters are dimmed.

var look: Dictionary = {}
var speaking := false
var active := false

var _t := 0.0
var _mouth_open := false
var _mouth_timer := 0.0
var _blink_left := 0.0
var _next_blink := 2.5


func setup(speaker_id: String) -> void:
	look = GS.SPEAKERS.get(speaker_id, {}).get("look", {})
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_next_blink = randf_range(1.5, 4.0)


func _process(delta: float) -> void:
	_t += delta
	if speaking:
		_mouth_timer -= delta
		if _mouth_timer <= 0.0:
			_mouth_open = not _mouth_open
			_mouth_timer = 2.0 / 22.0  # authored 22 FPS, flap every 2 frames
	else:
		_mouth_open = false
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink_left = 0.12
		_next_blink = randf_range(2.0, 5.0)
	_blink_left = max(0.0, _blink_left - delta)
	queue_redraw()


func _col(key: String, fallback: String) -> Color:
	return Color(look.get(key, fallback))


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
	draw_circle(Vector2.ZERO, r.x, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _arc_poly(c: Vector2, r: float, a0: float, a1: float, extra: PackedVector2Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(17):
		var a := lerpf(a0, a1, i / 16.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	pts.append_array(extra)
	return pts


func _draw() -> void:
	if look.is_empty():
		return
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var bob := 0.0
	if speaking and not GS.settings.get("reduced_motion", false):
		bob = sin(_t * 9.0) * 1.2
	var r := w * 0.2
	var hc := Vector2(cx, h * 0.40 + bob)
	var skin := _col("skin", "#e0b090")
	var hair := _col("hair", "#333333")
	var clothes := _col("clothes", "#445566")
	var shirt := _col("shirt", "#eeeeee")
	var style: String = look.get("style", "short")
	var acc: String = look.get("acc", "")
	var outline := Color(0, 0, 0, 0.35)

	# Back hair (behind head)
	match style:
		"ponytail":
			_ellipse(hc + Vector2(r * 0.95, r * 0.55), Vector2(r * 0.38, r * 0.75), hair)
		"bob":
			draw_rect(Rect2(hc.x - r * 1.12, hc.y - r * 0.3, r * 2.24, r * 1.25), hair)
		"long":
			draw_rect(Rect2(hc.x - r * 1.1, hc.y - r * 0.3, r * 2.2, r * 2.1), hair)
		"curly":
			for i in range(11):
				var a := lerpf(PI * 0.85, PI * 2.15, i / 10.0)
				draw_circle(hc + Vector2(cos(a), sin(a)) * r * 1.0, r * 0.42, hair)

	# Shoulders / jacket
	var top := hc.y + r * 1.35
	var body := PackedVector2Array([
		Vector2(cx - r * 0.7, top), Vector2(cx + r * 0.7, top),
		Vector2(cx + r * 2.1, top + r * 0.9), Vector2(cx + r * 2.35, h),
		Vector2(cx - r * 2.35, h), Vector2(cx - r * 2.1, top + r * 0.9)])
	draw_colored_polygon(body, clothes)
	draw_polyline(body + PackedVector2Array([body[0]]), outline, 1.0)
	# Shirt V
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - r * 0.55, top), Vector2(cx + r * 0.55, top), Vector2(cx, top + r * 1.25)]), shirt)
	# Neck
	draw_rect(Rect2(cx - r * 0.32, hc.y + r * 0.7, r * 0.64, r * 0.75), skin.darkened(0.12))
	if acc.contains("tie"):
		var tie := _col("tie", "#7a2335")
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - r * 0.13, top + r * 0.05), Vector2(cx + r * 0.13, top + r * 0.05),
			Vector2(cx + r * 0.2, top + r * 1.3), Vector2(cx, top + r * 1.55), Vector2(cx - r * 0.2, top + r * 1.3)]), tie)
	if acc.contains("badge"):
		draw_line(Vector2(cx - r * 0.5, top), Vector2(cx - r * 0.9, top + r * 1.3), Color("#c0392b"), 1.5)
		draw_rect(Rect2(cx - r * 1.2, top + r * 1.25, r * 0.6, r * 0.42), Color("#f4f4f4"))
		draw_rect(Rect2(cx - r * 1.2, top + r * 1.25, r * 0.6, r * 0.12), Color("#4fc3c9"))

	# Head
	_ellipse(hc, Vector2(r, r * 1.12), skin)
	# Ears
	draw_circle(hc + Vector2(-r * 0.98, r * 0.1), r * 0.18, skin.darkened(0.05))
	draw_circle(hc + Vector2(r * 0.98, r * 0.1), r * 0.18, skin.darkened(0.05))

	# Front hair / fringe
	match style:
		"ponytail", "bob", "long":
			draw_colored_polygon(_arc_poly(hc, r * 1.08, PI * 1.0, PI * 2.0,
				PackedVector2Array([hc + Vector2(r * 0.95, -r * 0.1), hc + Vector2(r * 0.2, -r * 0.55), hc + Vector2(-r * 0.6, -r * 0.35), hc + Vector2(-r * 1.0, -r * 0.0)])), hair)
		"short":
			draw_colored_polygon(_arc_poly(hc, r * 1.06, PI * 1.02, PI * 1.98,
				PackedVector2Array([hc + Vector2(r * 0.9, -r * 0.35), hc + Vector2(-r * 0.3, -r * 0.6), hc + Vector2(-r * 0.92, -r * 0.3)])), hair)
		"slick":
			draw_colored_polygon(_arc_poly(hc, r * 1.07, PI * 1.0, PI * 2.0,
				PackedVector2Array([hc + Vector2(r * 0.95, -r * 0.3), hc + Vector2(-r * 0.1, -r * 0.72), hc + Vector2(-r * 0.95, -r * 0.2)])), hair)
			draw_line(hc + Vector2(-r * 0.35, -r * 1.0), hc + Vector2(r * 0.4, -r * 0.8), hair.lightened(0.35), 1.0)
		"curly":
			for i in range(7):
				var a := lerpf(PI * 1.1, PI * 1.9, i / 6.0)
				draw_circle(hc + Vector2(cos(a), sin(a)) * r * 0.85, r * 0.33, hair)
		"bald":
			draw_circle(hc + Vector2(-r * 0.92, -r * 0.15), r * 0.25, hair)
			draw_circle(hc + Vector2(r * 0.92, -r * 0.15), r * 0.25, hair)
	if style == "ponytail":
		draw_circle(hc + Vector2(r * 0.85, -r * 0.2), r * 0.16, Color("#c0392b"))  # hair tie

	# Eyes + brows
	var ey := hc.y + r * 0.08
	var eye_col := Color("#1c1c24")
	for sx in [-1.0, 1.0]:
		var ec := Vector2(cx + sx * r * 0.4, ey)
		if _blink_left > 0.0:
			draw_line(ec + Vector2(-r * 0.12, 0), ec + Vector2(r * 0.12, 0), eye_col, 1.5)
		else:
			draw_circle(ec, r * 0.11, eye_col)
			draw_circle(ec + Vector2(-r * 0.03, -r * 0.04), r * 0.035, Color.WHITE)
		var inner_drop := r * 0.08 if look.get("brow", "") == "worried" else 0.0
		draw_line(ec + Vector2(-sx * r * 0.18, -r * 0.27 - inner_drop), ec + Vector2(sx * r * 0.2, -r * 0.3), hair.darkened(0.2), 2.0)
	if acc.contains("glasses"):
		for sx in [-1.0, 1.0]:
			draw_rect(Rect2(cx + sx * r * 0.4 - r * 0.25, ey - r * 0.18, r * 0.5, r * 0.36), Color("#222222"), false, 1.2)
		draw_line(Vector2(cx - r * 0.15, ey - r * 0.05), Vector2(cx + r * 0.15, ey - r * 0.05), Color("#222222"), 1.0)

	# Nose + mouth
	draw_line(Vector2(cx, ey + r * 0.15), Vector2(cx - r * 0.06, ey + r * 0.38), skin.darkened(0.25), 1.2)
	var mc := Vector2(cx, hc.y + r * 0.62)
	if _mouth_open:
		_ellipse(mc, Vector2(r * 0.17, r * 0.12), Color("#7a2a2a"))
	else:
		draw_line(mc + Vector2(-r * 0.2, 0), mc + Vector2(r * 0.2, 0), Color("#7a3a3a"), 1.5)
