extends Control
## Runs the Case 1 dialogue graph: lines, choices, gates, events and scene exits.
## Builds its own UI at the 640x360 logical canvas.

signal chapter_finished
signal quit_to_title
signal _modal_choice(idx: int)

const UI := preload("res://scripts/ui_kit.gd")
const SpriteActor := preload("res://scripts/sprite_actor.gd")
const Background := preload("res://scripts/background.gd")
const SettingsPanel := preload("res://scripts/settings_panel.gd")

const STAGE_BOTTOM := 266.0

var bg: Control
var stage: Control
var top_title: Label
var neg_panel: PanelContainer
var neg_label: Label
var momentum_label: Label
var name_plate: PanelContainer
var name_label: Label
var dialogue_panel: PanelContainer
var text_label: RichTextLabel
var advance_mark: Label
var choice_layer: Control
var toast_label: Label
var modal_layer: Control
var fade: ColorRect

var portraits: Dictionary = {}
var _react_next := ""   # reaction state for the next speaker (e.g. A12 after a correction)
var current: Dictionary = {}
var mode := ""            # "line" | "choice" | "busy"
var typing := false
var _type_pos := 0.0
var _last_text := ""
var _modal_count := 0
var _choice_buttons: Array = []
var _modal_buttons: Array = []
var _toast_tween: Tween

# Automated play-through (used for testing: godot -- --autotest [--shots=DIR] [--seed=N])
var autotest := false
var _shots_dir := ""
var _shot_pending := ""
var _shot_taken: Dictionary = {}
var _auto_steps := 0
var _auto_wait := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GS.toast.connect(_on_toast)
	GS.momentum_changed.connect(func(_v): _update_neg_hud())
	GS.settings_changed.connect(_apply_settings)
	_apply_settings()
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--shots="):
			_shots_dir = a.substr(8)
		elif a.begins_with("--seed="):
			seed(int(a.substr(7)))


# ================================================================ UI construction

func _build_ui() -> void:
	bg = Background.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	stage = Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

	var catcher := Control.new()
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(_on_catcher_input)
	add_child(catcher)

	# Top bar
	var top := UI.panel(Color(0.04, 0.06, 0.1, 0.85), Color(0, 0, 0, 0), 4)
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 22)
	add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 4)
	top.add_child(th)
	top_title = UI.label("", 11, UI.C_GOLD, false)
	top_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	th.add_child(top_title)
	for spec in [["Records (E)", _open_records], ["Log (L)", _open_log], ["Menu (Esc)", _open_menu]]:
		var b := UI.button(spec[0], Color(0, 0, 0, 0), 10)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 16)
		b.pressed.connect(spec[1])
		th.add_child(b)

	# Negotiation HUD
	neg_panel = UI.panel(Color(0.25, 0.06, 0.06, 0.9), UI.C_CHALLENGE, 5)
	neg_panel.position = Vector2(388, 25)
	neg_panel.custom_minimum_size = Vector2(248, 0)
	neg_panel.visible = false
	add_child(neg_panel)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 0)
	neg_panel.add_child(nv)
	neg_label = UI.label("", 10, UI.C_TEXT)
	nv.add_child(neg_label)
	momentum_label = UI.label("", 12, UI.C_GOLD, false)
	nv.add_child(momentum_label)

	# Dialogue box
	dialogue_panel = UI.panel(Color(0.05, 0.07, 0.12, 0.94), UI.C_BORDER, 9)
	dialogue_panel.position = Vector2(8, 262)
	dialogue_panel.size = Vector2(624, 92)
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_panel)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = false
	text_label.scroll_active = false
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.custom_minimum_size = Vector2(600, 70)
	dialogue_panel.add_child(text_label)

	advance_mark = UI.label("▼", 10, UI.C_GOLD, false)
	advance_mark.position = Vector2(614, 338)
	add_child(advance_mark)

	name_plate = UI.panel(UI.C_BORDER, Color(0, 0, 0, 0), 6)
	name_plate.position = Vector2(18, 249)
	name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_plate)
	name_label = UI.label("", 11, Color("#08111a"), false)
	name_plate.add_child(name_label)

	choice_layer = Control.new()
	choice_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(choice_layer)

	toast_label = UI.label("", 11, Color.WHITE, false)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_stylebox_override("normal", UI.box(Color(0.1, 0.35, 0.3, 0.95), UI.C_GOOD, 1, 4, 8))
	toast_label.position = Vector2(8, 26)
	toast_label.custom_minimum_size = Vector2(372, 0)
	toast_label.modulate.a = 0.0
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_label)

	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)


