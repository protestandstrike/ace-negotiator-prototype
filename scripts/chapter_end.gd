extends Control
## End-of-chapter case report: outcome, puzzle findings, records and reasoning.

signal done

const UI := preload("res://scripts/ui_kit.gd")
const Background := preload("res://scripts/background.gd")

const OUTCOME_TEXT := {
	"AGREEMENT": "AGREEMENT — a Daniel-specific, properly authorised settlement. Its implementation still has to be checked.",
	"CONTINUING": "CONTINUING — Northbridge negotiations continue. Information requests are outstanding.",
	"DISAGREEMENT": "DISAGREEMENT — the dispute is recorded without an agreement.",
}
const PUZZLE_TEXT := {"SOLVED_FULL": "documented finding", "SOLVED_LIMITED": "limited finding", "SOLVED_INSUFFICIENT_EVIDENCE": "evidence gap recorded"}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := Background.new()
	bg.bg_id = "BG01"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var p := UI.panel(UI.C_PANEL, UI.C_GOLD, 12)
	p.position = Vector2(30, 14)
	p.size = Vector2(580, 332)
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(UI.label("CASE 1 REPORT · The Restructuring", 16, UI.C_GOLD))
	var st: Dictionary = GS.state
	v.add_child(UI.label(OUTCOME_TEXT.get(st["outcome"], "No outcome recorded."), 12, Color.WHITE))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var c1 := VBoxContainer.new()
	c1.custom_minimum_size = Vector2(270, 0)
	c1.add_theme_constant_override("separation", 1)
	row.add_child(c1)
	c1.add_child(UI.label("Puzzle findings", 11, UI.C_BORDER))
	for pid in GS.PUZZLES:
		c1.add_child(UI.label("· %s: %s" % [GS.PUZZLES[pid]["title"], PUZZLE_TEXT.get(st["puzzles"].get(pid, ""), "—")], 10))
	c1.add_child(UI.label("Decisions by others", 11, UI.C_BORDER))
	c1.add_child(UI.label("· Nina: %s" % ("gave a limited statement" if st["witness"].get("NINA", "") == "CONSENTED" else "declined a formal statement"), 10))
	c1.add_child(UI.label("· Daniel: %s" % String(st["daniel_instruction"]).to_lower(), 10))

	var c2 := VBoxContainer.new()
	c2.add_theme_constant_override("separation", 0)
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(c2)
	var verified := 0
	for eid in GS.EVIDENCE:
		if GS.has_evidence(eid):
			verified += 1
	c2.add_child(UI.label("Records verified: %d / %d" % [verified, GS.EVIDENCE.size()], 11, UI.C_BORDER))
	for eid in GS.EVIDENCE:
		var ok := GS.has_evidence(eid)
		c2.add_child(UI.label(("✓ " if ok else "✗ ") + GS.EVIDENCE[eid]["title"], 9, UI.C_GOOD if ok else UI.C_MUTED))

	var r: Dictionary = st["reasoning"]
	var total: int = int(r.get("SUPPORTED", 0)) + int(r.get("OVERSTATEMENT_CORRECTED", 0)) + int(r.get("CONSENT_GUARD", 0))
	v.add_child(UI.label("Reasoning: %d of %d answers were supported by the record on the first try. (Corrections are part of learning — they are not penalties.)" % [int(r.get("SUPPORTED", 0)), total], 10, UI.C_MUTED))
	v.add_child(UI.label("Next: Case 2 — The Culture Fit (Bellwether Retail). Not included in this prototype.", 11, UI.C_GOLD))
	var b := UI.button("Return to title", UI.C_BORDER)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(func(): done.emit())
	v.add_child(b)
	b.call_deferred("grab_focus")
