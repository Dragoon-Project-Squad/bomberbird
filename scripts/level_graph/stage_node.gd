class_name StageNode extends GraphNode

const STAGE_SCENE_DIR: String = "res://scenes/stages/"
const ENEMY_SCENE_DIR: String = "res://scenes/enemies/"

@onready var scene_options: OptionButton = %SceneOptions
@onready var exit_boiler: HBoxContainer = %ExitBoiler
@onready var pickups_tab: GridContainer = %PickupWeights
@onready var stage_tab: StageDataUI = %Stage
@onready var pickup_boiler: SpinBox = %PickupBoiler
@onready var stage_name: LineEdit = %StageName

var stages_subfolders: Dictionary = {}
var enemy_subfolders: Dictionary = {}
var curr_tab: int = 0

var curr_enemy_options: Array[String] = []
var selected_scene_file: String = ""
var selected_scene_path: String = ""

var pickup_resource: PickupTable = PickupTable.new()
var enemy_resource: EnemyTable = EnemyTable.new()
var exit_resource: ExitTable = ExitTable.new()
var spawn_point_arr: Array[Vector2i] = []

var exit_indx: int = 0
var enemy_indx: int = 0
var spawn_point_indx: int = 0
var exit_in_port_color: Color = Color.SILVER

# ----------------------------- init functions

func _ready():
	get_file_name_from_dir(STAGE_SCENE_DIR, [], stages_subfolders)
	_set_scene_options(stages_subfolders)

	get_file_name_from_dir(ENEMY_SCENE_DIR, [], enemy_subfolders)

	set_slot(
		0,
		true,
		0,
		exit_in_port_color,
		false,
		0,
		Color.GOLD,
	)

	$TabContainer.current_tab = curr_tab

## sets all values for a node given a StageNodeData
func load_stage_node(stage_node_data: StageNodeData):
	self.name = stage_node_data.stage_node_name
	self.title = stage_node_data.stage_node_title
	self.stage_name.text = stage_node_data.stage_node_title
	self.position_offset = stage_node_data.stage_node_pos
	self.curr_enemy_options = stage_node_data.curr_enemy_options
	self.selected_scene_file = stage_node_data.selected_scene_file
	self.selected_scene_path = stage_node_data.selected_scene_path
	_set_option_button_select(scene_options, selected_scene_file)
	self.spawn_point_arr = stage_node_data.spawn_point_arr
	self.pickup_resource = stage_node_data.pickup_resource
	self.enemy_resource = stage_node_data.enemy_resource
	self.exit_resource = stage_node_data.exit_resource
	pickup_resource.update()
	_setup_pickup_tab()
	_setup_exit_from_load()

## given an OptionButton and a String searches for that String in the items of the OptionButton and then sets the selection to that Option
func _set_option_button_select(option_button: OptionButton, item: String) -> int:
	var idx: int
	for i in range(option_button.item_count):
		if item != option_button.get_item_text(i): continue
		idx = i
		option_button.select(idx)
		break
	return idx

## Given the subfolders Dictonary for scene adds the option to the SceneOption
func _set_scene_options(stages_subfolders_arg: Dictionary):
	for key in stages_subfolders_arg.keys():
		scene_options.add_item(key)
	scene_options.selected = -1

## resets the enemy option (deselects them all and redoes the option list)
func _reset_enemy_options(enemy_subfolders_arg: Dictionary, subfolders: Array[String]):
	curr_enemy_options.clear()
	for key in enemy_subfolders_arg.keys():
		if enemy_subfolders_arg[key] != subfolders: continue
		curr_enemy_options.append(key)
	print(curr_enemy_options)
	
	_set_enemy_options()
		
## same as _set_scene_option but for enemies
func _set_enemy_options():
	stage_tab.enemy_options = curr_enemy_options

## given a scene and its subfolders returns the path to that scene (if only_dir == true returns the path to the Directory containing the scene rather then the scene)
static func get_path_to_scene(scene: String, subfolders: Array[String], only_dir: bool = false):
	var ret: String = STAGE_SCENE_DIR.left(len(STAGE_SCENE_DIR) - 1)
	for s in subfolders:
		ret += "/" + s
	return ret + ("/" + scene if !only_dir else "")