func _apply_settings() -> void:
	if text_label:
		text_label.add_theme_font_size_override("normal_font_size", GS.text_font_size())


# ================================================================ scene flow

func begin(resume: bool) -> void:
	var sid: String = GS.state["scene_id"]
	var node: String = GS.state.get("node_id", "")
	if not resume or node == "" or not GS.nodes.has(node):
		node = GS.scenes[sid]["entry"]
	await _enter_scene(sid, node)


func _enter_scene(scene_id: String, node_id: String) -> void:
	mode = "busy"
	_clear_choices()
	GS.state["scene_id"] = scene_id
	GS.state["node_id"] = node_id
	GS.save_game()
	var sc: Dictionary = GS.scenes[scene_id]
	var num := GS.scene_number(scene_id)
	var place: String = GS.BACKGROUNDS.get(sc["background"], sc["background"])

	await _fade_to(1.0)
	_set_text("", "")
	var card := VBoxContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.position = Vector2(120, 140)
	card.custom_minimum_size = Vector2(400, 80)
	var l1 := UI.label("CASE 1 · THE RESTRUCTURING", 11, UI.C_GOLD)
	var l2 := UI.label("Scene %d of 12" % num, 20, Color.WHITE)
	var l3 := UI.label(place, 12, UI.C_MUTED)
	for l in [l1, l2, l3]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(l)
	add_child(card)
	_shoot("scene_%02d_card" % num)
	await get_tree().create_timer(0.3 if autotest else 1.3).timeout
	card.queue_free()

	bg.set_bg(sc["background"])
	top_title.text = "CASE 1 · S%02d · %s" % [num, place]
	_build_roster(sc)
	_update_neg_hud()
	await _fade_to(0.0)
	goto(node_id)


func _fade_to(a: float) -> void:
	var dur := 0.05 if (autotest or GS.settings.get("reduced_motion", false)) else 0.35
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, dur)
	await tw.finished


func _build_roster(sc: Dictionary) -> void:
	for p in portraits.values():
		p.queue_free()
	portraits.clear()
	var left: Array = []
	var right: Array = []
	for n in sc["nodes"]:
		if n["type"] != "line":
			continue
		var sp: String = n["speaker"]
		if sp in left or sp in right or not GS.SPEAKERS.has(sp):
			continue
		if GS.SPEAKERS[sp]["side"] == "employer":
			right.append(sp)
		else:
			left.append(sp)
	# Workers stand nearest the centre of the UWF group.
	left.sort_custom(func(a, b): return _side_rank(a) < _side_rank(b))
	var step := 86.0
	var positions: Dictionary = {}
	if right.is_empty():
		var total := step * (left.size() - 1)
		for i in left.size():
			positions[left[i]] = 320.0 - total * 0.5 + i * step
	else:
		for i in left.size():
			positions[left[i]] = 54.0 + i * step
		for i in right.size():
			positions[right[i]] = 586.0 - i * step
	for sp in positions:
		var p := SpriteActor.new()
		p.setup(sp, 2)
		p.position = Vector2(roundf(positions[sp] - p.size.x * 0.5), STAGE_BOTTOM - p.size.y)
		p.modulate = Color(0.68, 0.7, 0.78)
		stage.add_child(p)
		portraits[sp] = p
		p.play(_idle_state(sp))
	if portraits.has("JULIAN_VANE"):
		portraits["JULIAN_VANE"].play("A12", "A01", 1.5)   # straightens jacket on entry


func _side_rank(sp: String) -> int:
	return ["VERA_JUSTICE", "AUDREY_ORDER", "LAURENCE_ABBOTT", "SALLY_DARITY", "SUP_DANIEL", "SUP_NINA"].find(sp)


## Resting animation for a character who is on stage but not speaking.
func _idle_state(sp: String) -> String:
	var scene_n := GS.scene_number(GS.state["scene_id"])
	match sp:
		"SUP_DANIEL":
			if scene_n == 12:
				return "SUP_RELIEVED" if GS.state["outcome"] == "AGREEMENT" else "SUP_CONCERNED"
			return "SUP_NEUTRAL" if scene_n == 11 else "SUP_CONCERNED"
		"SUP_NINA":
			return "SUP_NEUTRAL" if GS.state["witness"].has("NINA") else "SUP_HESITANT"
		"SUP_NORTHBRIDGE_REP":
			return "SUP_FORMAL"
		"JULIAN_VANE", "MONA_POLLY":
			return "A01"
	return "A11"


