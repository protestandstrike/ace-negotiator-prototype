extends Control
## Placeholder backgrounds drawn in code, one per approved BG ID used in Case 1.

var bg_id := "BG01"


func set_bg(id: String) -> void:
	bg_id = id
	queue_redraw()


func _grad(rect: Rect2, top: Color, bottom: Color, bands: int = 24) -> void:
	var bh := rect.size.y / bands
	for i in range(bands):
		draw_rect(Rect2(rect.position.x, rect.position.y + i * bh, rect.size.x, bh + 1.0), top.lerp(bottom, float(i) / (bands - 1)))


func _text(pos: Vector2, s: String, size: int, col: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x if size.x > 0.0 else 640.0
	var h := size.y if size.y > 0.0 else 360.0
	match bg_id:
		"BG01": _union_office(w, h)
		"BG02": _consultation(w, h)
		"BG03": _negotiation(w, h)
		"BG05": _tech_office(w, h)
		"BG12": _archive(w, h)
		_: _title(w, h)


func _title(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h), Color("#0b1022"), Color("#1d2b4a"))
	for i in range(14):
		var x := -200.0 + i * 70.0
		draw_line(Vector2(x, h), Vector2(x + 260, 0), Color(0.31, 0.76, 0.79, 0.07), 18.0)
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color(0, 0, 0, 0.25))


func _union_office(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h * 0.72), Color("#e9dcc3"), Color("#d4c2a2"))
	_grad(Rect2(0, h * 0.72, w, h * 0.28), Color("#8a5f3c"), Color("#5e3f27"), 8)
	for i in range(9):
		draw_line(Vector2(0, h * 0.72 + i * 12), Vector2(w, h * 0.72 + i * 12), Color(0, 0, 0, 0.12), 1.0)
	# Window
	draw_rect(Rect2(40, 40, 150, 120), Color("#9fd3ef"))
	draw_rect(Rect2(40, 120, 150, 40), Color("#7fb98a"))
	draw_rect(Rect2(40, 40, 150, 120), Color("#f6f1e6"), false, 6.0)
	draw_line(Vector2(115, 40), Vector2(115, 160), Color("#f6f1e6"), 4.0)
	# Notice board
	draw_rect(Rect2(250, 50, 170, 105), Color("#b98b57"))
	draw_rect(Rect2(250, 50, 170, 105), Color("#6e4b2a"), false, 4.0)
	var notes := [Color("#fff59d"), Color("#90caf9"), Color("#f8bbd0"), Color("#c5e1a5"), Color("#ffe0b2")]
	for i in range(7):
		draw_rect(Rect2(262 + (i % 4) * 39, 62 + (i / 4) * 44, 30, 32), notes[i % notes.size()])
	# UWF poster
	draw_rect(Rect2(470, 40, 110, 140), Color("#2f7f86"))
	draw_rect(Rect2(478, 48, 94, 124), Color("#f4efe6"), false, 2.0)
	_text(Vector2(492, 100), "UWF", 30, Color("#f4efe6"))
	_text(Vector2(484, 125), "TOGETHER, BY", 10, Color("#f2c14e"))
	_text(Vector2(484, 139), "THE RECORD", 10, Color("#f2c14e"))
	# Desk
	draw_rect(Rect2(400, 215, 240, 20), Color("#6d4c33"))
	draw_rect(Rect2(410, 235, 14, 60), Color("#5a3e29"))
	draw_rect(Rect2(615, 235, 14, 60), Color("#5a3e29"))
	draw_rect(Rect2(450, 195, 50, 20), Color("#fafafa"))
	draw_rect(Rect2(455, 190, 50, 20), Color("#eeeeee"))
	# Plant
	draw_rect(Rect2(12, 230, 26, 34), Color("#a0522d"))
	for i in range(6):
		draw_circle(Vector2(25 + (i - 2.5) * 6, 222 - absf(i - 2.5) * -4 - 10), 10, Color("#4c8c4a"))


func _consultation(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h * 0.7), Color("#c9d6cf"), Color("#a9bdb1"))
	_grad(Rect2(0, h * 0.7, w, h * 0.3), Color("#6c7a86"), Color("#4b5661"), 8)
	# Picture frames
	draw_rect(Rect2(70, 50, 120, 80), Color("#f5f0e6"))
	draw_rect(Rect2(70, 50, 120, 80), Color("#7b5e3b"), false, 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(78, 122), Vector2(120, 75), Vector2(150, 105), Vector2(182, 122)]), Color("#7fa98a"))
	draw_circle(Vector2(160, 72), 9, Color("#f2c14e"))
	draw_rect(Rect2(450, 45, 90, 110), Color("#e7ddc9"))
	draw_rect(Rect2(450, 45, 90, 110), Color("#7b5e3b"), false, 5.0)
	# Lamp
	draw_rect(Rect2(588, 120, 6, 130), Color("#3a3a3a"))
	draw_colored_polygon(PackedVector2Array([Vector2(570, 120), Vector2(612, 120), Vector2(602, 95), Vector2(580, 95)]), Color("#f5e6c4"))
	# Table
	draw_rect(Rect2(170, 225, 300, 18), Color("#8b6a4a"))
	draw_rect(Rect2(310, 243, 20, 70), Color("#6b5038"))
	draw_rect(Rect2(250, 212, 22, 14), Color("#ffffff"))
	draw_rect(Rect2(370, 205, 14, 20), Color(0.7, 0.85, 0.95, 0.8))