static func get_file_name_from_dir(path: String, subfolders: Array[String], subfolder_dict: Dictionary):
	var scene_dir = DirAccess.open(path)
	assert(scene_dir, "stage scene dir not found at: " + path)

	scene_dir.list_dir_begin()
	var scene_file: String = scene_dir.get_next()
	while scene_file != "":
		if scene_file.get_extension() == "tscn":
			if(subfolder_dict.has(scene_file)):
				push_error("Same filename for differente stages found: " + get_path_to_scene(scene_file, subfolders) + " and " + get_path_to_scene(scene_file, subfolder_dict[scene_file]) + "expect fauty behavior")
			subfolder_dict[scene_file] = subfolders.duplicate()
		elif scene_file.get_extension() == "":
			subfolders.append(scene_file)
			get_file_name_from_dir(path + scene_file, subfolders, subfolder_dict)
			subfolders.pop_back()

		scene_file = scene_dir.get_next()

## setup the pickup tab hence loops throught all pickup enums in global and creates a UI element for it
func _setup_pickup_tab():
	var last_pickup: SpinBox = pickup_boiler
	for pickup in range(globals.pickups.NONE):
		match pickup:
			globals.pickups.GENERIC_COUNT: continue
			globals.pickups.GENERIC_BOOL: continue
			globals.pickups.GENERIC_EXCLUSIVE: continue
			globals.pickups.GENERIC_BOMB: continue
		
		var pickup_element: SpinBox = pickup_boiler.duplicate()
		pickup_element.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_FILL) # This no worky probably a bug in godot itself
		pickup_element.name = globals.pickup_name_str[pickup]
		pickup_element.prefix = globals.pickup_name_str[pickup] + ": "
		if pickup_resource.pickup_weights.has(pickup):
			pickup_element.value = float(pickup_resource.pickup_weights[pickup])
		pickup_element.show()
		
		last_pickup.add_sibling(pickup_element)
		last_pickup = pickup_element
		
		var changed_function_value: Callable = _on_pickup_weight_changed.bind(pickup)
		last_pickup.value_changed.connect(changed_function_value)

