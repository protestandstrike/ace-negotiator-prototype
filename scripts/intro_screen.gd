extends Control
## Introduction: setting, cast and how-to-play pages, then the Case 1 title card.
## Text is prototype narration drawn from the GDD (sections 1-4); it is not script dialogue.

signal finished

const UI := preload("res://scripts/ui_kit.gd")
const Background := preload("res://scripts/background.gd")
const SpriteActor := preload("res://scripts/sprite_actor.gd")

const PAGES := [
	{"bg": "TITLE", "cast": [], "title": "Sweden · June 2026",
		"text": "Across the country, workplaces are reorganising.\nSome workers are told that their jobs have simply disappeared."},
	{"bg": "BG01", "cast": [], "title": "The United Workers' Federation",
		"text": "The UWF is a (fictional) trade union. Its representatives help workers question decisions, check the evidence and negotiate with employers."},
	{"bg": "BG01", "cast": ["VERA_JUSTICE"], "title": "Vera Justice, 29",
		"text": "A new UWF regional representative. Not long ago her own employer, Synergia, dismissed her — and that dispute is still unresolved.\nVera knows how unfairness feels. She is still learning that feeling something strongly is not the same as proving it."},
	{"bg": "BG01", "cast": ["AUDREY_ORDER", "LAURENCE_ABBOTT", "SALLY_DARITY"], "title": "Vera's team",
		"text": "Audrey Order (56) — senior lead. Checks mandates and conflicts.\nLaurence Abbott (41) — legal adviser. Keeps facts, law and authority apart.\nSally Darity (32) — organiser. Makes sure taking part is always voluntary."},
	{"bg": "BG03", "cast": ["JULIAN_VANE"], "title": "Across the table",
		"text": "Julian Vane (35) — employer-side lawyer.\nCalm, precise, and very quick to notice a claim you cannot support."},
	{"bg": "BG01", "cast": [], "title": "How this job works",
		"text": "1.  Separate what someone says from what a document shows.\n2.  Workers decide for themselves — about their own claims, and about whether to give a statement.\n3.  Nobody accepts anything without real, recorded authority."},
	{"bg": "BG03", "cast": [], "title": "Negotiations", "actions": true,
		"text": "Momentum starts at 5. A wrong record costs 1. If it runs out, you go back to the start of that phase — nothing you verified is lost."},
	{"bg": "BG12", "cast": [], "title": "Records and puzzles",
		"text": "A record can only be used once it is verified. Setting one aside and recording a gap is allowed.\nPuzzles accept a full finding, a limited finding or \"not enough information\" — pick what the record actually supports. Hints are free. There are no timers."},
]

var _page := -1
var _bg: Control
var _cast_holder: Control
var _title: Label
var _text: Label
var _extra: Control
var _counter: Label
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = Background.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_cast_holder = Control.new()
	_cast_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cast_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cast_holder)

	var p := UI.panel(Color(0.05, 0.07, 0.12, 0.93), UI.C_BORDER, 12)
	p.position = Vector2(20, 196)
	p.size = Vector2(600, 150)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	_title = UI.label("", 15, UI.C_GOLD)
	v.add_child(_title)
	_extra = HBoxContainer.new()
	_extra.add_theme_constant_override("separation", 4)
	v.add_child(_extra)
	_text = UI.label("", 12)
	v.add_child(_text)

	_counter = UI.label("", 10, UI.C_MUTED, false)
	_counter.position = Vector2(500, 330)
	add_child(_counter)
	var skip := UI.button("Skip intro", Color(0, 0, 0, 0), 10)
	skip.focus_mode = Control.FOCUS_NONE
	skip.position = Vector2(560, 6)
	skip.pressed.connect(_finish)
	add_child(skip)
	_next()


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_next()
	elif ev is InputEventScreenTouch and ev.pressed:
		_next()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_accept") or (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_SPACE):
		get_viewport().set_input_as_handled()
		_next()
	elif ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_finish()


func _next() -> void:
	if _busy:
		return
	_page += 1
	if _page >= PAGES.size():
		_finish()
		return
	var pg: Dictionary = PAGES[_page]
	_bg.set_bg(pg["bg"])
	_title.text = pg["title"]
	_text.text = pg["text"]
	_counter.text = "%d / %d   ·   click or Enter ▶" % [_page + 1, PAGES.size()]
	for c in _cast_holder.get_children():
		c.queue_free()
	var cast: Array = pg["cast"]
	for i in cast.size():
		var por := SpriteActor.new()
		por.setup(cast[i], 2)
		por.position = Vector2(320 - cast.size() * 60 + i * 120 + 60 - por.size.x * 0.5, 200 - por.size.y)
		_cast_holder.add_child(por)
		por.play("A12", "A01")
		var nm := UI.label(GS.speaker_name(cast[i]), 10, Color(GS.SPEAKERS[cast[i]]["color"]), false)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = por.position + Vector2(9, -12)
		nm.custom_minimum_size = Vector2(110, 0)
		_cast_holder.add_child(nm)
	for c in _extra.get_children():
		c.queue_free()
	if pg.get("actions", false):
		for a in [["QUESTION!", UI.C_QUESTION, "ask for a missing detail · free"], ["CHALLENGE!", UI.C_CHALLENGE, "state a supported objection"],
				["EVIDENCE!", UI.C_EVIDENCE, "present a verified record"], ["CONSULT", UI.C_CONSULT, "ask Laurence · free"]]:
			var chip := UI.label("%s\n%s" % [a[0], a[2]], 9, Color.WHITE)
			chip.add_theme_stylebox_override("normal", UI.box(a[1].darkened(0.5), a[1], 1, 4, 5))
			chip.custom_minimum_size = Vector2(140, 0)
			_extra.add_child(chip)
	var gs := get_node_or_null("/root/GS")
	if gs and OS.get_cmdline_user_args().has("--autotest"):
		_busy = true
		await get_tree().create_timer(0.25).timeout
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--shots="):
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(a.substr(8).path_join("intro_%02d.png" % (_page + 1)))
		_busy = false
		_next()


func _finish() -> void:
	if _page >= 999:
		return
	_page = 999
	_busy = true
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("#0b1022")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.position = Vector2(70, 120)
	v.custom_minimum_size = Vector2(500, 0)
	add_child(v)
	for spec in [["CASE 1", 14, UI.C_BORDER], ["The Restructuring", 30, UI.C_GOLD], ["Northbridge · 8–26 June 2026", 12, UI.C_MUTED]]:
		var l := UI.label(spec[0], spec[1], spec[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	v.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(v, "modulate:a", 1.0, 0.6)
	tw.tween_interval(1.6)
	tw.tween_property(v, "modulate:a", 0.0, 0.5)
	await tw.finished
	finished.emit()
