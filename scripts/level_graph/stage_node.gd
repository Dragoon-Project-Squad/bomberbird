class_name StageNode extends GraphNode

const STAGE_SCENE_DIR = "res://scenes/stages/"

@onready var scene_options: OptionButton = %SceneOptions
@onready var exit_boiler: HBoxContainer = %ExitBoiler

var selected_scene_path: String
var pickup_resource: PickupTable
#var enemy_resource: ??? TODO make enemies a thing
var exit_indx: int = 0
var exit_array: Array[Vector2i] = []

func _ready():
	_get_scenes_from_dir()
	set_slot(
		exit_indx,
		true,
		0,
		Color.SILVER,
		false,
		0,
		Color.GOLD,
	)


func _get_scenes_from_dir():
	var stages_dir = DirAccess.open(STAGE_SCENE_DIR)
	assert(stages_dir, "stage scene dir not found at: " + STAGE_SCENE_DIR)

	stages_dir.list_dir_begin()
	var scene_file: String = stages_dir.get_next()
	while scene_file != "":
		if scene_file.get_extension() == "tscn":
			scene_options.add_item(scene_file)
		scene_file = stages_dir.get_next()


func _on_scene_options_pressed() -> void:
	selected_scene_path = scene_options.get_item_text(scene_options.selected)

## Create a new entry for an exit
func _on_add_exit_button_pressed() -> void:
	var exit: HBoxContainer = exit_boiler.duplicate()
	exit_indx += 1
	
	exit.name = "Exit" + str(exit_indx)
	exit.get_node("ExitNumber").text = str(exit_indx) + "."
	exit.show()

	exit_array.append(Vector2i.ZERO)
	
	add_child(exit)
	move_child(exit, 1 + exit_indx)
	
	set_slot(
		exit_indx,
		false,
		0,
		Color.SILVER,
		true,
		0,
		Color.GOLD,
	)
	
	var remove_function: Callable = _on_remove_exit_button_pressed.bind(exit)
	var changed_function_x: Callable = _on_exit_position_changed.bind(exit, true)
	var changed_function_y: Callable = _on_exit_position_changed.bind(exit, false)
	exit.get_node("RemoveExitButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
	exit.get_node("Position/x").value_changed.connect(changed_function_x)
	exit.get_node("Position/y").value_changed.connect(changed_function_y)

## deletes an exit and adjusts all indicies of exits after itself
func _on_remove_exit_button_pressed(exit: HBoxContainer):
	var exit_num: int = exit.name.to_int()
	assert(exit_num <= exit_indx, "encountered invalid index for exit")
	var exit_indx_new: int = exit_num

	get_parent().remove_ports(self.name, exit_num - 1)

	get_parent().reindex_ports(self.name, exit_num - 1, -1)
	clear_slot(exit_indx)

	# We need to change the name of the exit that we wish to remove in order to change its sibling's name.
	exit.name = "REMOVING_" + exit.name
	for i in range(2 + exit_num, 2 + exit_indx):
		var child = get_child(i)
		assert(child.has_node("ExitNumber"), "bad index: " + str(i))
		child.name = "Exit" + str(exit_indx_new)
		child.get_node("ExitNumber").text = str(exit_indx_new) + "."
		exit_indx_new += 1
	
	exit_array.remove_at(exit_num)
	exit.queue_free()

	exit_indx -= 1
	
func _on_exit_position_changed(val: float, exit: HBoxContainer, is_x: bool,):
	var exit_num: int = exit.name.to_int() - 1
	if is_x:
		exit_array[exit_num].x = int(val)
	else:
		exit_array[exit_num].y = int(val)
	print(exit_array)
	