func _focus_speaker(sp: String, anim: String) -> void:
	for id in portraits:
		var p = portraits[id]
		var on: bool = id == sp
		p.modulate = Color.WHITE if on else Color(0.68, 0.7, 0.78)
		if on:
			p.move_to_front()
			if _react_next != "" and p.has_state(_react_next):
				p.play(_react_next, anim, 0.8)
			else:
				p.play(anim)
		else:
			p.idle(_idle_state(id))
	_react_next = ""


func _react(sp: String, state: String, then: String = "", lock: float = 1.6) -> void:
	if portraits.has(sp):
		portraits[sp].play(state, then if then != "" else _idle_state(sp), lock)


# ================================================================ graph interpreter

func goto(node_id: String) -> void:
	var id := node_id
	mode = "busy"
	var guard := 0
	while guard < 500:
		guard += 1
		if not GS.nodes.has(id):
			push_error("Missing dialogue node: " + id)
			return
		var n: Dictionary = GS.nodes[id]
		GS.state["node_id"] = id
		match n["type"]:
			"join":
				id = n["next"]
			"gate":
				await _resolve_interactive(n["test"])
				id = n["yes"] if GS.test(n["test"]) else n["no"]
			"event":
				await _handle_event(n)
				id = n["next"]
			"line":
				for e in n.get("effects", []):
					GS.apply_effect(e)
				# The source graph sometimes repeats an identical line on two paths; show it once.
				if n["text"] == _last_text:
					if GS.state["momentum"] <= 0 and GS.state["negotiation"] != "":
						await _momentum_reset()
						return
					id = n["next"]
					continue
				_show_line(n)
				return
			"choice":
				_show_choice(n)
				return
			"scene_exit":
				_scene_exit(n)
				return
			_:
				push_error("Unknown node type " + str(n["type"]))
				return


func _show_line(n: Dictionary) -> void:
	current = n
	mode = "line"
	var sp: String = n["speaker"]
	_set_text(GS.speaker_name(sp), n["text"], GS.SPEAKERS.get(sp, {}).get("color", "#4fc3c9"))
	var anim: String = n.get("animation", "A02")
	_focus_speaker(sp, anim)
	for e in n.get("effects", []):
		if e.begins_with("MOMENTUM:-"):
			_react("VERA_JUSTICE", "A09")
			_react("JULIAN_VANE", "A04", "A01")
		elif e == "C01:AGREEMENT":
			for id in ["AUDREY_ORDER", "LAURENCE_ABBOTT", "SALLY_DARITY"]:
				_react(id, "A10", "A11", 2.5)
			_react("SUP_DANIEL", "SUP_RELIEVED", "SUP_RELIEVED", 3.0)
		elif e == "C01:DISAGREEMENT":
			_react("VERA_JUSTICE", "A08", "A08", 2.5)
	GS.add_log(GS.speaker_name(sp), n["text"])
	_last_text = n["text"]


func _set_text(who: String, text: String, col: String = "#4fc3c9") -> void:
	name_plate.visible = who != ""
	name_label.text = who
	name_plate.add_theme_stylebox_override("panel", UI.box(Color(col), Color(0, 0, 0, 0), 0, 4, 6))
	text_label.text = text
	_type_pos = 0.0
	typing = text != ""
	text_label.visible_characters = 0 if typing else -1
	advance_mark.visible = false


func _process(delta: float) -> void:
	if typing:
		_type_pos += delta * GS.chars_per_second()
		var total := text_label.get_total_character_count()
		if _type_pos >= total:
			_finish_typing()
		else:
			text_label.visible_characters = int(_type_pos)
	if mode == "line" and not typing:
		advance_mark.visible = true
		if not GS.settings.get("reduced_motion", false):
			advance_mark.position.y = 338 + sin(Time.get_ticks_msec() / 180.0) * 1.5
	if autotest:
		_autotest_tick(delta)


func _finish_typing() -> void:
	typing = false
	text_label.visible_characters = -1
	var sp: String = current.get("speaker", "")
	if portraits.has(sp) and portraits[sp].state in ["A02", "SUP_SPEAKING"]:
		portraits[sp].play("A01" if sp in GS.SPEAKERS and not sp.begins_with("SUP_") else _idle_state(sp))


func _advance() -> void:
	if mode != "line" or _modal_count > 0:
		return
	if typing:
		_finish_typing()
		return
	if GS.state["momentum"] <= 0 and GS.state["negotiation"] != "":
		await _momentum_reset()
		return
	goto(current["next"])


func _on_catcher_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif ev is InputEventScreenTouch and ev.pressed:
		_advance()


func _unhandled_input(ev: InputEvent) -> void:
	if _modal_count > 0:
		return
	if ev.is_action_pressed("ui_accept") or (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_SPACE):
		if mode == "line":
			get_viewport().set_input_as_handled()
			_advance()
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_E: _open_records()
			KEY_L: _open_log()
			KEY_ESCAPE: _open_menu()


