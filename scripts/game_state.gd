extends Node
## Global game state (autoload "GS").
## Loads the Case 1 dialogue graph, tracks evidence / puzzles / negotiation
## state, evaluates script gate tests and handles save + settings.

signal toast(text: String)
signal momentum_changed(value: int)
signal settings_changed

const DATA_PATH := "res://data/C01_SCRIPT_v2_0.json"
const SAVE_PATH := "user://ace_negotiator_c01_save.json"
const SETTINGS_PATH := "user://ace_negotiator_settings.json"
const SAVE_SCHEMA := "10.0-prototype-1"

const SPEAKERS := {
	"VERA_JUSTICE": {"name": "Vera Justice", "role": "UWF Regional Representative", "color": "#4fc3c9", "side": "uwf",
		"look": {"skin": "#e8b896", "hair": "#6b2d1f", "style": "ponytail", "clothes": "#2f7f86", "shirt": "#f4efe6", "acc": "badge"}},
	"AUDREY_ORDER": {"name": "Audrey Order", "role": "Senior UWF Lead", "color": "#b39ddb", "side": "uwf",
		"look": {"skin": "#efc7a8", "hair": "#c9c4bd", "style": "bob", "clothes": "#3b3f6b", "shirt": "#d9d4ea", "acc": "badge"}},
	"SALLY_DARITY": {"name": "Sally Darity", "role": "UWF Organiser", "color": "#f2c14e", "side": "uwf",
		"look": {"skin": "#8d5a3b", "hair": "#1e1410", "style": "curly", "clothes": "#d39b2a", "shirt": "#3a2f25", "acc": "badge"}},
	"LAURENCE_ABBOTT": {"name": "Laurence Abbott", "role": "UWF Legal Adviser", "color": "#8fd18f", "side": "uwf",
		"look": {"skin": "#d9a37e", "hair": "#4a3626", "style": "short", "clothes": "#5d636b", "shirt": "#e9eef2", "acc": "glasses_tie", "tie": "#7a2335"}},
	"JULIAN_VANE": {"name": "Julian Vane", "role": "Employer-side Lawyer", "color": "#e57373", "side": "employer",
		"look": {"skin": "#f1d0b5", "hair": "#14161c", "style": "slick", "clothes": "#23252b", "shirt": "#f5f5f5", "acc": "tie", "tie": "#9aa3ad"}},
	"SUP_DANIEL": {"name": "Daniel", "role": "Northbridge employee", "color": "#90caf9", "side": "worker",
		"look": {"skin": "#f0c6a0", "hair": "#b08a4f", "style": "short", "clothes": "#5a7fb0", "shirt": "#5a7fb0", "acc": "", "brow": "worried"}},
	"SUP_NINA": {"name": "Nina", "role": "Northbridge employee", "color": "#a5d6a7", "side": "worker",
		"look": {"skin": "#c98f6a", "hair": "#3b2318", "style": "long", "clothes": "#4f7a52", "shirt": "#e8e2d0", "acc": "", "brow": "worried"}},
	"SUP_NORTHBRIDGE_REP": {"name": "Northbridge Representative", "role": "Northbridge management", "color": "#ef9a9a", "side": "employer",
		"look": {"skin": "#e6b48f", "hair": "#8a8a8a", "style": "bald", "clothes": "#2c3e5c", "shirt": "#e9eef2", "acc": "tie", "tie": "#3d6fb0"}},
}

const BACKGROUNDS := {
	"BG01": "Union Office",
	"BG02": "Union Consultation Room",
	"BG03": "Corporate Negotiation Room",
	"BG05": "Modern Technology Office",
	"BG12": "Document Review Archive Room",
}

