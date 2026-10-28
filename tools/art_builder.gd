extends SceneTree
## Generates all pixel art for the prototype: character sprite sheets (with animation.json
## per GDD Appendix B) and 320x180 backgrounds. Everything is painted pixel by pixel here.
##
## Run from the project folder:
##   godot --headless --path . --script res://tools/art_builder.gd
## then re-import (open the editor, or: godot --headless --path . --import).

const FW := 64          # character frame size
const FH := 72
const FPS := 22
const SHEET_COLS := 8
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

const STATE_NAMES := {
	"A01": "Neutral", "A02": "Speaking", "A03": "Thinking", "A04": "Confident", "A05": "Objection",
	"A06": "Evidence Presentation", "A07": "Surprised", "A08": "Concerned", "A09": "Frustrated",
	"A10": "Positive", "A11": "Listening", "A12": "Character Signature",
}

## Character designs. Colour ramps are [highlight, base, shadow].
const CHARS := {
	"VERA_JUSTICE": {"dir": "principals/vera_justice", "kind": "principal", "sig": "point",
		"skin": ["#fbd9bd", "#f0b893", "#cf8b6a"], "hair": ["#c9603f", "#9a3b26", "#66231a"], "eye": "#2f6b4a",
		"style": "ponytail", "outfit": "blazer", "cloth": ["#4cb5b5", "#2c8a8f", "#1b5e66"], "shirt": ["#fffaf0", "#e2d9c8"],
		"acc": ["lanyard", "hairtie"]},
	"AUDREY_ORDER": {"dir": "principals/audrey_order", "kind": "principal", "sig": "notebook",
		"skin": ["#fde2cf", "#f2c4a6", "#d39c80"], "hair": ["#f1f0ee", "#c8c5c2", "#94908d"], "eye": "#4a5578",
		"style": "bob", "outfit": "cardigan", "cloth": ["#5b5f9a", "#3f4378", "#2a2c55"], "shirt": ["#eeeaf6", "#c9c3dc"],
		"acc": ["pearls"], "prop": "#8c2f39"},
	"SALLY_DARITY": {"dir": "principals/sally_darity", "kind": "principal", "sig": "notes",
		"skin": ["#b07a55", "#8c5a3b", "#663d26"], "hair": ["#4a3428", "#2a1c15", "#160e0b"], "eye": "#2a1c15",
		"style": "curly", "outfit": "jacket_open", "cloth": ["#f0bd4f", "#d39b2a", "#9c6d16"], "shirt": ["#4a3f38", "#2e2621"],
		"acc": ["lanyard_side"], "prop": "#f2c14e"},
	"LAURENCE_ABBOTT": {"dir": "principals/laurence_abbott", "kind": "principal", "sig": "glasses",
		"skin": ["#f0c39c", "#d9a37e", "#b07a58"], "hair": ["#7a5a40", "#4f3826", "#2f2116"], "eye": "#3d2b1f",
		"style": "short", "outfit": "suit", "cloth": ["#7d848d", "#5d636b", "#40454c"], "shirt": ["#f4f7fa", "#d5dce3"],
		"tie": ["#a23a4f", "#7a2335", "#521624"], "acc": ["glasses"]},
	"JULIAN_VANE": {"dir": "principals/julian_vane", "kind": "principal", "sig": "jacket",
		"skin": ["#fde0cc", "#f1caae", "#cfa286"], "hair": ["#3a3f4d", "#1a1d25", "#0b0c10"], "eye": "#2b3442",
		"style": "slick", "outfit": "suit", "cloth": ["#3a3d47", "#23252b", "#121317"], "shirt": ["#ffffff", "#dfe3e8"],
		"tie": ["#c4ccd6", "#9aa3ad", "#6c747e"], "acc": ["pocket_square"]},
	"MONA_POLLY": {"dir": "principals/mona_polly", "kind": "principal", "sig": "folder",
		"skin": ["#e8c19c", "#cfa07a", "#a87856"], "hair": ["#3b2f3a", "#211a22", "#0f0b10"], "eye": "#3b2618",
		"style": "bob_streak", "outfit": "turtleneck", "cloth": ["#3a3640", "#1f1c24", "#0e0c11"], "shirt": ["#ffffff", "#d8d8de"],
		"acc": ["gold_earring"], "prop": "#15131a"},
	"SUP_DANIEL": {"dir": "supporting/sup_daniel", "kind": "supporting",
		"states": ["SUP_NEUTRAL", "SUP_SPEAKING", "SUP_CONCERNED", "SUP_RELIEVED"],
		"skin": ["#fdd8bb", "#f0bb98", "#cc8d6e"], "hair": ["#d8b06a", "#b08a4f", "#7d5f33"], "eye": "#4a6b8a",
		"style": "messy", "outfit": "shirt", "cloth": ["#7ea3d1", "#5a7fb0", "#3e5c86"], "shirt": ["#7ea3d1", "#5a7fb0"], "acc": []},
	"SUP_NINA": {"dir": "supporting/sup_nina", "kind": "supporting",
		"states": ["SUP_NEUTRAL", "SUP_SPEAKING", "SUP_HESITANT"],
		"skin": ["#dba57f", "#c98f6a", "#a06a4a"], "hair": ["#5a3a28", "#3b2318", "#22140d"], "eye": "#3b2318",
		"style": "long", "outfit": "cardigan_round", "cloth": ["#6f9c72", "#4f7a52", "#365638"], "shirt": ["#efe7d4", "#d2c7ad"], "acc": []},
	"SUP_NORTHBRIDGE_REP": {"dir": "supporting/sup_northbridge_rep", "kind": "supporting",
		"states": ["SUP_NEUTRAL", "SUP_SPEAKING", "SUP_FORMAL"],
		"skin": ["#f4c9a8", "#e6b48f", "#c08b6a"], "hair": ["#b5b5b5", "#8a8a8a", "#5f5f5f"], "eye": "#2b3442",
		"style": "bald", "outfit": "suit", "cloth": ["#3f5a80", "#2c3e5c", "#1c2a40"], "shirt": ["#f4f7fa", "#d5dce3"],
		"tie": ["#5d8fd0", "#3d6fb0", "#28508a"], "acc": []},
}

## Per hair style: bottom row of the hair for columns x=22..41 (-1 = no hair), and cap ellipse.
const FRINGES := {
	"ponytail": [-1, 21, 20, 14, 15, 13, 14, 12, 13, 12, 12, 11, 12, 11, 11, 12, 14, 19, 20, -1],
	"bob": [27, 27, 27, 15, 13, 12, 12, 12, 11, 11, 12, 13, 13, 14, 14, 15, 16, 27, 27, 27],
	"curly": [23, 22, 20, 13, 12, 13, 12, 12, 13, 12, 12, 13, 12, 12, 13, 12, 13, 20, 22, 23],
	"short": [-1, 17, 16, 12, 11, 11, 12, 12, 11, 11, 11, 11, 11, 11, 11, 12, 12, 16, 17, -1],
	"slick": [-1, 16, 15, 11, 10, 10, 10, 10, 10, 11, 11, 10, 10, 10, 10, 10, 10, 15, 16, -1],
	"bob_streak": [28, 28, 28, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 28, 28, 28],
	"messy": [-1, 17, 16, 13, 14, 12, 14, 13, 12, 14, 13, 12, 14, 13, 12, 13, 13, 16, 17, -1],
	"long": [31, 31, 31, 16, 15, 14, 13, 12, 11, 11, 11, 11, 12, 13, 14, 15, 16, 31, 31, 31],
	"bald": [-1, 20, 20, 20, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 20, 20, 20, -1],
}

