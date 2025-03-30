class_name StageNode extends GraphNode

const STAGE_SCENE_DIR: String = "res://scenes/stages/"

@onready var scene_options: OptionButton = %SceneOptions
@onready var exit_boiler: HBoxContainer = %ExitBoiler
@onready var pickups_tab: GridContainer = %"Pickup Weights"
@onready var weights_vs_amount: CheckButton = %WeightsVsAmount
@onready var stage_tab: StageDataUI = %Stage
@onready var pickup_boiler: SpinBox = %PickupBoiler
@onready var stage_name: LineEdit = %StageName

var stages_subfolders: Dictionary = {}
var curr_tab: int = 0

var curr_enemy_options: Array[String] = []
var selected_scene_file: String = ""
var selected_scene_path: String = ""

var pickup_resource: PickupTable = PickupTable.new()
var exit_resource: ExitTable = ExitTable.new()

var exit_indx: int = 0
var enemy_indx: int = 0
var spawn_point_indx: int = 0
var exit_in_port_color: Color = Color.SILVER

# ----------------------------- init functions

func _ready():
	get_file_name_from_dir(STAGE_SCENE_DIR, [], stages_subfolders)
	_set_scene_options(stages_subfolders)


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
## [param stage_node_data] StageNodeData data to load from
func load_stage_node(stage_node_data: StageNodeData):
	self.name = stage_node_data.stage_node_name
	self.title = stage_node_data.stage_node_title
	self.stage_name.text = stage_node_data.stage_node_title
	self.position_offset = stage_node_data.stage_node_pos
	self.curr_enemy_options = stage_node_data.curr_enemy_options
	self.selected_scene_file = stage_node_data.selected_scene_file
	self.selected_scene_path = stage_node_data.selected_scene_path
	_set_option_button_select(scene_options, selected_scene_file)
	self.pickup_resource = stage_node_data.pickup_resource
	self.exit_resource = stage_node_data.exit_resource
	pickup_resource.update()
	stage_tab.load_from_resources(stage_node_data.enemy_resource, stage_node_data.spawnpoint_resource)
	_setup_pickup_tab()
	_setup_exit_from_load()

func save_node(index: int) -> StageNodeData:
	var node_data = StageNodeData.new()
	node_data.curr_enemy_options = curr_enemy_options
	node_data.selected_scene_file = selected_scene_file
	node_data.selected_scene_path = selected_scene_path
	node_data.pickup_resource = pickup_resource.duplicate()
	node_data.enemy_resource = EnemyTable.new()
	node_data.spawnpoint_resource = SpawnpointTable.new()
	stage_tab.write_to_resources(node_data.enemy_resource, node_data.spawnpoint_resource)

	node_data.exit_resource = exit_resource.duplicate()
	node_data.stage_node_name = name
	node_data.stage_node_title = title
	node_data.stage_node_pos = position_offset
	node_data.index = index

	#fill the children array with -1 we later only overwrite an index in this array if it leads to a next stage
	node_data.children.resize(exit_resource.size())
	node_data.children.fill(-1)
	return node_data

## searches for some String in the items of the OptionButton and then sets the selection to that Option
## [param option_button] the OptionButton to modify
## [param item] the string to search for
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

## given a scene and its subfolders returns the path to that scene (if only_dir == true returns the path to the Directory containing the scene rather then the scene)
static func get_path_to_scene(scene: String, subfolders: Array[String], only_dir: bool = false):
	var ret: String = STAGE_SCENE_DIR.left(len(STAGE_SCENE_DIR) - 1)
	for s in subfolders:
		ret += "/" + s
	return ret + ("/" + scene if !only_dir else "")

## recusrive function that given a [param path] to a folder stores all .tscn file and its subfolders into a [param subfolder_dict] dictonary
## [param path] String path to the top most folder
## [param subfolders] a temp Array used inbetween recursive calls (if you call this from a non recursive place this argument should be an empty array
## [param subfolder_dict] The dict to store the results into
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