func _scene_exit(n: Dictionary) -> void:
	mode = "busy"
	GS.state["flags"][n["scene_complete"]] = true
	_last_text = ""
	var nxt: String = n["next_scene"]
	if GS.scenes.has(nxt):
		_enter_scene(nxt, GS.scenes[nxt]["entry"])
	else:
		GS.state["scene_id"] = "C01_S12"
		GS.state["flags"]["CHAPTER_COMPLETE"] = true
		GS.save_game()
		await _fade_to(1.0)
		chapter_finished.emit()


# ================================================================ choices

func _clear_choices() -> void:
	for c in choice_layer.get_children():
		c.queue_free()
	_choice_buttons.clear()


func _show_choice(n: Dictionary) -> void:
	current = n
	mode = "choice"
	advance_mark.visible = false
	_finish_typing()
	_clear_choices()
	var opts: Array = n["options"]

	# Evidence presentation menu
	if opts.size() > 0 and opts[0].has("evidence_id"):
		_evidence_menu(n)
		return

	# Negotiation phase choice?
	var re := RegEx.create_from_string("^(C01_N\\d\\d):PHASE_(\\d+):")
	for o in opts:
		for e in o.get("effects", []):
			var m := re.search(e)
			if m:
				_enter_phase(m.get_string(1), int(m.get_string(2)), n["id"])
				_react("VERA_JUSTICE", "A03", "A03", 0.0)
				_phase_view(n)
				return

	for o in opts:
		if String(o["label"]).begins_with("HINT"):
			_react("VERA_JUSTICE", "A03", "A03", 0.0)
			_puzzle_view(n)
			return
	_plain_view(n)


func _choice_container(width: float, accent: Color, title: String) -> VBoxContainer:
	var holder := VBoxContainer.new()
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.position = Vector2((640 - width) * 0.5, 26)
	holder.size = Vector2(width, 220)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_layer.add_child(holder)
	var p := UI.panel(UI.C_PANEL, accent, 8)
	holder.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(UI.label(title, 12, accent))
	return v


func _plain_view(n: Dictionary) -> void:
	var v := _choice_container(500, UI.C_GOLD, n.get("prompt", ""))
	for o in n["options"]:
		var b := UI.button(o["label"], Color(0, 0, 0, 0), 12, true)
		b.pressed.connect(_choose.bind(n, o))
		v.add_child(b)
		_choice_buttons.append(b)
	_focus_first(_choice_buttons)
	_shoot("choice_plain")


func _phase_view(n: Dictionary) -> void:
	var v := _choice_container(500, UI.C_CHALLENGE, n.get("prompt", ""))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for o in n["options"]:
		var lab: String = o["label"]
		var col := UI.C_CONSULT
		if lab.begins_with("QUESTION"): col = UI.C_QUESTION
		elif lab.begins_with("CHALLENGE"): col = UI.C_CHALLENGE
		elif lab.begins_with("EVIDENCE"): col = UI.C_EVIDENCE
		var b := UI.button(lab, col, 12, true)
		b.custom_minimum_size = Vector2(236, 34)
		b.pressed.connect(_choose.bind(n, o))
		grid.add_child(b)
		_choice_buttons.append(b)
	v.add_child(UI.label("QUESTION! and CONSULT are free. A wrong record costs 1 Momentum.", 10, UI.C_MUTED))
	_focus_first(_choice_buttons)
	_shoot("choice_negotiation")


func _puzzle_view(n: Dictionary) -> void:
	var pid := "C01_P%02d" % [1 + ["C01_S05", "C01_S08", "C01_S09", "C01_S10"].find(GS.state["scene_id"])]
	var pz: Dictionary = GS.PUZZLES.get(pid, {"title": "Puzzle", "records": []})
	var v := _choice_container(608, UI.C_EVIDENCE, "PUZZLE · %s — %s" % [pz["title"], n.get("prompt", "")])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var board := VBoxContainer.new()
	board.custom_minimum_size = Vector2(330, 0)
	board.add_theme_constant_override("separation", 3)
	row.add_child(board)
	board.add_child(UI.label("CASE BOARD — what the record can show", 10, UI.C_GOLD))
	for eid in pz["records"]:
		var ev: Dictionary = GS.EVIDENCE[eid]
		var ok := GS.has_evidence(eid)
		var t: String
		if ok:
			t = "✓ %s\n   Shows: %s  Not: %s" % [ev["title"], ev["supports"], ev["limits"]]
		elif GS.evidence_resolved(eid):
			t = "✗ %s — gap: not verified / not available" % ev["title"]
		else:
			t = "· %s — not yet obtained" % ev["title"]
		board.add_child(UI.label(t, 9, UI.C_TEXT if ok else UI.C_MUTED))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	row.add_child(right)
	var hints := HBoxContainer.new()
	for o in n["options"]:
		var lab: String = o["label"]
		var b: Button
		if lab.begins_with("HINT"):
			b = UI.button(lab.replace(" (free)", ""), UI.C_CONSULT, 10)
			b.alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hints.add_child(b)
		else:
			b = UI.button(lab, UI.C_EVIDENCE, 11, true)
			right.add_child(b)
		b.pressed.connect(_choose.bind(n, o))
		_choice_buttons.append(b)
	right.add_child(UI.label("Free hints:", 9, UI.C_MUTED))
	right.add_child(hints)
	_focus_first(_choice_buttons)
	_shoot("choice_puzzle")