## Evidence card text. Wording is drawn from what the Case 1 script says about each record.
const EVIDENCE := {
	"C01_E01": {"title": "Dismissal Notice", "source": "Supplied by Daniel (his own copy)",
		"summary": "Northbridge's notice to Daniel, dated 10 June 2026. Stated reason: \"Work shortage following reorganisation.\"",
		"supports": "Northbridge's stated reason and its operative wording.",
		"limits": "Does not answer the vacancy question on its own.",
		"check": "Is this the complete, signed version?"},
	"C01_E02": {"title": "Employment Contract", "source": "Supplied by Daniel",
		"summary": "Daniel's agreed employment terms. It also contains his address and salary, which the negotiation does not need.",
		"supports": "Daniel's relevant employment terms.",
		"limits": "Says nothing about which vacancies Northbridge had. Present only the relevant clauses.",
		"check": "Use only authenticated, relevant passages."},
	"C01_E03": {"title": "Organisation Chart", "source": "Circulated by Northbridge",
		"summary": "The proposed structure Northbridge circulated. Daniel's box is not on it.",
		"supports": "The structure this dated version actually shows.",
		"limits": "A draft is not automatically an implemented decision. A missing box is not missing work.",
		"check": "Is it dated? Which version, and was it only a proposal?"},
	"C01_E04": {"title": "Recruitment Advertisement", "source": "Northbridge's public job posting (full dated copy)",
		"summary": "A role with a new title. It mentions customer systems Daniel maintains, and asks for a tool he has never used.",
		"supports": "That a vacancy was advertised, as described.",
		"limits": "Does not prove Daniel is entitled to the job.",
		"check": "A full dated posting - not a cropped screenshot."},
	"C01_E05": {"title": "New Position Description", "source": "Northbridge's description of the new role",
		"summary": "The duties and qualifications of the new position.",
		"supports": "What the new role requires.",
		"limits": "Not whether Daniel meets those requirements.",
		"check": "Is the description authenticated and complete?"},
	"C01_E06": {"title": "Restructuring Timeline", "source": "Compiled by UWF from verified documents",
		"summary": "Dated events in order: the notice, the planning meeting and the chart's circulation. Unknown dates stay marked as unknown.",
		"supports": "Its sourced events and its stated gaps.",
		"limits": "Does not show when management actually approved the decision.",
		"check": "Generated from verified entries only."},
	"C01_E07": {"title": "Meeting Minutes", "source": "Northbridge planning-meeting minutes",
		"summary": "A record of the planning meeting's discussion, with its date.",
		"supports": "The specified meeting discussion.",
		"limits": "Does not establish every management decision.",
		"check": "Were these minutes agreed, corrected or merely drafted?"},
	"C01_E08": {"title": "Nina Formal Statement", "source": "Nina - voluntary, limited scope",
		"summary": "Nina's limited statement about the planning meeting she attended.",
		"supports": "Only her stated first-hand observations.",
		"limits": "Use only within the scope Nina agreed to. Protect details about her colleagues.",
		"check": "Did Nina choose to give it, and does its scope allow this use?"},
	"C01_E09": {"title": "Redeployment Assessment", "source": "Northbridge's reassignment record",
		"summary": "Northbridge's documented look at possible reassignment for Daniel. Some alternatives appear.",
		"supports": "The steps and reasoning it documents.",
		"limits": "Missing alternatives remain questions - not proof that none existed.",
		"check": "What did Northbridge actually record?"},
	"C01_E10": {"title": "Consultancy Proposal", "source": "Outside consultancy document (background only)",
		"summary": "Advice an outside consultancy proposed to Northbridge about restructuring.",
		"supports": "That particular advice was proposed.",
		"limits": "Not that Northbridge implemented it. No theory of coordinated conduct.",
		"check": "Can it be authenticated and lawfully used?"},
}

## Records shown on the case board for each puzzle, and what level of finding they support.
const PUZZLES := {
	"C01_P01": {"title": "Position overlap", "records": ["C01_E02", "C01_E04", "C01_E05"]},
	"C01_P02": {"title": "Restructuring chronology", "records": ["C01_E01", "C01_E03", "C01_E07"]},
	"C01_P03": {"title": "Documentary corroboration", "records": ["C01_E03", "C01_E07", "C01_E08"]},
	"C01_P04": {"title": "Redeployment assessment", "records": ["C01_E04", "C01_E05", "C01_E09"]},
}

