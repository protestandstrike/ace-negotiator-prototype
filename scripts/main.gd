extends Control
## Root: switches between title, intro, game and chapter-end screens.

const UI := preload("res://scripts/ui_kit.gd")
const TitleScreen := preload("res://scripts/title_screen.gd")
const IntroScreen := preload("res://scripts/intro_screen.gd")
const GameScreen := preload("res://scripts/game_screen.gd")
const ChapterEnd := preload("res://scripts/chapter_end.gd")

var _screen: Control
var _autotest := false


func _ready() -> void:
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_autotest = OS.get_cmdline_user_args().has("--autotest")
	if _autotest:
		GS.settings["text_speed"] = 3
		if OS.get_cmdline_user_args().has("--resume"):
			_continue()
		else:
			GS.delete_save()
			_start_new()
	else:
		_show_title()
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--titleshot="):
				await get_tree().create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(a.substr(12))
				get_tree().quit(0)


func _swap(c: Control) -> void:
	if _screen:
		_screen.queue_free()
	_screen = c
	add_child(c)


func _show_title() -> void:
	var t = TitleScreen.new()
	t.new_game.connect(_start_new)
	t.continue_game.connect(_continue)
	_swap(t)


func _start_new() -> void:
	GS.new_game()
	GS.delete_save()
	var intro = IntroScreen.new()
	intro.finished.connect(func(): _start_game(false))
	_swap(intro)


func _continue() -> void:
	if not GS.load_game():
		_start_new()
		return
	if GS.state["flags"].has("CHAPTER_COMPLETE"):
		_show_end()
	else:
		_start_game(true)


func _start_game(resume: bool) -> void:
	var g = GameScreen.new()
	g.chapter_finished.connect(_show_end)
	g.quit_to_title.connect(_show_title)
	_swap(g)
	g.begin(resume)


func _show_end() -> void:
	var e = ChapterEnd.new()
	e.done.connect(_show_title)
	_swap(e)
	if _autotest:
		print("AUTOTEST COMPLETE outcome=%s puzzles=%s evidence=%s witness=%s daniel=%s reasoning=%s" % [
			GS.state["outcome"], GS.state["puzzles"], GS.state["evidence"], GS.state["witness"], GS.state["daniel_instruction"], GS.state["reasoning"]])
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--shots="):
				await get_tree().create_timer(0.3).timeout
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(a.substr(8).path_join("zz_chapter_end.png"))
		get_tree().quit(0)
