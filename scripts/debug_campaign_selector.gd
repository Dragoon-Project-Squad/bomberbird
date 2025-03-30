extends Control

const LEVEL_GRAPH_SCENE := preload("res://scenes/level_graph/level_graph.tscn")
const SAVED_GRAPHS_FOLDER: String = "res://resources/level_graph/saved_graphs/"

@onready var selector: OptionButton = get_node("HBoxContainer/CampaignSelector")
@onready var button: Button = get_node("HBoxContainer/GraphButton")

func _ready() -> void:
	_get_file_name_from_dir(SAVED_GRAPHS_FOLDER)

func get_graph() -> String:
	return selector.get_item_text(selector.selected)

func _get_file_name_from_dir(path: String):
	selector.clear()
	var scene_dir = DirAccess.open(path)
	assert(scene_dir, "stage scene dir not found at: " + path)

	scene_dir.list_dir_begin()
	var scene_file: String = scene_dir.get_next()
	while scene_file != "":
		if scene_file.get_extension() == "res":
			selector.add_item(scene_file.left(len(scene_file) - 4))
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
	level_graph_editor.has_saved.connect(_get_file_name_from_dir.bind(SAVED_GRAPHS_FOLDER))

	if ResourceLoader.exists(SAVED_GRAPHS_FOLDER+ "/" + get_graph() + ".res"):
		level_graph_editor.load_graph(ResourceLoader.load(SAVED_GRAPHS_FOLDER + "/" + get_graph() + ".res"))
		level_graph_editor.has_loaded.emit()
	else:
		print("No savedata loaded")
	
