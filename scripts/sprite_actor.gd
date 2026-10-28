extends Control
## Plays a character's pixel-art sprite sheet using its animation.json (GDD Appendix B):
## per-state frames, durations at 22 FPS, loop / one-shot, reduced-motion frame and fallback.

signal finished(state: String)

const ART_ROOT := "res://art/characters/"
const DIRS := {
	"VERA_JUSTICE": "principals/vera_justice", "AUDREY_ORDER": "principals/audrey_order",
	"SALLY_DARITY": "principals/sally_darity", "LAURENCE_ABBOTT": "principals/laurence_abbott",
	"JULIAN_VANE": "principals/julian_vane", "MONA_POLLY": "principals/mona_polly",
	"SUP_DANIEL": "supporting/sup_daniel", "SUP_NINA": "supporting/sup_nina",
	"SUP_NORTHBRIDGE_REP": "supporting/sup_northbridge_rep",
}
## Principal state requests mapped onto the supporting-cast minimum states.
const SUP_MAP := {"A01": "SUP_NEUTRAL", "A02": "SUP_SPEAKING", "A11": "SUP_NEUTRAL", "A08": "SUP_CONCERNED",
	"A10": "SUP_RELIEVED", "A04": "SUP_CONFIDENT", "A03": "SUP_NEUTRAL", "A06": "SUP_SPEAKING"}

static var _cache: Dictionary = {}

var actor := ""
var pixel_scale := 2
var state := ""
var meta: Dictionary = {}
var sheet: Texture2D
var _frame_i := 0
var _ticks_left := 0.0
var _done := false
var _then := ""
var _locked_until := 0


func setup(actor_id: String, scale_px: int = 2) -> void:
	actor = actor_id
	pixel_scale = scale_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dir: String = ART_ROOT + DIRS.get(actor_id, "")
	if not _cache.has(dir):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(dir + "/animation.json"))
		var tex: Texture2D = load(dir + "/sheet.png") if ResourceLoader.exists(dir + "/sheet.png") else null
		_cache[dir] = [parsed if typeof(parsed) == TYPE_DICTIONARY else {}, tex]
	meta = _cache[dir][0]
	sheet = _cache[dir][1]
	var fs: Array = meta.get("frame_size", [64, 72])
	custom_minimum_size = Vector2(fs[0], fs[1]) * pixel_scale
	size = custom_minimum_size
	pivot_offset = Vector2(size.x * 0.5, size.y)
	play(meta.get("fallback", "A01"))


func has_state(s: String) -> bool:
	return meta.get("states", {}).has(s)


func resolve(s: String) -> String:
	if has_state(s):
		return s
	if SUP_MAP.has(s) and has_state(SUP_MAP[s]):
		return SUP_MAP[s]
	return meta.get("fallback", "A01")


## Play a state. `then` is played once a one-shot state ends. `lock_sec` stops
## idle requests from interrupting this reaction for a moment.
func play(s: String, then: String = "", lock_sec: float = 0.0) -> void:
	var r := resolve(s)
	_then = then
	if lock_sec > 0.0:
		_locked_until = Time.get_ticks_msec() + int(lock_sec * 1000.0)
	if r == state and not _done:
		return
	state = r
	_frame_i = 0
	_done = false
	_ticks_left = _durations()[0] if _durations().size() > 0 else 1
	queue_redraw()


## Idle/background state request: ignored while a locked reaction is showing.
func idle(s: String) -> void:
	if Time.get_ticks_msec() < _locked_until:
		_then = s
		return
	play(s)


func _st() -> Dictionary:
	return meta.get("states", {}).get(state, {})


func _durations() -> Array:
	return _st().get("durations", [1])


func _process(delta: float) -> void:
	if _done or sheet == null:
		return
	if GS.settings.get("reduced_motion", false):
		return
	var fps: float = meta.get("fps", 22)
	_ticks_left -= delta * fps
	var durs := _durations()
	var frames: Array = _st().get("frames", [0])
	while _ticks_left <= 0.0:
		if _frame_i + 1 < frames.size():
			_frame_i += 1
		elif _st().get("loop", true):
			_frame_i = 0
		else:
			_done = true
			finished.emit(state)
			if _then != "":
				var nxt := _then
				_then = ""
				play(nxt)
			queue_redraw()
			return
		_ticks_left += float(durs[_frame_i])
		queue_redraw()


func _draw() -> void:
	if sheet == null:
		return
	var st := _st()
	var frames: Array = st.get("frames", [0])
	var idx: int
	if GS.settings.get("reduced_motion", false):
		idx = int(st.get("reduced_motion_frame", frames[0]))
	else:
		idx = int(frames[clampi(_frame_i, 0, frames.size() - 1)])
	var fs: Array = meta.get("frame_size", [64, 72])
	var cols: int = meta.get("columns", 8)
	var src := Rect2((idx % cols) * fs[0], (idx / cols) * fs[1], fs[0], fs[1])
	draw_texture_rect_region(sheet, Rect2(Vector2.ZERO, Vector2(fs[0], fs[1]) * pixel_scale), src)