func _negotiation(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h), Color("#1c2333"), Color("#2c3546"))
	# Windows with skyline
	for i in range(4):
		var x := 30.0 + i * 150.0
		_grad(Rect2(x, 25, 130, 170), Color("#2d4a73"), Color("#8aa6c8"), 12)
		for b in range(5):
			var bx := x + 6 + b * 25
			var bh := 40.0 + float((i * 7 + b * 13) % 70)
			draw_rect(Rect2(bx, 195 - bh, 20, bh), Color("#1a2638"))
			for wy in range(int(bh / 12)):
				if (b + wy + i) % 3 != 0:
					draw_rect(Rect2(bx + 4, 195 - bh + 5 + wy * 12, 4, 4), Color("#f2d27a"))
		draw_rect(Rect2(x, 25, 130, 170), Color("#0f1520"), false, 5.0)
	# Logo plaque
	draw_rect(Rect2(250, 202, 140, 18), Color("#0f1520"))
	_text(Vector2(266, 216), "NORTHBRIDGE", 12, Color("#c9d3df"))
	# Long table
	draw_colored_polygon(PackedVector2Array([Vector2(0, 280), Vector2(w, 280), Vector2(w, h), Vector2(0, h)]), Color("#3b2a20"))
	draw_rect(Rect2(0, 272, w, 10), Color("#5a3f2e"))


func _tech_office(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h * 0.75), Color("#eef4fa"), Color("#d5e2ee"))
	_grad(Rect2(0, h * 0.75, w, h * 0.25), Color("#9aa9b8"), Color("#7b8a99"), 6)
	for i in range(5):
		draw_rect(Rect2(40 + i * 130, 12, 80, 6), Color("#ffffff"))
	# Whiteboard org chart
	draw_rect(Rect2(200, 40, 240, 140), Color("#ffffff"))
	draw_rect(Rect2(200, 40, 240, 140), Color("#9aa9b8"), false, 3.0)
	draw_rect(Rect2(295, 55, 50, 20), Color("#4a90e2"))
	for i in range(3):
		var x := 225.0 + i * 70.0
		draw_line(Vector2(320, 75), Vector2(x + 25, 100), Color("#556677"), 1.5)
		draw_rect(Rect2(x, 100, 50, 20), Color("#90caf9"))
		draw_line(Vector2(x + 25, 120), Vector2(x + 25, 140), Color("#556677"), 1.5)
		draw_rect(Rect2(x + 5, 140, 40, 16), Color("#cfe3f7") if i != 1 else Color(0, 0, 0, 0))
	draw_rect(Rect2(300, 140, 40, 16), Color("#e2574c"), false, 1.5)
	_text(Vector2(312, 152), "?", 12, Color("#e2574c"))
	# Desks + monitors
	for x in [30.0, 500.0]:
		draw_rect(Rect2(x, 225, 120, 10), Color("#ffffff"))
		draw_rect(Rect2(x + 30, 185, 60, 38), Color("#263238"))
		draw_rect(Rect2(x + 33, 188, 54, 32), Color("#4fc3c9"))
		draw_rect(Rect2(x + 57, 223, 6, 4), Color("#263238"))
	# Glass partition
	for i in range(3):
		draw_line(Vector2(170 + i * 150, 0), Vector2(170 + i * 150, h * 0.75), Color(1, 1, 1, 0.5), 2.0)


func _archive(w: float, h: float) -> void:
	_grad(Rect2(0, 0, w, h), Color("#3b3326"), Color("#241f17"))
	var box_cols := [Color("#a67c52"), Color("#8c6239"), Color("#c49a6c"), Color("#b0855a")]
	for shelf in range(4):
		var y := 30.0 + shelf * 58.0
		draw_rect(Rect2(20, y + 44, w - 40, 6), Color("#5a4630"))
		for i in range(14):
			var bw := 30.0 + float((i * 17 + shelf * 5) % 14)
			var x := 26.0 + i * 43.0
			if x + bw > w - 24:
				break
			draw_rect(Rect2(x, y + 44 - 34, bw, 34), box_cols[(i + shelf) % 4])
			draw_rect(Rect2(x + bw * 0.3, y + 44 - 24, bw * 0.4, 8), Color("#f1e7d0"))
	# Lamp glow + desk with documents
	draw_circle(Vector2(w * 0.5, 0), 160, Color(1.0, 0.85, 0.5, 0.08))
	draw_rect(Rect2(120, 270, 400, 16), Color("#5b4128"))
	for i in range(4):
		draw_rect(Rect2(170 + i * 80, 258 - i * 2, 56, 14 + i * 2), Color("#f4ecd8"))