<<<<<<< HEAD
=======
## only called when node is loaded from a StageNodeData setup all the spawnpoint entries in the tab
func _setup_spawn_point_from_load():
	for spawn_point_entry in spawn_point_arr:
		var spawn_point: HBoxContainer = spawn_point_boiler.duplicate()
		spawn_point_indx += 1
		
		spawn_point_boiler.get_parent().add_child(spawn_point)
		spawn_point_boiler.get_parent().move_child(spawn_point, spawn_point_indx)
		
		spawn_point.name = "SpawnPoint" + str(spawn_point_indx)
		spawn_point.get_node("SpawnPointNumber").text = str(spawn_point_indx) + ". Spawn Point"
		spawn_point.get_node("Position/x").value = spawn_point_entry.x
		spawn_point.get_node("Position/y").value = spawn_point_entry.y

		spawn_point.show()
		
		var remove_function: Callable = _on_remove_spawn_point_button_pressed.bind(spawn_point)
		var changed_function_x: Callable = _on_spawn_point_position_changed.bind(spawn_point, true)
		var changed_function_y: Callable = _on_spawn_point_position_changed.bind(spawn_point, false)
		spawn_point.get_node("RemoveSpawnPointButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
		spawn_point.get_node("Position/x").value_changed.connect(changed_function_x)
		spawn_point.get_node("Position/y").value_changed.connect(changed_function_y)

>>>>>>> a3a3a40 (documenting stage and graph scripts)
# ---------------------- signal functions

## stores the new text of the scene_file
func _on_scene_options_item_selected(index: int) -> void:
	if index < 0:
		return
	selected_scene_file = scene_options.get_item_text(index)
	selected_scene_path = get_path_to_scene(selected_scene_file, stages_subfolders[selected_scene_file], true)

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

<<<<<<< HEAD
=======
## Create a new entry for an Enemy
func _on_add_enemy_button_pressed() -> void:
	var enemy: HBoxContainer = enemy_boiler.duplicate()
	enemy_indx += 1
	
	enemy_boiler.get_parent().add_child(enemy)
	enemy_boiler.get_parent().move_child(enemy, enemy_indx)
	
	enemy.name = "Enemy" + str(enemy_indx)
	enemy.get_node("EnemyNumber").text = str(enemy_indx) + "."
	_set_enemy_options(enemy.get_node("EnemySelect"))
	enemy.show()
	
	enemy_resource.append(Vector2i.ZERO, "", "")
	
	var remove_function: Callable = _on_remove_enemy_button_pressed.bind(enemy)
	var changed_function_x: Callable = _on_enemy_position_changed.bind(enemy, true)
	var changed_function_y: Callable = _on_enemy_position_changed.bind(enemy, false)
	var changed_function_file: Callable = _on_enemy_file_changed.bind(enemy)
	enemy.get_node("RemoveEnemyButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
	enemy.get_node("Position/x").value_changed.connect(changed_function_x)
	enemy.get_node("Position/y").value_changed.connect(changed_function_y)
	enemy.get_node("EnemySelect").item_selected.connect(changed_function_file)

## removes the enemy and reorders everything as needed
func _on_remove_enemy_button_pressed(enemy: HBoxContainer):
	var enemy_num: int = enemy.name.to_int()
	assert(enemy_num <= enemy_indx, "encountered invalid index for enemy")
	var enemy_indx_new: int = enemy_num

	# We need to change the name of the enemy that we wish to remove in order to change its sibling's name.
	enemy.name = "REMOVING_" + enemy.name
	for i in range(1 + enemy_num, 1 + enemy_indx):
		var child = enemy_boiler.get_parent().get_child(i)
		assert(child.has_node("EnemyNumber"), "bad index: " + str(i))
		child.name = "Enemy" + str(enemy_indx_new)
		child.get_node("EnemyNumber").text = str(enemy_indx_new) + "."
		enemy_indx_new += 1
	
	enemy_resource.remove_at(enemy_num)
	enemy.queue_free()

	enemy_indx -= 1

## updates the enemy position in the enemy_resource
func _on_enemy_position_changed(val: float, enemy: HBoxContainer, is_x: bool,):
	var enemy_num: int = enemy.name.to_int() - 1
	if is_x:
		enemy_resource.set_x(enemy_num, int(val))
	else:
		enemy_resource.set_y(enemy_num, int(val))

## updates the enemy file in the enemy_resource
func _on_enemy_file_changed(index: int, enemy: HBoxContainer):
	var enemy_num: int = enemy.name.to_int() - 1
	var file_name: String = enemy.get_node("EnemySelect").get_item_text(index)
	enemy_resource.set_file(enemy_num, file_name, _get_path_to_scene(file_name, enemy_subfolders[file_name], true))

## Create a new entry for an exit
func _on_add_spawn_point_button_pressed() -> void:
	var spawn_point: HBoxContainer = spawn_point_boiler.duplicate()
	spawn_point_indx += 1
	
	spawn_point_boiler.get_parent().add_child(spawn_point)
	spawn_point_boiler.get_parent().move_child(spawn_point, spawn_point_indx)
	
	spawn_point.name = "SpawnPoint" + str(spawn_point_indx)
	spawn_point.get_node("SpawnPointNumber").text = str(spawn_point_indx) + ". Spawn Point"
	spawn_point.show()
	
	spawn_point_arr.append(Vector2i.ZERO)
	print(spawn_point_arr)
	
	var remove_function: Callable = _on_remove_spawn_point_button_pressed.bind(spawn_point)
	var changed_function_x: Callable = _on_spawn_point_position_changed.bind(spawn_point, true)
	var changed_function_y: Callable = _on_spawn_point_position_changed.bind(spawn_point, false)
	spawn_point.get_node("RemoveSpawnPointButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
	spawn_point.get_node("Position/x").value_changed.connect(changed_function_x)
	spawn_point.get_node("Position/y").value_changed.connect(changed_function_y)

## removes a spawnpoint and adjust accordingly
func _on_remove_spawn_point_button_pressed(spawn_point: HBoxContainer):
	var spawn_point_num: int = spawn_point.name.to_int()
	assert(spawn_point_num <= spawn_point_indx, "encountered invalid index for spawn_point")
	var spawn_point_indx_new: int = spawn_point_num 

	# We need to change the name of the spawn point that we wish to remove in order to change its sibling's name.
	spawn_point.name = "REMOVING_" + spawn_point.name
	for i in range(1 + spawn_point_num, 1 + spawn_point_indx):
		var child = spawn_point.get_parent().get_child(i)
		assert(child.has_node("SpawnPointNumber"), "bad index: " + str(i))
		child.name = "Enemy" + str(spawn_point_indx_new)
		child.get_node("SpawnPointNumber").text = str(spawn_point_indx_new) + ". Spawn Pont"
		spawn_point_indx_new += 1
	
	spawn_point_arr.remove_at(spawn_point_num - 1)
	spawn_point.queue_free()

	spawn_point_indx -= 1

## Changes the spawn point resource
func _on_spawn_point_position_changed(value: float, spawn_point: HBoxContainer, is_x: bool):
	var spawn_point_num: int = spawn_point.name.to_int() - 1
	if is_x:
		spawn_point_arr[spawn_point_num].x = int(value)
	else:
		spawn_point_arr[spawn_point_num].y = int(value)
	print(spawn_point_arr)

>>>>>>> a3a3a40 (documenting stage and graph scripts)
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


func _on_weights_vs_amount_toggled(toggled_on: bool) -> void:
	pickup_resource.are_amounts = toggled_on
	if toggled_on:
		weights_vs_amount.text = "amount"
		pickups_tab.name = "Pickup amount"
	else:
		weights_vs_amount.text = "weights"
		pickups_tab.name = "Pickup weight"