## Which records actually establish the point in each negotiation phase.
const PHASE_EVIDENCE := {
	"C01_N01:1": ["C01_E03"],
	"C01_N01:2": ["C01_E04", "C01_E05"],
	"C01_N01:3": ["C01_E01", "C01_E03"],
	"C01_N02:1": ["C01_E04", "C01_E05"],
	"C01_N02:2": ["C01_E06"],
	"C01_N02:3": ["C01_E07", "C01_E08"],
	"C01_N02:4": ["C01_E09"],
}

const NEGOTIATIONS := {
	"C01_N01": {"scene": "C01_S07", "phases": ["Restructuring", "Proposed position", "Information and procedure"]},
	"C01_N02": {"scene": "C01_S11", "phases": ["Position", "Chronology", "Nina corroboration", "Redeployment"]},
}

var case_data: Dictionary = {}
var nodes: Dictionary = {}
var scenes: Dictionary = {}
var scene_order: Array = []

var state: Dictionary = {}
var settings: Dictionary = {"text_speed": 2, "text_size": 1, "reduced_motion": false, "high_contrast": false}


func _ready() -> void:
	_load_data()
	load_settings()
	new_game()


func _load_data() -> void:
	var txt := FileAccess.get_file_as_string(DATA_PATH)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Could not load script data at " + DATA_PATH)
		return
	case_data = parsed
	scenes = case_data["scenes"]
	scene_order = case_data["case"]["scene_ids"]
	for sid in scenes:
		for n in scenes[sid]["nodes"]:
			nodes[n["id"]] = n


func new_game() -> void:
	state = {
		"schema": SAVE_SCHEMA,
		"scene_id": "C01_S01",
		"evidence": {},          # id -> "COLLECTED" | "UNAVAILABLE"
		"puzzles": {},           # id -> SOLVED_FULL | SOLVED_LIMITED | SOLVED_INSUFFICIENT_EVIDENCE
		"flags": {},
		"reasoning": {"SUPPORTED": 0, "OVERSTATEMENT_CORRECTED": 0, "CONSENT_GUARD": 0},
		"momentum": 5,
		"negotiation": "",
		"phase": 0,
		"checkpoint": "",
		"witness": {},           # NINA -> CONSENTED | DECLINED
		"daniel_instruction": "",
		"outcome": "",
		"selected_evidence": "",
		"log": [],
	}


# ---------------------------------------------------------------- queries

func speaker_name(id: String) -> String:
	if SPEAKERS.has(id):
		return SPEAKERS[id]["name"]
	return id


func has_evidence(id: String) -> bool:
	return state["evidence"].get(id, "") == "COLLECTED"


func evidence_resolved(id: String) -> bool:
	return state["evidence"].has(id)


func scene_number(scene_id: String) -> int:
	return scene_order.find(scene_id) + 1


## 2 = full finding supported, 1 = limited, 0 = not enough verified information.
func puzzle_support(pid: String) -> int:
	var e := func(id): return has_evidence(id)
	match pid:
		"C01_P01":
			if e.call("C01_E04") and e.call("C01_E05"): return 2
			if e.call("C01_E04") or e.call("C01_E05"): return 1
		"C01_P02":
			var n := int(e.call("C01_E01")) + int(e.call("C01_E03")) + int(e.call("C01_E07"))
			if n == 3: return 2
			if n == 2 and e.call("C01_E07"): return 1
		"C01_P03":
			if e.call("C01_E07") and e.call("C01_E03"): return 2
			if e.call("C01_E07") or e.call("C01_E08"): return 1
		"C01_P04":
			if e.call("C01_E09") and e.call("C01_E04") and e.call("C01_E05"): return 2
			if e.call("C01_E09"): return 1
	return 0


func phase_evidence_ok(key: String) -> bool:
	var valid: Array = PHASE_EVIDENCE.get(key, [])
	var sel: String = state["selected_evidence"]
	if sel != "":
		return sel in valid and has_evidence(sel)
	# No record presented (CHALLENGE route): the guard asks whether we hold a supporting record.
	for id in valid:
		if has_evidence(id):
			return true
	return false


