extends Control

const DEFAULT_CAMPAIGN_GRAPH_NAME: String = "campaign_v1"
const DEFAULT_BOSS_RUSH_GRAPH_NAME: String = "BossRush"
const DEFAULT_BOSS_RUSH_SECRET_GRAPH_NAME: String = "BossRush"
const LEVEL_GRAPH_SCENE := preload("res://scenes/level_graph/level_graph.tscn")

@onready var selector: OptionButton = get_node("HBoxContainer/CampaignSelector")
@onready var button: Button = get_node("HBoxContainer/GraphButton")
@onready var loading_label: Label = $loading

func _ready() -> void:
	var camp_dir = DirAccess.open(LevelGraph.PERMANENT_SAVE_PATH)
	assert(camp_dir, "campaign dir not found at: " + LevelGraph.PERMANENT_SAVE_PATH)
	for perm_camp_file in camp_dir.get_files():
		if perm_camp_file.get_extension() != "json":
			continue
		if !FileAccess.file_exists(LevelGraph.SAVE_PATH + "/" + perm_camp_file):
			DirAccess.make_dir_recursive_absolute(LevelGraph.SAVE_PATH)
			var res_file := FileAccess.open(LevelGraph.PERMANENT_SAVE_PATH + "/" + perm_camp_file, FileAccess.READ)
			assert(res_file)
			var user_file := FileAccess.open(LevelGraph.SAVE_PATH + "/" + perm_camp_file, FileAccess.WRITE)
			assert(user_file)

			var json_str = res_file.get_as_text()
			user_file.store_string(json_str)

			user_file.close()
			res_file.close()
		else:
			var res_file := FileAccess.open(LevelGraph.PERMANENT_SAVE_PATH + "/" + perm_camp_file, FileAccess.READ)
			assert(res_file)
			var json_data := LevelGraph.load_json_file(perm_camp_file.left(len(perm_camp_file) - 5), FileAccess.READ)
			if !json_data.has("version") || json_data.version != LevelGraph.VERSION:
				var user_file_old = FileAccess.open(LevelGraph.SAVE_PATH + "/" + perm_camp_file.left(len(perm_camp_file) - 5) + "_old" + ".json", FileAccess.WRITE)
				assert(user_file_old)
				user_file_old.store_line(JSON.stringify(json_data))
				user_file_old.close()
				var user_file = FileAccess.open(LevelGraph.SAVE_PATH + "/" + perm_camp_file, FileAccess.WRITE)
				assert(user_file)
				var json_str_new = res_file.get_as_text()
				user_file.store_string(json_str_new)
				user_file.close()

			res_file.close()

	_update_and_set(DEFAULT_CAMPAIGN_GRAPH_NAME)

	if OS.is_debug_build(): self.show()
	else: self.hide()

func enter():
	if globals.is_campaign_mode():
		_update_and_set(DEFAULT_CAMPAIGN_GRAPH_NAME)
	elif globals.is_boss_rush_mode():
		if globals.secrets_enabled:
			_update_and_set(DEFAULT_BOSS_RUSH_SECRET_GRAPH_NAME)
		else:
			_update_and_set(DEFAULT_BOSS_RUSH_GRAPH_NAME)
	else:
		push_error("current_gamemode not correcly set")
		_update_and_set(DEFAULT_CAMPAIGN_GRAPH_NAME)


func _update_and_set(item_name: String = DEFAULT_CAMPAIGN_GRAPH_NAME):
	_get_file_name_from_dir(LevelGraph.SAVE_PATH)
	gamestate.current_graph = item_name
	for idx in range(selector.item_count):
		if selector.get_item_text(idx) == item_name:
			selector.select(idx)
			return

func _get_file_name_from_dir(path: String):
	selector.clear()
	var scene_dir = DirAccess.open(path)
	assert(scene_dir, "stage scene dir not found at: " + path)

	scene_dir.list_dir_begin()
	var scene_file: String = scene_dir.get_next()
	while scene_file != "":
		if scene_file.get_extension() == "json":
			selector.add_item(scene_file.left(len(scene_file) - 5))
		scene_file = scene_dir.get_next()

func _on_graph_button_pressed():
	loading_label.show()
	await get_tree().create_timer(0.05).timeout

	var level_graph_editor: GraphEdit = LEVEL_GRAPH_SCENE.instantiate()
	if get_parent():
		if get_parent().has_node("LevelGraph"): return
		get_parent().add_child(level_graph_editor)
	else:
		if has_node("LevelGraph"): return
		add_child(level_graph_editor)
	level_graph_editor.get_menu_hbox().get_node("LoadSaveLEdit").text = gamestate.current_graph
	level_graph_editor.file_name = gamestate.current_graph
	level_graph_editor.has_saved.connect(_update_and_set)

	var graph_json_data: Dictionary = LevelGraph.load_json_file(gamestate.current_graph)
	level_graph_editor.load_graph(graph_json_data)
	loading_label.hide()


func _on_campaign_selector_item_selected(idx: int):
	gamestate.current_graph = selector.get_item_text(idx)

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		self.visible = !self.visible