func _choose(n: Dictionary, o: Dictionary) -> void:
	if mode != "choice":
		return
	mode = "busy"
	_clear_choices()
	GS.add_log("▶ Choice", o["label"])
	for e in o.get("effects", []):
		GS.apply_effect(e)
		if e in ["REASONING:OVERSTATEMENT_CORRECTED", "REASONING:CONSENT_GUARD"]:
			_react("VERA_JUSTICE", "A07", "", 1.4)
			_react_next = "A12"   # the adviser who corrects Vera plays their signature move
		elif e == "REASONING:SUPPORTED":
			_react("VERA_JUSTICE", "A04", "", 1.4)
		elif e.ends_with(":CHALLENGE"):
			_react("VERA_JUSTICE", "A05", "", 1.8)
	# Scene 6 recovery: re-checking the existing appointment record verifies it.
	if n["id"] == "C01_S06_V11_AUTH_RECOVERY_CHOICE" and o["next"] == "C01_S06_V11_AUTH_GATE":
		await _authority_record("The existing appointment record was located and checked.")
	goto(o["next"])


func _evidence_menu(n: Dictionary) -> void:
	mode = "busy"
	var opts: Array = []
	for o in n["options"]:
		if o.has("evidence_id"):
			var eid: String = o["evidence_id"]
			var ok := GS.has_evidence(eid)
			opts.append({"text": o["label"] + ("" if ok else "  — not verified, cannot present"), "disabled": not ok, "accent": UI.C_EVIDENCE})
		else:
			opts.append({"text": o["label"]})
	var idx := await ask("EVIDENCE!", n.get("prompt", ""), opts, UI.C_EVIDENCE, 460)
	var o: Dictionary = n["options"][idx]
	GS.add_log("▶ Choice", o["label"])
	for e in o.get("effects", []):
		GS.apply_effect(e)
	goto(o["next"])


# ================================================================ negotiation

func _enter_phase(neg: String, phase: int, node_id: String) -> void:
	if GS.state["negotiation"] != neg:
		GS.state["negotiation"] = neg
		GS.state["phase"] = 0
		GS.set_momentum(5)
		GS.notify("Negotiation %s begins · Momentum 5" % neg)
	if GS.state["phase"] != phase:
		GS.state["phase"] = phase
		GS.state["checkpoint"] = node_id
		GS.state["selected_evidence"] = ""
		GS.state["node_id"] = node_id
		GS.save_game()
	_update_neg_hud()


func _update_neg_hud() -> void:
	var neg: String = GS.state.get("negotiation", "")
	neg_panel.visible = neg != ""
	if neg == "":
		return
	var phases: Array = GS.NEGOTIATIONS[neg]["phases"]
	var ph: int = GS.state["phase"]
	var phase_name: String = phases[ph - 1] if ph >= 1 and ph <= phases.size() else "Terms review"
	neg_label.text = "NEGOTIATION %s · Phase %d/%d · %s" % [neg.substr(4), ph, phases.size(), phase_name]
	var m: int = GS.state["momentum"]
	momentum_label.text = "MOMENTUM  " + "●".repeat(m) + "○".repeat(5 - m)


func _momentum_reset() -> void:
	await ask("MOMENTUM EXHAUSTED", "The argument has lost its footing. You return to the start of this phase with Momentum 5.\nVerified records and recorded decisions are kept.", ["Return to checkpoint"], UI.C_CHALLENGE)
	GS.set_momentum(5)
	GS.state["selected_evidence"] = ""
	_last_text = ""
	goto(GS.state["checkpoint"])


# ================================================================ gates needing player input

