extends RefCounted
## Shared colours, theme and small widget helpers.

const C_PANEL := Color(0.06, 0.08, 0.13, 0.96)
const C_PANEL_LIGHT := Color(0.11, 0.14, 0.21, 1.0)
const C_BORDER := Color("#4fc3c9")
const C_GOLD := Color("#f2c14e")
const C_TEXT := Color("#eef2f6")
const C_MUTED := Color("#9aa7b6")
const C_GOOD := Color("#6fcf97")
const C_BAD := Color("#e2574c")
const C_QUESTION := Color("#f2c14e")
const C_CHALLENGE := Color("#e2574c")
const C_EVIDENCE := Color("#4a90e2")
const C_CONSULT := Color("#5cb85c")


static func box(bg: Color, border: Color, bw: int = 1, radius: int = 4, pad: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = max(2, pad - 3)
	s.content_margin_bottom = max(2, pad - 3)
	return s


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 12
	t.set_stylebox("normal", "Button", box(Color(0.12, 0.16, 0.24), Color(0.30, 0.40, 0.50)))
	t.set_stylebox("hover", "Button", box(Color(0.17, 0.25, 0.35), C_BORDER))
	t.set_stylebox("pressed", "Button", box(Color(0.08, 0.30, 0.34), C_BORDER))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), C_GOLD, 2))
	t.set_stylebox("disabled", "Button", box(Color(0.09, 0.10, 0.13), Color(0.20, 0.22, 0.27)))
	t.set_color("font_color", "Button", C_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.48, 0.55))
	t.set_stylebox("panel", "PanelContainer", box(C_PANEL, C_BORDER, 1, 6, 8))
	t.set_stylebox("panel", "Panel", box(C_PANEL, C_BORDER, 1, 6, 8))
	t.set_color("font_color", "Label", C_TEXT)
	t.set_color("default_color", "RichTextLabel", C_TEXT)
	t.set_color("font_color", "CheckBox", C_TEXT)
	t.set_stylebox("focus", "CheckBox", box(Color(0, 0, 0, 0), C_GOLD, 1))
	t.set_stylebox("focus", "OptionButton", box(Color(0, 0, 0, 0), C_GOLD, 2))
	t.set_stylebox("normal", "OptionButton", box(Color(0.12, 0.16, 0.24), Color(0.30, 0.40, 0.50)))
	t.set_stylebox("hover", "OptionButton", box(Color(0.17, 0.25, 0.35), C_BORDER))
	return t


static func label(text: String, size: int = 12, color: Color = C_TEXT, wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, accent: Color = Color(0, 0, 0, 0), size: int = 12, wrap: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	if wrap:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if accent.a > 0.0:
		b.add_theme_stylebox_override("normal", box(accent.darkened(0.55), accent, 1))
		b.add_theme_stylebox_override("hover", box(accent.darkened(0.35), accent.lightened(0.3), 2))
		b.add_theme_stylebox_override("pressed", box(accent.darkened(0.2), Color.WHITE, 2))
	return b


static func panel(bg: Color = C_PANEL, border: Color = C_BORDER, pad: int = 8) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, 1, 6, pad))
	return p


## A full-screen dimmed modal holder with a centred panel. Returns [root, content_vbox].
static func modal(parent: Control, width: float, title: String, accent: Color = C_BORDER) -> Array:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := panel(C_PANEL, accent, 10)
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	if title != "":
		v.add_child(label(title, 14, accent))
	parent.add_child(root)
	return [root, v]
