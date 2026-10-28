extends Control
## Title screen: New game / Continue / Settings / Quit.

signal new_game
signal continue_game

const UI := preload("res://scripts/ui_kit.gd")
const Background := preload("res://scripts/background.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := Background.new()
	bg.bg_id = "TITLE"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := UI.label("ACE NEGOTIATOR", 40, UI.C_GOLD, false)
	title.add_theme_color_override("font_outline_color", Color("#0b1022"))
	title.add_theme_constant_override("outline_size", 6)
	title.position = Vector2(40, 50)
	add_child(title)
	var sub := UI.label("Facts. Consent. Authority.", 14, UI.C_BORDER, false)
	sub.position = Vector2(44, 102)
	add_child(sub)
	var proto := UI.label("PROTOTYPE · Introduction + Case 1: The Restructuring", 10, UI.C_MUTED, false)
	proto.position = Vector2(44, 124)
	add_child(proto)

	var v := VBoxContainer.new()
	v.position = Vector2(44, 160)
	v.custom_minimum_size = Vector2(200, 0)
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var b_new := UI.button("New game", UI.C_BORDER, 13)
	b_new.pressed.connect(func(): new_game.emit())
	v.add_child(b_new)
	var b_cont := UI.button("Continue", UI.C_BORDER, 13)
	b_cont.disabled = not GS.has_save()
	b_cont.pressed.connect(func(): continue_game.emit())
	v.add_child(b_cont)
	var b_set := UI.button("Settings", Color(0, 0, 0, 0), 13)
	b_set.pressed.connect(_open_settings)
	v.add_child(b_set)
	if OS.get_name() != "Web":
		var b_quit := UI.button("Quit", Color(0, 0, 0, 0), 13)
		b_quit.pressed.connect(func(): get_tree().quit())
		v.add_child(b_quit)
	(b_cont if not b_cont.disabled else b_new).call_deferred("grab_focus")

	var foot := UI.label("An educational work of fiction. Not legal advice. All organisations and people are fictional.", 9, UI.C_MUTED, false)
	foot.position = Vector2(44, 338)
	add_child(foot)

	# Character line-up on the right
	var Portrait := preload("res://scripts/portrait.gd")
	var ids := ["LAURENCE_ABBOTT", "AUDREY_ORDER", "VERA_JUSTICE", "SALLY_DARITY"]
	for i in ids.size():
		var p := Portrait.new()
		p.setup(ids[i])
		var big: bool = ids[i] == "VERA_JUSTICE"
		p.size = Vector2(130, 190) if big else Vector2(100, 146)
		p.position = Vector2(300 + i * 80 - (15 if big else 0), 340 - p.size.y)
		p.z_index = 2 if big else 0
		if not big:
			p.modulate = Color(0.75, 0.78, 0.85)
		add_child(p)


func _open_settings() -> void:
	var sp = SettingsPanel.new()
	add_child(sp)
	await sp.closed