## only called when node is loaded from a StageNodeData setup all the exit entries
func _setup_exit_from_load():
	for exit_entry in exit_resource.exits:
		var exit: HBoxContainer = exit_boiler.duplicate()
		exit_indx += 1
		
		var offset: int = 0
		for child in get_children():
			if child == exit_boiler: break
			offset += 1
	
		add_child(exit)
		move_child(exit, offset + exit_indx)
		
		exit.name = "Exit" + str(exit_indx)
		exit.get_node("ExitNumber").text = str(exit_indx) + "."
		exit.get_node("ExitColor").color = exit_entry.color
		exit.get_node("Position/x").value = exit_entry.coords.x
		exit.get_node("Position/y").value = exit_entry.coords.y
		exit.show()
			

		set_slot(
			exit_indx + 1,
			false,
			0,
			exit_in_port_color,
			true,
			0,
			exit.get_node("ExitColor").color,
		)
		
		var remove_function: Callable = _on_remove_exit_button_pressed.bind(exit)
		var changed_function_x: Callable = _on_exit_position_changed.bind(exit, true)
		var changed_function_y: Callable = _on_exit_position_changed.bind(exit, false)
		var changed_function_color: Callable = _on_exit_color_changed.bind(exit)
		exit.get_node("RemoveExitButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
		exit.get_node("Position/x").value_changed.connect(changed_function_x)
		exit.get_node("Position/y").value_changed.connect(changed_function_y)
		exit.get_node("ExitColor").color_changed.connect(changed_function_color)

# ---------------------- signal functions

## stores the new text of the scene_file and calls _reset_enemy_options)
func _on_scene_options_item_selected(index: int) -> void:
	if index < 0:
		return
	selected_scene_file = scene_options.get_item_text(index)
	selected_scene_path = get_path_to_scene(selected_scene_file, stages_subfolders[selected_scene_file], true)
	_reset_enemy_options(enemy_subfolders, stages_subfolders[selected_scene_file])

## prevents the enemy tab from being selected if no scene is selected
func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 1 && selected_scene_file == "":
		$TabContainer.current_tab = curr_tab
		scene_options.disabled = true
		await get_tree().create_timer(0.2).timeout
		scene_options.disabled = false
	else: curr_tab = $TabContainer.current_tab

## Create a new entry for an exit
func _on_add_exit_button_pressed() -> void:
	var exit: HBoxContainer = exit_boiler.duplicate()
	exit_indx += 1
	
	var offset: int = 0
	for child in get_children():
		if child == exit_boiler: break
		offset += 1

	add_child(exit)
	move_child(exit, offset + exit_indx)
	
	exit.name = "Exit" + str(exit_indx)
	exit.get_node("ExitNumber").text = str(exit_indx) + "."
	exit.show()
	
	exit_resource.append(Vector2i.ZERO, exit.get_node("ExitColor").color)
	
	set_slot(
		exit_indx + 1,
		false,
		0,
		exit_in_port_color,
		true,
		0,
		exit.get_node("ExitColor").color,
	)
	
	var remove_function: Callable = _on_remove_exit_button_pressed.bind(exit)
	var changed_function_x: Callable = _on_exit_position_changed.bind(exit, true)
	var changed_function_y: Callable = _on_exit_position_changed.bind(exit, false)
	var changed_function_color: Callable = _on_exit_color_changed.bind(exit)
	exit.get_node("RemoveExitButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
	exit.get_node("Position/x").value_changed.connect(changed_function_x)
	exit.get_node("Position/y").value_changed.connect(changed_function_y)
	exit.get_node("ExitColor").color_changed.connect(changed_function_color)

## deletes an exit and adjusts all indicies of exits after itself
func _on_remove_exit_button_pressed(exit: HBoxContainer):
	var exit_num: int = exit.name.to_int()
	assert(exit_num <= exit_indx, "encountered invalid index for exit")
	var exit_indx_new: int = exit_num

	print(exit_num, ", ", exit_indx)
	if exit_num < exit_indx:
		# Readjust the slots to behave correctly
		get_parent().remove_ports(self.name, exit_num - 1)
		get_parent().reindex_ports(self.name, exit_num - 1, -1)
	else: 
		get_parent().remove_ports(self.name, exit_num - 1)
	clear_slot(exit_indx + 1)

	# We need to change the name of the exit that we wish to remove in order to change its sibling's name.
	exit.name = "REMOVING_" + exit.name

	var offset: int = 0
	for child in get_children():
		offset += 1
		if child == exit_boiler: break

	for i in range(offset + exit_num, offset + exit_indx):
		var child = get_child(i)
		assert(child.has_node("ExitNumber"), "bad index: " + str(i))
		child.name = "Exit" + str(exit_indx_new)
		child.get_node("ExitNumber").text = str(exit_indx_new) + "."
		_on_exit_color_changed(child.get_node("ExitColor").color, child)
		exit_indx_new += 1
	
	exit_resource.remove_at(exit_num - 1)
	exit.queue_free()
	exit_indx -= 1
	
## updates the exit position in the exit_resource
func _on_exit_position_changed(val: float, exit: HBoxContainer, is_x: bool,):
	var exit_num: int = exit.name.to_int() - 1
	if is_x:
		exit_resource.set_x(exit_num, int(val))
	else:
		exit_resource.set_y(exit_num, int(val))
	
## updates the exit color in the exit_resource
func _on_exit_color_changed(color: Color, exit: HBoxContainer):
	var exit_num: int = exit.name.to_int()
	set_slot(
		exit_num + 1,
		false,
		0,
		exit_in_port_color,
		true,
		0,
		exit.get_node("ExitColor").color,
	)
	exit_resource.set_color(exit_num - 1, color)

## updates the pickup_weight in the Pickup_resource
func _on_pickup_weight_changed(weight: float, pickup: int):
	if(pickup_resource.pickup_weights.has(pickup)):
		pickup_resource.pickup_weights[pickup] = weight
		pickup_resource.reverse_update()
	else:
		push_error("Pickup " + globals.pickup_name_str[pickup] + " not yet implemented")

## renames the node title to the text int he stage_name LineEdit iff there is no stage with that name already
func _on_stage_name_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: return
	var new_text: String = stage_name.text
	for node in get_parent().get_children():
		if node is StageNode && node != self && node.title == new_text:
			#hacky hack hack
			stage_name.editable = false
			await get_tree().create_timer(0.2).timeout
			stage_name.editable = true
			stage_name.text = ""
			return
	self.title = new_text