func _resolve_interactive(expr: String) -> void:
	var parts: Array = Array(expr.substr(4).split(",")) if expr.begins_with("all:") else [expr]
	var blocked := false
	for part in parts:
		var kind: String = part.get_slice(":", 0)
		var arg: String = part.substr(kind.length() + 1)
		match kind:
			"witness_consent":
				if not GS.state["witness"].has(arg):
					await _witness_decision(arg)
				if GS.state["witness"][arg] != "CONSENTED":
					blocked = true
			"evidence_auth":
				if not GS.evidence_resolved(arg):
					if blocked:
						GS.set_evidence(arg, "UNAVAILABLE")
					else:
						await _evidence_intake(arg)
			"agreement_authorised":
				await _authority_check()


func _evidence_intake(eid: String) -> void:
	var ev: Dictionary = GS.EVIDENCE[eid]
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	body.add_child(UI.label(ev["title"].to_upper(), 13, Color.WHITE))
	body.add_child(UI.label("Source: " + ev["source"], 10, UI.C_MUTED))
	body.add_child(UI.label(ev["summary"], 11))
	body.add_child(UI.label("Check before recording: " + ev["check"], 10, UI.C_GOLD))
	body.add_child(UI.label("Collecting is optional. A recorded gap is a valid result.", 9, UI.C_MUTED))
	var idx := await ask("RECORD OFFERED", body, [
		{"text": "Verify the source and record it", "accent": UI.C_GOOD},
		{"text": "Set it aside — record a gap"}], UI.C_GOLD, 440)
	if idx == 0:
		GS.set_evidence(eid, "COLLECTED")
		GS.add_log("Record", "Verified: " + ev["title"])
		GS.notify("Record verified: " + ev["title"])
	else:
		GS.set_evidence(eid, "UNAVAILABLE")
		GS.add_log("Record", "Gap recorded: " + ev["title"])
		GS.notify("Gap recorded: " + ev["title"])


func _witness_decision(who: String) -> void:
	var idx := await ask("NINA'S DECISION",
		"This decision belongs to Nina — not to Vera, and not to the union.\nIn this prototype you choose on her behalf. There is no wrong answer: the case continues either way.",
		[{"text": "Nina gives a limited statement about the meeting she attended", "accent": UI.C_CONSULT},
		 {"text": "Nina declines to give a formal statement", "accent": UI.C_CONSULT}], UI.C_CONSULT, 440)
	GS.state["witness"][who] = "CONSENTED" if idx == 0 else "DECLINED"


func _authority_record(intro: String) -> void:
	GS.state["flags"]["AUTH_VERIFIED:C01"] = true
	var body := VBoxContainer.new()
	body.add_child(UI.label(intro, 11))
	var rec := "mandate_id: C01_UWF_MANDATE\nissuing_body: UWF Regional Executive (fictional)\npowers: AUTH_REQUEST_INFORMATION, AUTH_LOCAL_NEGOTIATE\nscope: Northbridge restructuring — Daniel's position\nindividual_rights_included: false (Daniel instructs separately)\nverified: true"
	var l := UI.label(rec, 10, UI.C_GOOD)
	l.add_theme_stylebox_override("normal", UI.box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, 3, 6))
	body.add_child(l)
	body.add_child(UI.label("This authorises questions and negotiation — not accepting terms on anyone's behalf.", 10, UI.C_MUTED))
	await ask("UWF AUTHORITY RECORD", body, ["Continue"], UI.C_GOOD, 440)
	GS.add_log("Record", "UWF negotiating authority verified")


func _authority_check() -> void:
	var uwf: bool = GS.state["flags"].has("AUTH_VERIFIED:C01")
	var dan: String = GS.state["daniel_instruction"]
	var rows := [
		[true, "Terms: all nine clauses read and scope checked"],
		[true, "Northbridge: authorised representative ready to sign the exact terms"],
		[uwf, "UWF: verified authority for the collective follow-up (Clause 6)"],
		[dan == "APPROVED", "Daniel: informed written instructions on his individual terms (%s)" % dan.to_lower()],
	]
	var body := VBoxContainer.new()
	for r in rows:
		body.add_child(UI.label(("✓  " if r[0] else "✗  ") + r[1], 11, UI.C_GOOD if r[0] else UI.C_BAD))
	await ask("AUTHORITY CHECK", body, ["Continue"], UI.C_GOLD, 460)


func _daniel_instructions() -> void:
	var idx := await ask("DANIEL'S INSTRUCTIONS",
		"Clauses 1–5 affect Daniel personally, so only Daniel can approve them.\nIn this prototype you choose on his behalf.",
		[{"text": "Daniel approves the individual terms in writing", "accent": UI.C_CONSULT},
		 {"text": "Daniel wants more time and information first", "accent": UI.C_CONSULT},
		 {"text": "Daniel declines the package", "accent": UI.C_CONSULT}], UI.C_CONSULT, 440)
	GS.state["daniel_instruction"] = ["APPROVED", "PENDING", "DECLINED"][idx]
	GS.add_log("Record", "Daniel's instruction: " + GS.state["daniel_instruction"].to_lower())