const FONT := {
	"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
	"D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
	"G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"],
	"N": ["1001", "1101", "1011", "1001", "1001"], "O": ["010", "101", "101", "101", "010"], "R": ["110", "101", "110", "101", "101"],
	"S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"],
	"V": ["101", "101", "101", "101", "010"], "W": ["10001", "10001", "10101", "10101", "01010"], "M": ["10001", "11011", "10101", "10001", "10001"],
	"Y": ["101", "101", "010", "010", "010"], "L": ["100", "100", "100", "100", "111"], "P": ["110", "101", "110", "100", "100"],
	"K": ["101", "101", "110", "101", "101"], "?": ["110", "001", "010", "000", "010"], "2": ["110", "001", "010", "100", "111"],
	"0": ["010", "101", "101", "101", "010"], "6": ["011", "100", "110", "101", "010"], "1": ["010", "110", "010", "010", "111"],
	"5": ["111", "100", "110", "001", "110"], "4": ["101", "101", "111", "001", "001"], " ": ["00", "00", "00", "00", "00"],
	"!": ["1", "1", "1", "0", "1"], "3": ["110", "001", "010", "001", "110"], "7": ["111", "001", "010", "010", "010"],
	"8": ["010", "101", "010", "101", "010"], "9": ["010", "101", "011", "001", "110"], "-": ["000", "000", "111", "000", "000"], ".": ["0", "0", "0", "0", "1"],
}

var img: Image
var oy := 0             # vertical offset of the head for the current frame
var ch: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://art/backgrounds"))
	for id in CHARS:
		_build_character(id)
	_build_backgrounds()
	print("Art build complete")
	quit()


# ====================================================================== drawing helpers

func C(hex: String) -> Color:
	return Color(hex)


func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(xx, yy, c)


func frame(x: int, y: int, w: int, h: int, c: Color) -> void:
	rect(x, y, w, 1, c)
	rect(x, y + h - 1, w, 1, c)
	rect(x, y, 1, h, c)
	rect(x + w - 1, y, 1, h, c)


func ell(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 2):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 2):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(x, y, c)


