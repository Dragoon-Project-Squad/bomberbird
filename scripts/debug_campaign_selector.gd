extends Control

const DEFAULT_GRAPH_NAME: String = "test_campaign_1"
const LEVEL_GRAPH_SCENE := preload("res://scenes/level_graph/level_graph.tscn")

@onready var selector: OptionButton = get_node("HBoxContainer/CampaignSelector")
@onready var button: Button = get_node("HBoxContainer/GraphButton")

func _ready() -> void:
	_update_and_set(DEFAULT_GRAPH_NAME)

func _update_and_set(item_name: String):
	_get_file_name_from_dir(LevelGraph.SAVE_PATH)
	for idx in range(selector.item_count):
		if selector.get_item_text(idx) == DEFAULT_GRAPH_NAME:
			selector.select(idx)
			return

func get_graph() -> String:
	return selector.get_item_text(selector.selected)

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
	var level_graph_editor: GraphEdit = LEVEL_GRAPH_SCENE.instantiate()
	if get_parent():
		if get_parent().has_node("LevelGraph"): return
		get_parent().add_child(level_graph_editor)
	else:
		if has_node("LevelGraph"): return
		add_child(level_graph_editor)
	level_graph_editor.get_menu_hbox().get_node("LoadSaveLEdit").text = get_graph()
	level_graph_editor.file_name = get_graph()
	level_graph_editor.has_saved.connect(_update_and_set.bind(level_graph_editor.file_name))

	var graph_json_data: Dictionary = LevelGraph.load_json_file(get_graph())
	level_graph_editor.load_graph(graph_json_data)
	level_graph_editor.has_loaded.emit()
