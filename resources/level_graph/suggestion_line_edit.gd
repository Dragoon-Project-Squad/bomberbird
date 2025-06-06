class_name SuggestionLineEdit extends LineEdit

@onready var popup_menu: PopupMenu = PopupMenu.new()

@export var popup_menu_size: int = 10
@export var idx: int = -1

var filtered_list: Array[String] = []
var full_list: Array[String] = []
var focus_pop: bool = false

func _ready() -> void:
	var read_only_stylebox: StyleBoxFlat = StyleBoxFlat.new()
	read_only_stylebox.bg_color = Color(1.0, 0.173, 0.125, 0.51)
	self.add_theme_stylebox_override("read_only", read_only_stylebox)
	add_child(popup_menu)
	tooltip_text = "Press Arrow down to get suggestions"
	placeholder_text = "Press Arrow down when focused"

	_get_file_name_from_dir(LevelGraph.SAVE_PATH, full_list)
	popup_menu.unfocusable = true
	custom_minimum_size.x = 300
	
	popup_menu.popup_hide.connect(
		func(): popup_menu.unfocusable = true
	)

	popup_menu.about_to_popup.connect(
		func(): popup_menu.unfocusable = false,
		CONNECT_DEFERRED,
	)

	popup_menu.index_pressed.connect(_update_edit)

func _get_file_name_from_dir(path: String, list: Array[String]):
	list.clear()
	var camp_dir = DirAccess.open(path)
	assert(camp_dir, "res dir not found at: " + path)

	for camp_file in camp_dir.get_files():
		if camp_file.get_extension() == "json":
			list.append(camp_file.get_basename())

func _gui_input(event: InputEvent) -> void:
	if not popup_menu.visible:
		if event.is_action_pressed("ui_down", true):
			_update_list(text)
		return

	if event.is_action_pressed("ui_up", true):
		idx = wrapi(idx - 1, 0, filtered_list.size())
		popup_menu.set_focused_item(idx)
		accept_event()
	elif event.is_action_pressed("ui_down", true):
		idx = wrapi(idx + 1, 0, filtered_list.size())
		popup_menu.set_focused_item(idx)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		_update_edit(idx)
		focus_pop = false
		popup_menu.hide()
		accept_event()


func _update_edit(sel_indx: int):
	self.text = filtered_list[sel_indx]
	self.text_changed.emit(self.text)
	caret_column = text.length()

func _update_list(in_text: String, silent: bool = false):
	filtered_list = full_list.duplicate()
	filtered_list.sort_custom(func(arg1: String, arg2: String) -> int:
		return arg1.similarity(in_text) > arg2.similarity(in_text)
	)

	filtered_list.resize(min(len(filtered_list), popup_menu_size))
	_update_popup_menu(silent)

func _update_popup_menu(silent):
	popup_menu.clear()
	for item in filtered_list:
		popup_menu.add_item(item)
	if not popup_menu.visible && !silent:
		popup_menu.popup(Rect2(position + Vector2(0, size.y + 2), size))
	idx = 0
	popup_menu.set_focused_item(idx)
	
func _on_graph_edit_saved(_name: String):
	_get_file_name_from_dir(LevelGraph.SAVE_PATH, full_list)
	_update_list(text, true)