func poly(pts: PackedVector2Array, c: Color) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(int(r.position.y), int(r.end.y) + 1):
		for x in range(int(r.position.x), int(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), pts):
				px(x, y, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func capsule(a: Vector2, b: Vector2, r: float, c: Color) -> void:
	var lo := Vector2(min(a.x, b.x), min(a.y, b.y)) - Vector2(r + 1, r + 1)
	var hi := Vector2(max(a.x, b.x), max(a.y, b.y)) + Vector2(r + 1, r + 1)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p := Vector2(x, y)
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= r:
				px(x, y, c)


## Bayer-dithered vertical gradient through a list of colours.
func vgrad(x: int, y: int, w: int, h: int, cols: Array) -> void:
	for yy in range(h):
		var t = float(yy) / max(1, h - 1) * (cols.size() - 1)
		var i := mini(int(t), cols.size() - 2)
		var f = t - i
		for xx in range(w):
			var th = (BAYER[(y + yy) % 4][(x + xx) % 4] + 0.5) / 16.0
			px(x + xx, y + yy, C(cols[i + 1]) if f > th else C(cols[i]))


func dither_rect(x: int, y: int, w: int, h: int, a: Color, b: Color, amount: float) -> void:
	for yy in range(h):
		for xx in range(w):
			var th = (BAYER[(y + yy) % 4][(x + xx) % 4] + 0.5) / 16.0
			px(x + xx, y + yy, b if amount > th else a)


## Lighten (or tint) existing pixels inside a polygon with ordered dithering.
func light_overlay(pts: PackedVector2Array, tint: Color, strength: float) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(int(r.position.y), int(r.end.y) + 1):
		for x in range(int(r.position.x), int(r.end.x) + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if not Geometry2D.is_point_in_polygon(Vector2(x, y), pts):
				continue
			var th = (BAYER[y % 4][x % 4] + 0.5) / 16.0
			if strength > th:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(tint, 0.35))


func text(s: String, x: int, y: int, c: Color, scale: int = 1) -> int:
	var cx := x
	for chr in s:
		var g: Array = FONT.get(chr, FONT["?"])
		for row in range(g.size()):
			var line_s: String = g[row]
			for col in range(line_s.length()):
				if line_s[col] == "1":
					rect(cx + col * scale, y + row * scale, scale, scale, c)
		cx += (String(g[0]).length() + 1) * scale
	return cx


func text_width(s: String, scale: int = 1) -> int:
	var w := 0
	for chr in s:
		w += (String(FONT.get(chr, FONT["?"])[0]).length() + 1) * scale
	return w - scale


## Selective outline: transparent pixels next to opaque ones get a darkened neighbour colour.
func outline_outer() -> void:
	var src := img.duplicate()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= img.get_width() or ny >= img.get_height():
					continue
				var n = src.get_pixel(nx, ny)
				if n.a > 0.0:
					img.set_pixel(x, y, n.darkened(0.72))
					break


# ====================================================================== characters

func ramp(key: String, i: int) -> Color:
	return C(ch[key][i])


func ink(c: Color) -> Color:
	return c.darkened(0.7)


func _build_character(id: String) -> void:
	ch = CHARS[id]
	var states := _state_table(id)
	var unique: Array = []     # frame spec keys in sheet order
	var images: Array = []
	var out_states := {}
	for st in states:
		var s: Dictionary = states[st]
		var idxs: Array = []
		for spec in s["frames"]:
			var key := JSON.stringify(spec)
			var at := unique.find(key)
			if at == -1:
				images.append(_render(spec))
				unique.append(key)
				at = unique.size() - 1
			idxs.append(at)
		out_states[st] = {
			"name": STATE_NAMES.get(st, st.replace("SUP_", "").capitalize()),
			"frames": idxs, "durations": s["durations"], "loop": s["loop"],
			"reduced_motion_frame": idxs[s.get("rm", 0)],
		}
	var rows := int(ceil(images.size() / float(SHEET_COLS)))
	var sheet := Image.create(FW * SHEET_COLS, FH * rows, false, Image.FORMAT_RGBA8)
	for i in images.size():
		sheet.blit_rect(images[i], Rect2i(0, 0, FW, FH), Vector2i((i % SHEET_COLS) * FW, (i / SHEET_COLS) * FH))
	var dir = "res://art/characters/" + ch["dir"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	sheet.save_png(ProjectSettings.globalize_path(dir + "/sheet.png"))
	var meta := {
		"actor": id, "kind": ch["kind"], "sheet": "sheet.png", "frame_size": [FW, FH], "columns": SHEET_COLS,
		"fps": FPS, "pivot": [FW / 2, FH], "duration_unit": "frames_at_fps",
		"fallback": "A01" if ch["kind"] == "principal" else "SUP_NEUTRAL", "states": out_states,
	}
	var f := FileAccess.open(ProjectSettings.globalize_path(dir + "/animation.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  "))
	f.close()
	print("  %s: %d states, %d unique frames" % [id, out_states.size(), images.size()])


func _f(over: Dictionary) -> Dictionary:
	var d := {"eyes": "open", "brows": "normal", "mouth": "closed", "pose": "none", "dy": 0, "g": 0, "blush": false}
	d.merge(over, true)
	return d


func _st(frames: Array, durations: Array, loop: bool, rm: int = 0) -> Dictionary:
	return {"frames": frames, "durations": durations, "loop": loop, "rm": rm}


func _state_table(id: String) -> Dictionary:
	var t := {}
	var neutral := _st([_f({}), _f({"eyes": "half"}), _f({"eyes": "closed"}), _f({"eyes": "half"})], [66, 1, 2, 1], true)
	var speaking := _st([_f({}), _f({"mouth": "half"}), _f({"mouth": "open"}), _f({"mouth": "half"})], [2, 2, 3, 2], true)
	var concerned := _st([_f({"brows": "worried", "mouth": "frown", "eyes": "down"}), _f({"brows": "worried", "mouth": "frown", "eyes": "closed"})], [60, 2], true)
	var confident := _st([_f({"pose": "crossed", "eyes": "closed", "mouth": "smirk"}), _f({"pose": "crossed", "eyes": "half", "mouth": "smirk"})], [3, 40], false, 1)
	if ch["kind"] == "principal":
		t["A01"] = neutral
		t["A02"] = speaking
		t["A03"] = _st([_f({"pose": "chin", "eyes": "side", "brows": "raised", "mouth": "flat"}), _f({"pose": "chin", "eyes": "closed", "brows": "raised", "mouth": "flat"})], [44, 3], true)
		t["A04"] = confident
		t["A05"] = _st([_f({"pose": "palm_wind", "brows": "angry"}), _f({"pose": "palm", "brows": "angry", "mouth": "open", "dy": -1}), _f({"pose": "palm", "brows": "angry", "mouth": "open"})], [3, 2, 40], false, 2)
		t["A06"] = _st([_f({"pose": "doc_low"}), _f({"pose": "doc_high", "mouth": "half"}), _f({"pose": "doc_high", "mouth": "smirk"})], [3, 3, 40], false, 2)
		t["A07"] = _st([_f({"eyes": "wide", "brows": "raised", "mouth": "o", "dy": -1}), _f({"eyes": "wide", "brows": "raised", "mouth": "o"})], [2, 40], false, 1)
		t["A08"] = concerned
		t["A09"] = _st([_f({"pose": "forehead", "brows": "angry", "eyes": "closed", "mouth": "frown"}), _f({"pose": "forehead", "brows": "angry", "eyes": "closed", "mouth": "frown", "dy": 1})], [20, 20], true)
		t["A10"] = _st([_f({"eyes": "happy", "brows": "raised", "mouth": "smile", "dy": -1}), _f({"eyes": "happy", "brows": "raised", "mouth": "smile"})], [3, 40], false, 1)
		t["A11"] = _st([_f({}), _f({"dy": 1}), _f({}), _f({"eyes": "closed"})], [30, 4, 30, 2], true)
		t["A12"] = _signature(ch["sig"])
	else:
		for s in ch["states"]:
			match s:
				"SUP_NEUTRAL": t[s] = neutral
				"SUP_SPEAKING": t[s] = speaking
				"SUP_CONCERNED": t[s] = concerned
				"SUP_RELIEVED": t[s] = _st([_f({"eyes": "happy", "brows": "raised", "mouth": "smile", "blush": true})], [40], true)
				"SUP_HESITANT": t[s] = _st([_f({"pose": "hold_arm", "eyes": "side_down", "brows": "worried", "mouth": "flat"}), _f({"pose": "hold_arm", "eyes": "closed", "brows": "worried", "mouth": "flat"})], [50, 2], true)
				"SUP_FORMAL": t[s] = _st([_f({"pose": "clasp"}), _f({"pose": "clasp", "eyes": "closed"})], [66, 2], true)
				"SUP_CONFIDENT": t[s] = confident
	return t


func _signature(sig: String) -> Dictionary:
	match sig:
		"point":     # Vera points
			return _st([_f({"pose": "point_wind", "brows": "angry"}), _f({"pose": "point", "brows": "angry", "mouth": "open", "dy": -1}), _f({"pose": "point", "brows": "angry"})], [3, 2, 40], false, 2)
		"notebook":  # Audrey closes notebook
			return _st([_f({"pose": "book_open", "eyes": "down"}), _f({"pose": "book_mid", "eyes": "down"}), _f({"pose": "book_closed", "eyes": "closed"}), _f({"pose": "book_closed", "mouth": "smile"})], [8, 2, 3, 40], false, 3)
		"notes":     # Sally opens notes
			return _st([_f({"pose": "notes_closed"}), _f({"pose": "notes_mid", "eyes": "down"}), _f({"pose": "notes_open", "eyes": "down"})], [4, 2, 40], false, 2)
		"glasses":   # Laurence adjusts glasses
			return _st([_f({"pose": "glasses_rise"}), _f({"pose": "glasses", "eyes": "closed"}), _f({"pose": "glasses", "eyes": "closed", "g": -1}), _f({"mouth": "flat"})], [3, 4, 4, 40], false, 3)
		"jacket":    # Julian straightens jacket
			return _st([_f({"pose": "lapels_low"}), _f({"pose": "lapels_high", "eyes": "closed", "dy": -1}), _f({"pose": "lapels_low", "mouth": "smirk"}), _f({"eyes": "half", "mouth": "smirk"})], [3, 3, 3, 40], false, 3)
		"folder":    # Mona closes folder
			return _st([_f({"pose": "folder_open", "eyes": "down"}), _f({"pose": "folder_mid", "eyes": "down"}), _f({"pose": "folder_closed", "eyes": "half", "mouth": "smirk"})], [6, 2, 40], false, 2)
	return _st([_f({})], [40], true)


func _render(spec: Dictionary) -> Image:
	img = Image.create(FW, FH, false, Image.FORMAT_RGBA8)
	oy = int(spec["dy"])
	_hair_back()
	_torso()
	_neck()
	_head(spec)
	_hair_front()
	_head_accessories(spec)
	_pose(spec["pose"])
	outline_outer()
	return img


func _hair_back() -> void:
	var hb := ramp("hair", 1)
	var hs := ramp("hair", 2)
	match ch["style"]:
		"ponytail":
			ell(42, 10 + oy, 4, 3.2, hb)
			capsule(Vector2(44, 12 + oy), Vector2(46, 26 + oy), 2.6, hb)
			capsule(Vector2(46, 26 + oy), Vector2(45, 36 + oy), 2.0, hs)
			ell(31.5, 16 + oy, 9.6, 9, hb)
		"bob":
			ell(31.5, 16 + oy, 10.2, 10, hb)
			rect(21, 16 + oy, 22, 12, hb)
			rect(21, 26 + oy, 22, 2, hs)
		"curly":
			for i in range(15):
				var a := lerpf(PI * 0.75, PI * 2.25, i / 14.0)
				ell(31.5 + cos(a) * 11.0, 16 + oy + sin(a) * 10.0, 4.2, 4.0, hb if i % 3 else hs)
		"bob_streak":
			ell(31.5, 16 + oy, 10, 10, hb)
			rect(21, 16 + oy, 22, 13, hb)
		"long":
			ell(31.5, 16 + oy, 10, 10, hb)
			rect(21, 16 + oy, 22, 30, hb)
			rect(21, 40 + oy, 22, 6, hs)
		"short", "messy", "slick":
			ell(31.5, 14 + oy, 8.4, 6.5, hb)


func _torso() -> void:
	var hl := ramp("cloth", 0)
	var base := ramp("cloth", 1)
	var sh := ramp("cloth", 2)
	var body := PackedVector2Array([Vector2(24, 31), Vector2(39, 31), Vector2(48, 33), Vector2(52, 39),
		Vector2(54, 72), Vector2(9, 72), Vector2(11, 39), Vector2(15, 33)])
	poly(body, base)
	# light from the upper left
	for y in range(31, FH):
		for x in range(FW):
			if img.get_pixel(x, y) != base:
				continue
			if x >= 46 or (y > 66 and x > 40):
				px(x, y, sh)
			elif x <= 15 or (y <= 34 and x < 30):
				px(x, y, hl)
	line(17, 46, 17, 71, sh)   # sleeve seams
	line(46, 46, 46, 71, sh)
	var s0 := ramp("shirt", 0)
	var s1 := ramp("shirt", 1)
	match ch["outfit"]:
		"blazer", "suit":
			poly(PackedVector2Array([Vector2(27, 31), Vector2(36, 31), Vector2(31.5, 46)]), s0)
			line(26, 31, 31, 47, sh)
			line(37, 31, 32, 47, sh)
			line(27, 33, 29, 38, hl)
			px(28, 31, s1); px(35, 31, s1); px(29, 32, s1); px(34, 32, s1)
			if ch.has("tie"):
				var t: Array = ch["tie"]
				poly(PackedVector2Array([Vector2(30.5, 34), Vector2(32.5, 34), Vector2(33.4, 44), Vector2(31.5, 47), Vector2(29.6, 44)]), C(t[1]))
				rect(30, 32, 3, 2, C(t[2]))
				line(31, 35, 31, 43, C(t[0]))
			px(31, 52, sh); px(31, 60, sh)   # buttons
		"cardigan":
			poly(PackedVector2Array([Vector2(26, 31), Vector2(37, 31), Vector2(31.5, 50)]), s0)
			line(26, 31, 31, 51, sh)
			line(37, 31, 32, 51, sh)
			for by in [54, 59, 64, 69]:
				px(31, by, C("#e8e2d2")); px(32, by, C("#c9c0aa"))
			line(31, 51, 31, 71, sh)
		"jacket_open":
			poly(PackedVector2Array([Vector2(25, 31), Vector2(38, 31), Vector2(40, 72), Vector2(23, 72)]), s1)
			rect(27, 31, 10, 2, s0)
			line(24, 32, 22, 71, sh)
			line(39, 32, 41, 71, sh)
			line(25, 34, 23, 60, hl)
		"shirt":
			poly(PackedVector2Array([Vector2(24, 30), Vector2(31, 32), Vector2(27, 37)]), ramp("cloth", 0))
			poly(PackedVector2Array([Vector2(39, 30), Vector2(32, 32), Vector2(36, 37)]), ramp("cloth", 0))
			line(31, 33, 31, 71, sh)
			for by in [38, 45, 52, 59, 66]:
				px(32, by, C("#e8eef6"))
			frame(36, 42, 7, 6, sh)
			px(23, 30, ink(hl)); px(40, 30, ink(hl))
		"turtleneck":
			rect(27, 27, 10, 6, s0)
			rect(27, 31, 10, 2, s1)
			poly(PackedVector2Array([Vector2(27, 33), Vector2(36, 33), Vector2(31.5, 47)]), s0)
			line(26, 33, 31, 48, sh)
			line(37, 33, 32, 48, sh)
			rect(40, 40, 2, 2, C("#d4a83a"))   # lapel pin
		"cardigan_round":
			poly(PackedVector2Array([Vector2(25, 31), Vector2(38, 31), Vector2(37, 46), Vector2(26, 46)]), s0)
			rect(27, 31, 10, 1, s1)
			line(25, 33, 27, 71, sh)
			line(38, 33, 36, 71, sh)
	for a in ch["acc"]:
		match a:
			"lanyard":
				line(27, 31, 23, 49, C("#c0392b"))
				line(36, 31, 25, 49, C("#c0392b"))
				rect(20, 49, 7, 8, C("#f6f6f2"))
				rect(20, 49, 7, 2, C("#4fc3c9"))
				rect(21, 53, 5, 1, C("#9aa7b6"))
			"lanyard_side":
				line(28, 31, 27, 50, C("#4fc3c9"))
				rect(24, 50, 7, 8, C("#f6f6f2"))
				rect(24, 50, 7, 2, C("#2c8a8f"))
			"pocket_square":
				rect(42, 43, 4, 2, C("#ffffff"))
				px(43, 42, C("#ffffff"))


func _neck() -> void:
	rect(28, 24 + oy, 8, 9 - oy, ramp("skin", 2))
	rect(28, 24 + oy, 8, 2, ramp("skin", 2).darkened(0.12))


func _head(spec: Dictionary) -> void:
	var s0 := ramp("skin", 0)
	var s1 := ramp("skin", 1)
	var s2 := ramp("skin", 2)
	# ears
	rect(22, 18 + oy, 2, 4, s2.darkened(0.35))
	rect(40, 18 + oy, 2, 4, s2.darkened(0.35))
	rect(23, 19 + oy, 1, 2, s1)
	rect(40, 19 + oy, 1, 2, s2)
	# face with outline
	ell(31.5, 17.5 + oy, 9.0, 10.4, ink(s2))
	ell(31.5, 17.5 + oy, 8.0, 9.4, s1)
	for y in range(8 + oy, 28 + oy):
		for x in range(24, 40):
			if img.get_pixel(x, y) != s1:
				continue
			if x >= 37 or y >= 25 + oy and x >= 34:
				px(x, y, s2)
			elif x <= 26 and y <= 18 + oy:
				px(x, y, s0)
	px(31, 21 + oy, s2)   # nose
	px(31, 22 + oy, s2)
	if spec["blush"]:
		px(26, 22 + oy, C("#e88a8a")); px(27, 22 + oy, C("#e88a8a"))
		px(36, 22 + oy, C("#e88a8a")); px(37, 22 + oy, C("#e88a8a"))
	_eyes(spec["eyes"])
	_brows(spec["brows"])
	_mouth(spec["mouth"])


func _eyes(kind: String) -> void:
	var lash := C("#1d1520")
	var white := C("#fbfbf6")
	var iris := C(ch["eye"])
	var shine := Color.WHITE
	for side in [0, 1]:
		var x0: int = 26 if side == 0 else 34
		var y0 := 18 + oy
		match kind:
			"open", "side", "down", "side_down":
				var dx := 1 if kind.begins_with("side") else 0
				var dy := 1 if kind.ends_with("down") else 0
				rect(x0, y0 + dy, 4, 1, lash)
				rect(x0, y0 + 1 + dy, 4, 2 - dy, white)
				rect(x0 + 1 + dx, y0 + 1 + dy, 2, 2 - dy, iris)
				if dy == 0:
					px(x0 + 1 + dx, y0 + 1, shine)
				px(x0 - 1 if side == 0 else x0 + 4, y0, lash)
			"half":
				rect(x0, y0 + 1, 4, 1, lash)
				rect(x0 + 1, y0 + 2, 2, 1, iris)
			"closed":
				rect(x0, y0 + 2, 4, 1, lash)
				px(x0 - 1 if side == 0 else x0 + 4, y0 + 1, lash)
			"wide":
				rect(x0, y0 - 1, 4, 1, lash)
				rect(x0, y0, 4, 3, white)
				rect(x0 + 1, y0 + 1, 2, 2, iris)
				px(x0 + 1, y0 + 1, shine)
			"happy":
				px(x0, y0 + 2, lash); px(x0 + 1, y0 + 1, lash); px(x0 + 2, y0 + 1, lash); px(x0 + 3, y0 + 2, lash)


func _brows(kind: String) -> void:
	var b := ramp("hair", 2) if ch["style"] != "bob" else C("#8a8580")
	if ch["style"] == "bald":
		b = C("#6a6a6a")
	var y := 15 + oy
	for side in [0, 1]:
		var xs := [26, 27, 28, 29] if side == 0 else [37, 36, 35, 34]   # outer -> inner
		var ys: Array
		match kind:
			"raised": ys = [y - 1, y - 2, y - 2, y - 1]
			"worried": ys = [y + 1, y, y - 1, y - 1]
			"angry": ys = [y - 1, y - 1, y, y + 1]
			_: ys = [y, y - 1, y - 1, y]
		for i in 4:
			px(xs[i], ys[i], b)


func _mouth(kind: String) -> void:
	var lip := C("#7a2e2e")
	var dark := C("#3a1418")
	var tongue := C("#d0606a")
	var y := 25 + oy
	match kind:
		"closed": rect(30, y, 4, 1, lip)
		"flat": rect(30, y, 3, 1, lip)
		"half":
			rect(30, y, 4, 1, dark)
			rect(31, y + 1, 2, 1, dark)
		"open":
			rect(30, y, 4, 2, dark)
			rect(31, y + 1, 2, 1, tongue)
		"smile":
			px(29, y - 1, lip); rect(30, y, 4, 1, lip); px(34, y - 1, lip)
		"frown":
			px(29, y + 1, lip); rect(30, y, 4, 1, lip); px(34, y + 1, lip)
		"smirk":
			rect(30, y, 3, 1, lip); px(33, y - 1, lip)
		"o":
			rect(31, y - 1, 2, 3, dark)
			px(30, y, dark); px(33, y, dark)


func _hair_front() -> void:
	var h0 := ramp("hair", 0)
	var h1 := ramp("hair", 1)
	var h2 := ramp("hair", 2)
	var style: String = ch["style"]
	var bottoms: Array = FRINGES[style]
	var cap_cy := 13.0
	var cap_ry := 7.2
	var cap_rx := 9.6
	if style == "curly":
		cap_ry = 8.5
		cap_rx = 10.5
	for i in range(bottoms.size()):
		var x := 22 + i
		var bottom: int = bottoms[i]
		if bottom < 0:
			continue
		var top := 6
		var u := (x - 31.5) / cap_rx
		if absf(u) < 1.0:
			top = int(round(cap_cy - cap_ry * sqrt(1.0 - u * u)))
		else:
			top = int(cap_cy)
		if style == "bald":
			top = 13
		for y in range(top, bottom + 1):
			var c := h1
			if x >= 37 or y >= bottom - 1:
				c = h2
			px(x, y + oy, c)
		px(x, top - 1 + oy, ink(h2))
	# side outline pixels for long side locks
	if style != "bald":
		for y in range(9, 14):
			if img.get_pixel(21, y + oy).a == 0.0:
				px(21, y + oy, ink(h2))
			if img.get_pixel(42, y + oy).a == 0.0:
				px(42, y + oy, ink(h2))
	# highlights
	match style:
		"slick":
			for i in range(5):
				px(26 + i * 2, 8 + oy, h0)
				px(27 + i * 2, 9 + oy, h0)
		"curly":
			for p in [Vector2i(25, 9), Vector2i(29, 8), Vector2i(33, 8), Vector2i(27, 11), Vector2i(31, 10)]:
				px(p.x, p.y + oy, h0)
		"bald":
			ell(31.5, 12 + oy, 7.5, 5, ramp("skin", 1))
			px(29, 9 + oy, ramp("skin", 0)); px(30, 9 + oy, ramp("skin", 0))
		_:
			for x in range(26, 32):
				px(x, 9 + oy, h0)
			px(27, 10 + oy, h0); px(28, 10 + oy, h0)
	if style == "bob_streak":
		for y in range(7, 15):
			px(28, y + oy, C("#c9c7cc"))
			px(29, y + oy, C("#a9a7ae"))
	if "hairtie" in ch["acc"]:
		rect(40, 9 + oy, 2, 3, C("#d64545"))


func _head_accessories(spec: Dictionary) -> void:
	if "glasses" in ch["acc"]:
		var gy := 17 + oy + int(spec["g"])
		var fc := C("#24242c")
		frame(25, gy, 6, 5, fc)
		frame(33, gy, 6, 5, fc)
		rect(31, gy + 1, 2, 1, fc)
		px(24, gy + 1, fc)
		px(39, gy + 1, fc)
		px(26, gy + 1, C("#ffffff"))
		px(34, gy + 1, C("#ffffff"))
	if "pearls" in ch["acc"]:
		px(23, 22 + oy, C("#ffffff"))
	if "gold_earring" in ch["acc"]:
		px(23, 22 + oy, C("#e0b84a"))
		px(23, 23 + oy, C("#b8902a"))


# ---------------------------------------------------------------- arms, hands and props

func _arm(pts: Array, r: float = 3.4) -> void:
	var sleeve := ramp("cloth", 1)
	var dark := ink(ramp("cloth", 2))
	for i in range(pts.size() - 1):
		capsule(pts[i], pts[i + 1], r + 1.0, dark)
	for i in range(pts.size() - 1):
		capsule(pts[i], pts[i + 1], r, sleeve)
	# cuff
	var end: Vector2 = pts[pts.size() - 1]
	var prev: Vector2 = pts[pts.size() - 2]
	var cuff := end - (end - prev).normalized() * 1.5
	ell(cuff.x, cuff.y, 1.6, 1.6, ramp("shirt", 1))


func _hand(c: Vector2, rx: float = 2.4, ry: float = 2.4) -> void:
	ell(c.x, c.y, rx + 1.0, ry + 1.0, ink(ramp("skin", 2)))
	ell(c.x, c.y, rx, ry, ramp("skin", 1))
	px(int(c.x) - 1, int(c.y) - 1, ramp("skin", 0))


func _paper(x: int, y: int, w: int, h: int) -> void:
	frame(x - 1, y - 1, w + 2, h + 2, C("#5a5248"))
	rect(x, y, w, h, C("#fbf8f0"))
	for ly in range(y + 2, y + h - 2, 2):
		rect(x + 2, ly, w - 4 - (ly % 3), 1, C("#b9b3a8"))


func _book(x: int, y: int, w: int, h: int, cover: Color) -> void:
	frame(x - 1, y - 1, w + 2, h + 2, ink(cover))
	rect(x, y, w, h, cover)
	rect(x, y, 2, h, cover.darkened(0.3))
	rect(x + 3, y + 2, w - 5, 1, cover.lightened(0.3))


func _open_pages(x: int, y: int, w: int, h: int, cover: Color, spiral: bool = false) -> void:
	frame(x - 2, y - 1, w + 4, h + 3, ink(cover))
	rect(x - 1, y, w + 2, h + 2, cover)
	rect(x, y, w, h, C("#fbf8f0"))
	line(x + w / 2, y, x + w / 2, y + h - 1, C("#c9c2b4"))
	for ly in range(y + 2, y + h - 1, 2):
		rect(x + 1, ly, w / 2 - 2, 1, C("#b9b3a8"))
		rect(x + w / 2 + 1, ly, w / 2 - 3, 1, C("#b9b3a8"))
	if spiral:
		for sx in range(x + 1, x + w, 2):
			px(sx, y - 1, C("#8a8f99"))


func _pose(p: String) -> void:
	var prop := C(ch.get("prop", "#8c2f39"))
	match p:
		"none":
			pass
		"chin":
			_arm([Vector2(17, 64), Vector2(17, 52), Vector2(28, 33 + oy)])
			_hand(Vector2(30, 30 + oy), 2.6, 2.2)
		"forehead":
			_arm([Vector2(17, 64), Vector2(14, 48), Vector2(24, 22 + oy)])
			_hand(Vector2(27, 15 + oy), 3.2, 2.4)
		"point_wind":
			_arm([Vector2(46, 64), Vector2(54, 56), Vector2(45, 46)])
			_hand(Vector2(43, 45))
		"point":
			_arm([Vector2(46, 44), Vector2(54, 47), Vector2(58, 41)])
			_hand(Vector2(59, 39), 2.2, 2.2)
			line(61, 38, 63, 38, ink(ramp("skin", 2)))
			line(61, 40, 63, 40, ink(ramp("skin", 2)))
			line(61, 39, 63, 39, ramp("skin", 1))
		"palm_wind":
			_arm([Vector2(46, 64), Vector2(54, 56), Vector2(47, 46)])
			_hand(Vector2(46, 45))
		"palm":
			_arm([Vector2(46, 44), Vector2(55, 46), Vector2(56, 36)])
			var sk := ramp("skin", 1)
			var ol := ink(ramp("skin", 2))
			rect(51, 23, 11, 13, ol)
			rect(52, 24, 9, 11, sk)
			rect(50, 29, 3, 4, ol)
			rect(51, 30, 2, 2, sk)
			for fx in [54, 56, 58]:
				line(fx, 24, fx, 27, ramp("skin", 2))
			rect(52, 24, 1, 3, ramp("skin", 0))
		"doc_low", "doc_high":
			var py := 46 if p == "doc_low" else 38
			_arm([Vector2(17, 64), Vector2(15, 62), Vector2(21, py + 8)])
			_arm([Vector2(46, 64), Vector2(48, 62), Vector2(42, py + 8)])
			_paper(22, py, 20, 18)
			rect(24, py + 2, 6, 3, C("#c0392b").lightened(0.2))   # header stamp
			_hand(Vector2(21, py + 9), 2.2, 2.2)
			_hand(Vector2(42, py + 9), 2.2, 2.2)
		"crossed":
			_arm([Vector2(46, 60), Vector2(44, 52), Vector2(21, 53)])
			_hand(Vector2(19, 52), 2.2, 2.2)
			_arm([Vector2(17, 60), Vector2(19, 55), Vector2(42, 56)])
			_hand(Vector2(44, 55), 2.2, 2.2)
		"glasses_rise":
			_arm([Vector2(46, 64), Vector2(52, 56), Vector2(45, 41)])
			_hand(Vector2(44, 39))
		"glasses":
			_arm([Vector2(46, 64), Vector2(48, 46), Vector2(40, 26 + oy)])
			_hand(Vector2(39, 22 + oy), 2.0, 2.2)
			line(37, 19 + oy, 38, 20 + oy, ramp("skin", 1))
		"lapels_low", "lapels_high":
			var hy := 46 if p == "lapels_low" else 41
			_arm([Vector2(17, 64), Vector2(16, 60), Vector2(25, hy + 1)])
			_arm([Vector2(46, 64), Vector2(47, 60), Vector2(38, hy + 1)])
			_hand(Vector2(27, hy), 2.0, 2.4)
			_hand(Vector2(36, hy), 2.0, 2.4)
		"book_closed":
			_arm([Vector2(17, 64), Vector2(16, 62), Vector2(22, 54)])
			_arm([Vector2(46, 64), Vector2(47, 62), Vector2(41, 54)])
			_book(24, 43, 16, 15, prop)
			_hand(Vector2(23, 53), 2.0, 2.0)
			_hand(Vector2(40, 53), 2.0, 2.0)
		"book_mid":
			_arm([Vector2(17, 64), Vector2(15, 62), Vector2(20, 55)])
			_arm([Vector2(46, 64), Vector2(48, 62), Vector2(43, 55)])
			_book(24, 45, 16, 13, prop)
			_book(33, 42, 10, 15, prop.lightened(0.1))
			_hand(Vector2(21, 54), 2.0, 2.0)
			_hand(Vector2(43, 54), 2.0, 2.0)
		"book_open":
			_arm([Vector2(17, 64), Vector2(14, 62), Vector2(17, 56)])
			_arm([Vector2(46, 64), Vector2(49, 62), Vector2(46, 56)])
			_open_pages(18, 46, 28, 11, prop)
			_hand(Vector2(17, 55), 2.0, 2.0)
			_hand(Vector2(46, 55), 2.0, 2.0)
		"notes_closed":
			_arm([Vector2(46, 64), Vector2(47, 62), Vector2(40, 54)])
			_book(29, 45, 11, 13, prop)
			for sx in range(30, 40, 2):
				px(sx, 44, C("#8a8f99"))
			_hand(Vector2(39, 54), 2.0, 2.0)
		"notes_mid":
			_arm([Vector2(17, 64), Vector2(16, 62), Vector2(24, 55)])
			_arm([Vector2(46, 64), Vector2(47, 62), Vector2(40, 55)])
			_book(27, 46, 13, 11, prop)
			_paper(28, 41, 11, 5)
			_hand(Vector2(25, 54), 2.0, 2.0)
			_hand(Vector2(40, 54), 2.0, 2.0)
		"notes_open":
			_arm([Vector2(17, 64), Vector2(15, 62), Vector2(21, 54)])
			_arm([Vector2(46, 64), Vector2(48, 62), Vector2(42, 54)])
			_open_pages(22, 43, 20, 11, prop, true)
			_hand(Vector2(21, 53), 2.0, 2.0)
			_hand(Vector2(42, 53), 2.0, 2.0)
		"folder_open":
			_arm([Vector2(17, 64), Vector2(14, 62), Vector2(18, 55)])
			_arm([Vector2(46, 64), Vector2(49, 62), Vector2(45, 55)])
			_open_pages(19, 45, 26, 11, prop)
			_hand(Vector2(18, 54), 2.0, 2.0)
			_hand(Vector2(45, 54), 2.0, 2.0)
		"folder_mid":
			_arm([Vector2(17, 64), Vector2(15, 62), Vector2(21, 55)])
			_arm([Vector2(46, 64), Vector2(48, 62), Vector2(43, 55)])
			_book(23, 45, 18, 13, prop)
			_paper(30, 42, 12, 6)
			_hand(Vector2(22, 54), 2.0, 2.0)
			_hand(Vector2(43, 54), 2.0, 2.0)
		"folder_closed":
			_arm([Vector2(17, 64), Vector2(16, 62), Vector2(22, 55)])
			_arm([Vector2(46, 64), Vector2(47, 62), Vector2(41, 55)])
			_book(23, 43, 18, 15, prop)
			_hand(Vector2(23, 54), 2.0, 2.0)
			_hand(Vector2(41, 54), 2.0, 2.0)
		"hold_arm":
			_arm([Vector2(46, 64), Vector2(46, 64), Vector2(21, 58)])
			_hand(Vector2(19, 57), 2.2, 2.4)
		"clasp":
			_arm([Vector2(17, 64), Vector2(19, 66), Vector2(28, 64)])
			_arm([Vector2(46, 64), Vector2(44, 66), Vector2(35, 64)])
			_hand(Vector2(31.5, 63), 3.6, 2.6)
			line(31, 62, 31, 64, ramp("skin", 2))


# ====================================================================== backgrounds

func _new_bg() -> void:
	img = Image.create(320, 180, false, Image.FORMAT_RGBA8)
	rng.seed = 1234


func _save_bg(id: String) -> void:
	img.save_png(ProjectSettings.globalize_path("res://art/backgrounds/%s.png" % id))
	print("  background %s" % id)


func _build_backgrounds() -> void:
	_bg_union_office()
	_bg_consultation()
	_bg_negotiation()
	_bg_tech_office()
	_bg_archive()
	_bg_title()


func _plant(x: int, y: int, scale: float = 1.0) -> void:
	var pot := C("#b5653f")
	rect(x - 7, y, 14, 12, ink(pot))
	rect(x - 6, y + 1, 12, 10, pot)
	rect(x - 7, y, 14, 2, pot.lightened(0.2))
	for i in range(9):
		var a := lerpf(PI * 1.05, PI * 1.95, i / 8.0)
		var tip := Vector2(x + cos(a) * 12 * scale, y - 4 + sin(a) * 16 * scale)
		capsule(Vector2(x, y), tip, 2.2, C("#2f5e33"))
		capsule(Vector2(x, y), tip, 1.4, C("#4c8c4a") if i % 2 else C("#64a85a"))


func _window_view(x: int, y: int, w: int, h: int, sky: Array, day: bool) -> void:
	vgrad(x, y, w, h, sky)
	# far buildings
	var bx := x
	while bx < x + w:
		var bw := rng.randi_range(6, 12)
		var bh := rng.randi_range(h / 4, h / 2)
		rect(bx, y + h - bh, bw, bh, C("#9fb3c4") if day else C("#2a2f4f"))
		if not day:
			for wy in range(y + h - bh + 2, y + h - 2, 3):
				for wx in range(bx + 1, bx + bw - 1, 2):
					if rng.randf() < 0.35:
						px(wx, wy, C("#f2d27a"))
		bx += bw + 1
	if day:
		for i in range(5):
			ell(x + 6 + i * (w / 5.0), y + h - 3, 7, 6, C("#4f8a4c") if i % 2 else C("#5f9e57"))


func _bg_union_office() -> void:
	_new_bg()
	vgrad(0, 0, 320, 100, ["#efe1c4", "#e4d2b0", "#d8c39d"])
	rect(0, 99, 320, 2, C("#7a5133"))
	rect(0, 101, 320, 25, C("#9b6b45"))
	for x in range(0, 320, 20):
		frame(x + 2, 104, 16, 19, C("#7f5536"))
		line(x + 3, 105, x + 16, 105, C("#b07e55"))
	rect(0, 126, 320, 54, C("#8a5a36"))
	for row in range(6):
		var y := 126 + row * 9
		line(0, y, 319, y, C("#6b432a"))
		var off := (row * 37) % 60
		for x in range(off, 320, 60):
			line(x, y, x, y + 8, C("#6b432a"))
	dither_rect(0, 160, 320, 20, C("#8a5a36"), C("#6b432a"), 0.4)
	# window with blinds
	rect(16, 16, 76, 76, C("#c9b896"))
	_window_view(20, 20, 68, 66, ["#7fbde6", "#bfe1f2"], true)
	for y in range(20, 42, 3):
		rect(20, y, 68, 2, C("#efe8d6"))
		line(20, y + 1, 87, y + 1, C("#d6ccb5"))
	rect(52, 20, 4, 66, C("#f3ead8"))
	frame(16, 16, 76, 76, C("#f3ead8"))
	frame(17, 17, 74, 74, C("#f3ead8"))
	rect(13, 91, 82, 4, C("#f7f0e2"))
	rect(13, 94, 82, 1, C("#b9a988"))
	# clock
	ell(108, 14, 7, 7, C("#4a3a2a"))
	ell(108, 14, 6, 6, C("#fbf6ea"))
	line(108, 14, 108, 10, C("#222222"))
	line(108, 14, 111, 15, C("#222222"))
	# notice board
	rect(124, 22, 82, 58, C("#6e4a2c"))
	rect(127, 25, 76, 52, C("#c39c6c"))
	for i in range(160):
		px(127 + rng.randi_range(0, 75), 25 + rng.randi_range(0, 51), C("#a8804f"))
	var notes := [[131, 29, 18, 22, "#fbf8f0"], [153, 28, 16, 14, "#fff2a1"], [173, 30, 26, 18, "#fbf8f0"],
		[132, 55, 14, 16, "#bfe0f7"], [150, 46, 20, 26, "#fbf8f0"], [175, 52, 22, 20, "#f8c8d4"]]
	for n in notes:
		rect(n[0] + 1, n[1] + 1, n[2], n[3], C("#8a6a45"))
		rect(n[0], n[1], n[2], n[3], C(n[4]))
		for ly in range(n[1] + 4, n[1] + n[3] - 2, 2):
			rect(n[0] + 2, ly, n[2] - 4 - (ly % 4), 1, C("#9a9488"))
		px(n[0] + n[2] / 2, n[1] + 1, C("#d63c3c"))
	# UWF banner
	rect(224, 14, 52, 74, C("#1b5e66"))
	rect(226, 16, 48, 70, C("#2c8a8f"))
	frame(229, 19, 42, 64, C("#f4efe6"))
	var tw := text_width("UWF", 3)
	text("UWF", 250 - tw / 2, 28, C("#f4efe6"), 3)
	for i in range(3):
		var hx := 238 + i * 12
		ell(hx, 52, 3, 3, C("#f2c14e"))
		rect(hx - 4, 56, 9, 10, C("#f2c14e"))
	rect(234, 70, 32, 1, C("#f4efe6"))
	text("UNITED", 238, 74, C("#f4efe6"))
	# bookshelf
	rect(284, 24, 34, 102, C("#5e3d24"))
	rect(286, 26, 30, 98, C("#7a5133"))
	var bcols := ["#2c8a8f", "#c0392b", "#f2c14e", "#7f8c8d", "#3f4378", "#e67e22"]
	for s in range(4):
		var sy := 26 + s * 25
		rect(286, sy + 22, 30, 3, C("#5e3d24"))
		var bxx := 287
		while bxx < 314:
			var bw := rng.randi_range(3, 5)
			var bh := rng.randi_range(14, 20)
			var col := C(bcols[rng.randi_range(0, bcols.size() - 1)])
			rect(bxx, sy + 22 - bh, bw, bh, col)
			rect(bxx, sy + 22 - bh, 1, bh, col.lightened(0.25))
			rect(bxx + 1, sy + 22 - bh + 3, bw - 2, 2, C("#f4efe6"))
			bxx += bw + 1
	# desk with monitor
	rect(196, 112, 84, 6, C("#6d4a30"))
	rect(196, 112, 84, 1, C("#93684a"))
	rect(198, 118, 80, 30, C("#5a3d27"))
	frame(204, 122, 30, 10, C("#4a311f"))
	rect(234, 84, 34, 24, C("#2b2f36"))
	rect(236, 86, 30, 20, C("#4fa3c9"))
	for ly in range(88, 104, 3):
		rect(238, ly, 10 + (ly * 7) % 14, 1, C("#d8f0f7"))
	rect(248, 108, 6, 4, C("#2b2f36"))
	rect(242, 111, 18, 2, C("#2b2f36"))
	rect(270, 104, 7, 8, C("#f4efe6"))
	rect(277, 106, 2, 3, C("#f4efe6"))
	rect(271, 105, 5, 1, C("#5a3a20"))
	rect(204, 106, 22, 6, C("#fbf8f0"))
	rect(205, 104, 20, 2, C("#ece6d8"))
	_plant(12, 116, 1.1)
	_save_bg("BG01")


func _bg_consultation() -> void:
	_new_bg()
	vgrad(0, 0, 320, 118, ["#cfdccd", "#bccdb9", "#a9bea6"])
	rect(0, 118, 320, 4, C("#f1ece0"))
	rect(0, 122, 320, 58, C("#6f7c88"))
	dither_rect(0, 122, 320, 58, C("#6f7c88"), C("#64707b"), 0.3)
	ell(160, 156, 120, 22, C("#7d4a3f"))
	ell(160, 156, 114, 19, C("#9a5f4f"))
	ell(160, 156, 100, 14, C("#a86b59"))
	# lamp glow
	light_overlay(PackedVector2Array([Vector2(8, 44), Vector2(40, 44), Vector2(60, 118), Vector2(-12, 118)]), C("#fff4d6"), 0.5)
	rect(23, 44, 2, 78, C("#3a3a3a"))
	rect(17, 120, 14, 3, C("#3a3a3a"))
	poly(PackedVector2Array([Vector2(12, 44), Vector2(36, 44), Vector2(31, 30), Vector2(17, 30)]), C("#f5e6c4"))
	line(12, 44, 36, 44, C("#d8c49a"))
	# framed print
	rect(48, 26, 64, 46, C("#7b5e3b"))
	rect(52, 30, 56, 38, C("#f5f0e6"))
	vgrad(55, 33, 50, 32, ["#f6d9a6", "#f2c49b"])
	ell(92, 42, 5, 5, C("#f6b04e"))
	poly(PackedVector2Array([Vector2(55, 64), Vector2(70, 44), Vector2(84, 58), Vector2(94, 50), Vector2(105, 64)]), C("#6f9c72"))
	poly(PackedVector2Array([Vector2(55, 64), Vector2(66, 54), Vector2(80, 64)]), C("#4f7a52"))
	# window with curtains
	rect(232, 18, 72, 80, C("#efe8d8"))
	_window_view(236, 22, 64, 72, ["#9fd0ec", "#d3ecf6"], true)
	rect(266, 22, 4, 72, C("#efe8d8"))
	for side in [0, 1]:
		var cx: int = 224 if side == 0 else 296
		rect(cx, 14, 16, 90, C("#d9b48a"))
		for fx in range(cx + 2, cx + 16, 4):
			line(fx, 14, fx, 103, C("#b8936a"))
	rect(220, 12, 96, 3, C("#7b5e3b"))
	# shelf
	rect(130, 52, 60, 4, C("#8b6a4a"))
	for i in range(5):
		rect(134 + i * 6, 40, 5, 12, C(["#2c8a8f", "#f2c14e", "#c0392b", "#3f4378", "#7f8c8d"][i]))
	_plant(176, 40, 0.6)
	# chairs and table
	for cx2 in [64, 232]:
		rect(cx2, 96, 26, 42, C("#1b5e66"))
		rect(cx2 + 2, 98, 22, 38, C("#2c8a8f"))
		rect(cx2 + 2, 98, 22, 3, C("#4cb5b5"))
	ell(160, 116, 56, 8, C("#6b4c33"))
	ell(160, 115, 54, 7, C("#9a7451"))
	ell(150, 113, 30, 3, C("#b48c66"))
	rect(155, 122, 10, 30, C("#6b4c33"))
	rect(144, 150, 32, 4, C("#6b4c33"))
	rect(134, 100, 10, 14, C("#bfe3f2"))
	rect(134, 100, 10, 2, C("#e9f6fb"))
	rect(144, 104, 3, 4, C("#bfe3f2"))
	rect(150, 106, 6, 8, C("#d8eef6"))
	rect(176, 104, 14, 9, C("#ffffff"))
	rect(176, 104, 14, 2, C("#4a90e2"))
	rect(181, 101, 4, 3, C("#ffffff"))
	_save_bg("BG02")


func _bg_negotiation() -> void:
	_new_bg()
	rect(0, 0, 320, 180, C("#161c29"))
	rect(0, 0, 320, 8, C("#0e131d"))
	for x in range(20, 320, 50):
		rect(x, 2, 8, 3, C("#f6e7b5"))
	# windows
	for i in range(6):
		var wx := i * 56 - 8
		if wx > 120 and wx < 190:
			continue
		_window_view(maxi(0, wx), 10, mini(50, 320 - maxi(0, wx)), 106, ["#22305a", "#4a3f6b", "#a55e6b", "#e59a6f", "#f3c38a"], false)
		rect(wx + 50, 10, 6, 106, C("#0e131d"))
	# wood wall with logo plate
	rect(128, 8, 64, 110, C("#3b2a20"))
	for x in range(130, 190, 6):
		line(x, 10, x, 116, C("#46322a"))
	rect(134, 44, 52, 14, C("#c9a453"))
	rect(135, 45, 50, 12, C("#e2c06a"))
	text("NORTHBRIDGE", 160 - text_width("NORTHBRIDGE") / 2, 48, C("#3b2a20"))
	rect(0, 116, 320, 4, C("#0e131d"))
	# chair backs
	for cx in [22, 78, 236, 292]:
		rect(cx - 12, 98, 24, 32, C("#0b0d12"))
		rect(cx - 11, 99, 22, 30, C("#1d2029"))
		rect(cx - 9, 101, 6, 26, C("#2b2f3b"))
	# long polished table
	rect(0, 128, 320, 52, C("#3b2a20"))
	rect(0, 127, 320, 2, C("#8a6a4f"))
	for i in range(6):
		var rx := i * 56 + 10
		light_overlay(PackedVector2Array([Vector2(rx, 130), Vector2(rx + 22, 130), Vector2(rx + 10, 180), Vector2(rx - 12, 180)]), C("#c98f6b"), 0.2)
	dither_rect(0, 160, 320, 20, C("#3b2a20"), C("#2a1d16"), 0.5)
	for dx in [40, 120, 210, 270]:
		rect(dx, 136, 22, 14, C("#e8e4dc"))
		rect(dx + 2, 138, 16, 1, C("#a8a29a"))
		rect(dx + 2, 141, 12, 1, C("#a8a29a"))
		rect(dx + 26, 132, 5, 9, C("#b8d8e8"))
		rect(dx + 26, 132, 5, 1, C("#e8f4fa"))
	_save_bg("BG03")


func _bg_tech_office() -> void:
	_new_bg()
	vgrad(0, 0, 320, 120, ["#f6f9fc", "#e8eff6", "#dbe5ee"])
	rect(0, 120, 320, 60, C("#b9c3cc"))
	for x in range(0, 320, 24):
		line(x, 120, x - 20, 179, C("#a7b2bc"))
	for y in [132, 148, 168]:
		line(0, y, 319, y, C("#a7b2bc"))
	# window strip
	_window_view(230, 8, 86, 34, ["#8ec5ea", "#cfe7f6"], true)
	frame(229, 7, 88, 36, C("#9aa9b8"))
	# pendant lamps
	for lx in [40, 160, 280]:
		line(lx, 0, lx, 10, C("#55606b"))
		poly(PackedVector2Array([Vector2(lx - 8, 16), Vector2(lx + 8, 16), Vector2(lx + 4, 10), Vector2(lx - 4, 10)]), C("#2b2f36"))
		rect(lx - 6, 16, 12, 1, C("#fff6c8"))
	# whiteboard with org chart (Daniel's box missing)
	rect(104, 20, 112, 72, C("#9aa9b8"))
	rect(106, 22, 108, 66, C("#ffffff"))
	rect(106, 86, 108, 3, C("#b9c3cc"))
	var ink_c := C("#3a4a5c")
	frame(146, 28, 28, 10, C("#2a5f9e"))
	rect(147, 29, 26, 8, C("#9cc4ef"))
	line(160, 38, 160, 44, ink_c)
	line(124, 44, 196, 44, ink_c)
	for i in range(3):
		var bx := 112 + i * 36
		line(bx + 12, 44, bx + 12, 50, ink_c)
		frame(bx, 50, 24, 9, C("#2a5f9e"))
		rect(bx + 1, 51, 22, 7, C("#cfe3f7"))
		line(bx + 12, 59, bx + 12, 66, ink_c)
		if i == 1:
			for dx in range(0, 22, 3):
				px(bx + 1 + dx, 66, C("#d63c3c"))
				px(bx + 1 + dx, 75, C("#d63c3c"))
			for dy in range(0, 9, 3):
				px(bx + 1, 66 + dy, C("#d63c3c"))
				px(bx + 23, 66 + dy, C("#d63c3c"))
			text("?", bx + 11, 68, C("#d63c3c"))
		else:
			frame(bx + 2, 66, 20, 9, C("#2a5f9e"))
			rect(bx + 3, 67, 18, 7, C("#e8f1fb"))
	rect(110, 84, 6, 2, C("#d63c3c"))
	rect(118, 84, 6, 2, C("#2a5f9e"))
	# glass partitions
	for gx in [92, 226]:
		rect(gx, 8, 2, 112, C("#c5d3df"))
		for i in range(3):
			line(gx - 14 + i * 5, 60 + i * 6, gx - 4 + i * 5, 40 + i * 6, C("#ffffff"))
	text("NORTHBRIDGE", 18, 30, C("#9aa9b8"))
	# desks with monitors
	for dx in [8, 236]:
		rect(dx, 104, 76, 5, C("#f4f6f8"))
		rect(dx, 109, 76, 2, C("#c5ced6"))
		rect(dx + 4, 111, 3, 26, C("#9aa9b8"))
		rect(dx + 69, 111, 3, 26, C("#9aa9b8"))
		for m in range(2):
			var mx = dx + 10 + m * 30
			rect(mx, 78, 26, 18, C("#263238"))
			rect(mx + 2, 80, 22, 14, C("#1f6f78"))
			for ly in range(82, 92, 2):
				rect(mx + 4 + (ly % 4), ly, 8 + (ly * 5 + m * 3) % 10, 1, C("#7fe0e0"))
			rect(mx + 11, 96, 4, 8, C("#263238"))
	_plant(212, 120, 0.9)
	_save_bg("BG05")


func _bg_archive() -> void:
	_new_bg()
	vgrad(0, 0, 320, 180, ["#3a3125", "#2c251c", "#211b14"])
	var box_cols := ["#b08a5a", "#9c7748", "#c39d6a", "#a8824f"]
	for s in range(3):
		var sy := 10 + s * 34
		rect(6, sy + 30, 308, 4, C("#5a4630"))
		rect(6, sy + 30, 308, 1, C("#7a6040"))
		var bx := 10
		while bx < 306:
			var bw := rng.randi_range(18, 26)
			var bh := rng.randi_range(20, 27)
			var col := C(box_cols[rng.randi_range(0, 3)])
			rect(bx, sy + 30 - bh, bw, bh, col.darkened(0.35))
			rect(bx + 1, sy + 31 - bh, bw - 2, bh - 1, col)
			rect(bx + 1, sy + 31 - bh, bw - 2, 2, col.lightened(0.15))
			rect(bx + bw / 2 - 5, sy + 30 - bh / 2 - 3, 10, 6, C("#efe4cc"))
			text(str(20 + rng.randi_range(18, 26)), bx + bw / 2 - 3, sy + 30 - bh / 2 - 2, C("#5a4630"))
			bx += bw + 2
	for x in [6, 160, 312]:
		rect(x - 2, 6, 4, 112, C("#4a3826"))
	rect(0, 118, 320, 62, C("#2a241d"))
	dither_rect(0, 118, 320, 62, C("#2a241d"), C("#332b22"), 0.3)
	# filing cabinet
	rect(14, 96, 34, 64, C("#5b6670"))
	for d in range(4):
		frame(16, 98 + d * 15, 30, 14, C("#46505a"))
		rect(27, 103 + d * 15, 8, 2, C("#aab4bd"))
	# table with stacks
	rect(96, 122, 150, 6, C("#5b4128"))
	rect(96, 122, 150, 1, C("#7f5d3c"))
	rect(102, 128, 5, 40, C("#4a3420"))
	rect(234, 128, 5, 40, C("#4a3420"))
	for i in range(4):
		var sx := 112 + i * 32
		for k in range(3 + i % 2):
			rect(sx + (k % 2), 118 - k * 3, 22, 3, C("#f4ecd8") if k % 2 == 0 else C("#e2d6ba"))
	# lamp and light cone
	line(170, 0, 170, 14, C("#1a1510"))
	poly(PackedVector2Array([Vector2(160, 22), Vector2(180, 22), Vector2(175, 14), Vector2(165, 14)]), C("#3b4a3a"))
	rect(162, 22, 16, 1, C("#fff0b8"))
	light_overlay(PackedVector2Array([Vector2(162, 23), Vector2(178, 23), Vector2(260, 140), Vector2(80, 140)]), C("#ffe7a8"), 0.28)
	_save_bg("BG12")


func _bg_title() -> void:
	_new_bg()
	vgrad(0, 0, 320, 180, ["#0b1022", "#121a38", "#1d2850", "#2a3666"])
	for i in range(70):
		px(rng.randi_range(0, 319), rng.randi_range(0, 90), C("#d8e2ff") if i % 3 else C("#f2c14e"))
	var bx := 0
	while bx < 320:
		var bw := rng.randi_range(14, 30)
		var bh := rng.randi_range(40, 110)
		rect(bx, 180 - bh, bw, bh, C("#0d1226"))
		rect(bx, 180 - bh, 1, bh, C("#1a2244"))
		for wy in range(180 - bh + 4, 178, 5):
			for wx in range(bx + 3, bx + bw - 2, 4):
				if rng.randf() < 0.3:
					rect(wx, wy, 2, 2, C("#f2d27a"))
		bx += bw + 2
	_save_bg("TITLE")