## Evaluates a gate test that needs no player input. Interactive tests are resolved
## by the game screen before this is called.
func test(expr: String) -> bool:
	if expr.begins_with("all:"):
		for part in expr.substr(4).split(","):
			if not test(part):
				return false
		return true
	var kind := expr.get_slice(":", 0)
	var arg := expr.substr(kind.length() + 1)
	match kind:
		"evidence_auth":
			return has_evidence(arg)
		"witness_consent":
			return state["witness"].get(arg, "") == "CONSENTED"
		"puzzle_full":
			return puzzle_support(arg) == 2
		"puzzle_limited":
			return puzzle_support(arg) >= 1
		"puzzle_insufficient":
			return puzzle_support(arg) == 0
		"phase_evidence":
			return phase_evidence_ok(arg)
		"initial_authority_verified":
			return state["flags"].has("AUTH_VERIFIED:" + arg)
		"agreement_authorised":
			return state["flags"].has("AUTH_VERIFIED:" + arg) and state["daniel_instruction"] == "APPROVED" \
				and state["flags"].has("TERMS_REVIEWED:C01_N02")
		"outcome_is_agreement":
			return state["outcome"] == "AGREEMENT"
	push_warning("Unknown gate test: " + expr)
	return false


# ---------------------------------------------------------------- mutations

func apply_effect(effect: String) -> void:
	var parts := effect.split(":")
	var head := parts[0]
	if head == "REASONING" and parts.size() > 1:
		state["reasoning"][parts[1]] = int(state["reasoning"].get(parts[1], 0)) + 1
	elif head == "MOMENTUM" and parts.size() > 1:
		set_momentum(int(state["momentum"]) + int(parts[1]))
	elif head == "SELECT_EVIDENCE":
		state["selected_evidence"] = parts[1]
	elif head == "EVIDENCE_PRESENTED":
		state["flags"][effect] = true
	elif head.begins_with("C01_P") and parts.size() > 1:
		state["puzzles"][head] = parts[1]
	elif head == "C01" and parts.size() > 1 and parts[1] in ["AGREEMENT", "CONTINUING", "DISAGREEMENT"]:
		state["outcome"] = parts[1]
	elif head.begins_with("C01_N") and parts.size() > 2:
		# e.g. C01_N01:PHASE_1:CHALLENGE - a non-documentary move clears any earlier record selection.
		state["selected_evidence"] = ""
	else:
		state["flags"][effect] = true


func set_momentum(v: int) -> void:
	state["momentum"] = clampi(v, 0, 5)
	momentum_changed.emit(state["momentum"])


func set_evidence(id: String, status: String) -> void:
	state["evidence"][id] = status


func add_log(who: String, text: String) -> void:
	state["log"].append({"who": who, "text": text})
	if state["log"].size() > 400:
		state["log"].pop_front()


func notify(text: String) -> void:
	toast.emit(text)


# ---------------------------------------------------------------- save / settings

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(state))
	f.close()
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.file_exists(SAVE_PATH.get_file()):
		dir.remove(SAVE_PATH.get_file())
	return dir.rename(SAVE_PATH.get_file() + ".tmp", SAVE_PATH.get_file()) == OK


func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("schema", "") != SAVE_SCHEMA:
		return false
	if not scenes.has(parsed.get("scene_id", "")):
		return false
	new_game()
	for k in parsed:
		state[k] = parsed[k]
	state["momentum"] = int(state["momentum"])
	state["phase"] = int(state["phase"])
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			for k in parsed:
				settings[k] = parsed[k]


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings))
	settings_changed.emit()


func text_font_size() -> int:
	return [11, 13, 16][clampi(int(settings["text_size"]), 0, 2)]


func chars_per_second() -> float:
	return [18.0, 35.0, 65.0, 100000.0][clampi(int(settings["text_speed"]), 0, 3)]
