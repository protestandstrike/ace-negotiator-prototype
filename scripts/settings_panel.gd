extends Control
## Reading and accessibility settings (text speed, size, reduced motion).

signal closed

const UI := preload("res://scripts/ui_kit.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UI.panel(UI.C_PANEL, UI.C_BORDER, 12)
	p.custom_minimum_size = Vector2(360, 0)
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UI.label("SETTINGS", 14, UI.C_BORDER))

	var speed := _option(v, "Text speed", ["Slow", "Normal", "Fast", "Instant"], int(GS.settings["text_speed"]))
	speed.item_selected.connect(func(i): GS.settings["text_speed"] = i)
	var tsize := _option(v, "Text size", ["Small", "Normal", "Large"], int(GS.settings["text_size"]))
	tsize.item_selected.connect(func(i): GS.settings["text_size"] = i)

	var rm := CheckBox.new()
	rm.text = "Reduced motion (no bobbing, quick fades)"
	rm.add_theme_font_size_override("font_size", 11)
	rm.button_pressed = bool(GS.settings["reduced_motion"])
	rm.toggled.connect(func(on): GS.settings["reduced_motion"] = on)
	v.add_child(rm)

	v.add_child(UI.label("Choices never auto-advance. There are no timers in this game.", 10, UI.C_MUTED))
	var done := UI.button("Done", UI.C_BORDER)
	done.alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.pressed.connect(_close)
	v.add_child(done)
	speed.call_deferred("grab_focus")


func _option(v: VBoxContainer, title: String, items: Array, selected: int) -> OptionButton:
	var h := HBoxContainer.new()
	var l := UI.label(title, 12, UI.C_TEXT, false)
	l.custom_minimum_size = Vector2(120, 0)
	h.add_child(l)
	var o := OptionButton.new()
	o.add_theme_font_size_override("font_size", 12)
	for it in items:
		o.add_item(it)
	o.select(selected)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(o)
	v.add_child(h)
	return o


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	GS.save_settings()
	closed.emit()
	queue_free()