# ================================================================ events

func _handle_event(n: Dictionary) -> void:
	var eff: String = n["effect"]
	var kind := eff.get_slice(":", 0)
	var arg := eff.substr(kind.length() + 1)
	match kind:
		"EVIDENCE_STATUS_RESOLVED":
			if not GS.evidence_resolved(arg):
				GS.set_evidence(arg, "UNAVAILABLE")
		"EVIDENCE_GENERATED":
			GS.set_evidence(arg, "COLLECTED")
			GS.add_log("Record", "New record: " + GS.EVIDENCE[arg]["title"])
			GS.notify("New record: " + GS.EVIDENCE[arg]["title"])
		"PUZZLE_COMPLETE":
			var res: String = GS.state["puzzles"].get(arg, "")
			var nice := {"SOLVED_FULL": "documented finding", "SOLVED_LIMITED": "limited finding", "SOLVED_INSUFFICIENT_EVIDENCE": "evidence gap recorded"}
			GS.notify("Puzzle solved — %s: %s" % [GS.PUZZLES[arg]["title"], nice.get(res, res)])
			GS.add_log("Record", "Puzzle %s: %s" % [GS.PUZZLES[arg]["title"], nice.get(res, res)])
		"NEGOTIATION_PHASE_COMPLETE":
			GS.state["selected_evidence"] = ""
			GS.notify("Phase complete — position recorded")
			if arg == "C01_N02:4":
				GS.state["phase"] = 5
				_update_neg_hud()
		"NEGOTIATION_COMPLETE":
			GS.state["negotiation"] = ""
			GS.state["phase"] = 0
			_update_neg_hud()
			GS.notify("Negotiation %s complete" % arg)
		"UWF_DELEGATION_VERIFICATION_REQUESTED":
			await _authority_record("The authorised UWF body considered the request and recorded a decision.")
		"WITNESS_DECISION_RECORDED":
			GS.notify("Nina's decision recorded: " + String(GS.state["witness"].get(arg, "")).to_lower())
		"TERMS_REVIEWED":
			GS.state["flags"]["TERMS_REVIEWED:" + arg] = true
			await _daniel_instructions()
		"FINAL_OUTCOME_RECORDED":
			GS.notify("Outcome recorded: " + GS.state["outcome"])
			GS.add_log("Record", "Case outcome: " + GS.state["outcome"])
		_:
			GS.state["flags"][eff] = true


# ================================================================ modals

func ask(title: String, body, options: Array, accent: Color = UI.C_BORDER, width: float = 420.0) -> int:
	var m: Array = UI.modal(modal_layer, width, title, accent)
	var v: VBoxContainer = m[1]
	if body is String:
		if body != "":
			v.add_child(UI.label(body, 11))
	elif body is Control:
		v.add_child(body)
	var buttons: Array = []
	for i in options.size():
		var spec = options[i]
		if spec is String:
			spec = {"text": spec}
		var b := UI.button(spec["text"], spec.get("accent", Color(0, 0, 0, 0)), 12, true)
		b.disabled = spec.get("disabled", false)
		b.pressed.connect(func(): _modal_choice.emit(i))
		v.add_child(b)
		buttons.append(b)
	_modal_count += 1
	_modal_buttons = buttons
	_focus_first(buttons)
	_shoot("modal_" + title.to_lower().replace(" ", "_").replace("'", "").replace("!", ""))
	var idx: int = await _modal_choice
	m[0].queue_free()
	_modal_count -= 1
	_modal_buttons = []
	_focus_first(_choice_buttons)
	return idx


func _focus_first(buttons: Array) -> void:
	for b in buttons:
		if is_instance_valid(b) and not b.disabled:
			b.call_deferred("grab_focus")
			return


func _close_button(root: Control, v: VBoxContainer) -> void:
	var b := UI.button("Close", UI.C_BORDER)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(func():
		root.queue_free()
		_modal_count -= 1
		_focus_first(_choice_buttons))
	v.add_child(b)
	b.call_deferred("grab_focus")


func _open_records() -> void:
	if _modal_count > 0:
		return
	var m: Array = UI.modal(modal_layer, 600, "RECORDS — Case 1 evidence board", UI.C_EVIDENCE)
	_modal_count += 1
	var v: VBoxContainer = m[1]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(190, 0)
	row.add_child(list)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.custom_minimum_size = Vector2(380, 200)
	row.add_child(detail)
	var any := false
	for eid in GS.EVIDENCE:
		if not GS.evidence_resolved(eid):
			continue
		any = true
		var ok := GS.has_evidence(eid)
		var b := UI.button(("✓ " if ok else "✗ ") + GS.EVIDENCE[eid]["title"], Color(0, 0, 0, 0), 10)
		b.custom_minimum_size = Vector2(0, 18)
		b.pressed.connect(_show_record.bind(detail, eid))
		list.add_child(b)
	if any:
		for eid in GS.EVIDENCE:
			if GS.evidence_resolved(eid):
				_show_record(detail, eid)
				break
	else:
		detail.add_child(UI.label("No records yet. Records appear here once they are offered.", 11, UI.C_MUTED))
	_close_button(m[0], v)
	_shoot("records")


func _show_record(detail: VBoxContainer, eid: String) -> void:
	for c in detail.get_children():
		c.queue_free()
	var ev: Dictionary = GS.EVIDENCE[eid]
	var ok := GS.has_evidence(eid)
	detail.add_child(UI.label(ev["title"].to_upper() + "   ·   " + eid, 13, Color.WHITE))
	detail.add_child(UI.label("VERIFIED — may be presented within its scope" if ok else "GAP — cannot be presented", 10, UI.C_GOOD if ok else UI.C_BAD))
	detail.add_child(UI.label("Source: " + ev["source"] + "   ·   Sensitivity: CONTROLLED", 10, UI.C_MUTED))
	if ok:
		detail.add_child(UI.label(ev["summary"], 11))
		detail.add_child(UI.label("Can show: " + ev["supports"], 10, UI.C_GOOD))
		detail.add_child(UI.label("Cannot show: " + ev["limits"], 10, UI.C_GOLD))
	else:
		detail.add_child(UI.label("This record was not verified or is not available. Its contents are not shown, and it cannot be used as proof.", 11, UI.C_MUTED))


func _open_log() -> void:
	if _modal_count > 0:
		return
	var m: Array = UI.modal(modal_layer, 600, "LOG — what has been said and decided", UI.C_BORDER)
	_modal_count += 1
	var v: VBoxContainer = m[1]
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lv)
	for e in GS.state["log"].slice(-120):
		var who: String = e["who"]
		var col := UI.C_GOLD if who.begins_with("▶") else (UI.C_GOOD if who == "Record" else UI.C_BORDER)
		var l := UI.label("%s: %s" % [who, e["text"]], 10, UI.C_TEXT)
		l.add_theme_color_override("font_color", col.lerp(UI.C_TEXT, 0.5))
		l.custom_minimum_size = Vector2(560, 0)
		lv.add_child(l)
	_close_button(m[0], v)
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _open_menu() -> void:
	if _modal_count > 0:
		return
	var idx := await ask("MENU", "Progress is saved automatically at the start of each scene and at negotiation checkpoints.",
		["Resume", "Settings", "Return to title"], UI.C_BORDER, 320)
	if idx == 1:
		var sp = SettingsPanel.new()
		_modal_count += 1
		modal_layer.add_child(sp)
		await sp.closed
		_modal_count -= 1
		_focus_first(_choice_buttons)
	elif idx == 2:
		GS.save_game()
		quit_to_title.emit()


func _on_toast(text: String) -> void:
	toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	toast_label.modulate.a = 1.0
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)


# ================================================================ automated test play

func _shoot(name: String) -> void:
	if _shots_dir != "" and not _shot_taken.has(name):
		_shot_taken[name] = true
		_shot_pending = name


func _autotest_tick(delta: float) -> void:
	_auto_wait -= delta
	if _auto_wait > 0.0:
		return
	_auto_wait = 0.02
	if _shot_pending != "":
		var nm := _shot_pending
		_shot_pending = ""
		_auto_wait = 0.4
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shots_dir.path_join(nm + ".png"))
		return
	_auto_steps += 1
	if _auto_steps > 30000:
		push_error("AUTOTEST: too many steps, possible loop at " + str(GS.state["node_id"]))
		get_tree().quit(2)
		return
	if _modal_count > 0:
		_press_random(_modal_buttons)
	elif mode == "choice":
		_press_random(_choice_buttons)
	elif mode == "line":
		_advance()


func _press_random(buttons: Array) -> void:
	var live: Array = buttons.filter(func(b): return is_instance_valid(b) and not b.disabled)
	if live.is_empty():
		return
	# Bias toward the first options so runs finish in reasonable time.
	var i := randi() % live.size()
	if randf() < 0.5:
		i = 0
	live[i].emit_signal("pressed")
