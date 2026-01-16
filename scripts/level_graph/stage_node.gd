class_name StageNode extends GraphNode
## Represents a single Node in a Level Graph

const STAGE_SCENE_DIR: String = "res://scenes/stages/"

const STAGE_DIR: Dictionary = {
	"Saloon": "desert_stages/desert_runtime.tscn",
	"Beach": "beach_stages/beach_runtime.tscn",
	"Dungeon": "dungeon_stages/dungeon_runtime.tscn",
	"Lab": "lab_stages/lab_runtime.tscn",
	"Secret": "secret_stages/secret_runtime.tscn",
	"Vintage": "vintage_stages/vintage_runtime.tscn",
	}

signal has_changed

@onready var scene_options: OptionButton = %SceneOptions
@onready var exit_boiler: HBoxContainer = %ExitBoiler
@onready var pickups_tab: GridContainer = %"Pickup Weights"
@onready var weights_vs_amount: CheckButton = %WeightsVsAmount
@onready var base_pickup_spawn_rate: SpinBox = %BasePickupSpawnChance
@onready var stage_tab: StageDataUI = %Stage
@onready var stage_name: LineEdit = %StageName

var selected_scene: String

var curr_tab: int = 0

var pickup_resource: PickupTable = PickupTable.new()
var exit_resource: ExitTable = ExitTable.new()

var exit_indx: int = 0
var enemy_indx: int = 0
var spawn_point_indx: int = 0
var exit_in_port_color: Color = Color.SILVER

# ----------------------------- init functions

func _ready():
	_set_scene_options(STAGE_DIR)
	if get_parent() != null:
		exit_boiler.get_node("Position/x").max_value = stage_tab.map_size.x - 1
		exit_boiler.get_node("Position/y").max_value = stage_tab.map_size.y - 1

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
	stage_tab.has_changed.connect(func (): self.has_changed.emit())

## sets all values for a node given a StageNodeData
## [param stage_node_data] StageNodeData data to load from
func load_stage_node(stage_node_data: Dictionary):
	self.name = stage_node_data.stage_node_name
	self.title = stage_node_data.stage_node_title
	self.stage_name.text = stage_node_data.stage_node_title
	self.position_offset = str_to_var(stage_node_data.stage_node_pos)
	self.selected_scene = stage_node_data.selected_scene
	_set_option_button_select(scene_options, selected_scene)
	self.pickup_resource = PickupTable.new()
	self.pickup_resource.from_json(stage_node_data.pickup_table)
	self.exit_resource = ExitTable.new()
	self.exit_resource.from_json(stage_node_data.exit_table)
	var enemy_resource: EnemyTable = EnemyTable.new()
	enemy_resource.from_json(stage_node_data.enemy_table)
	var spawnpoint_resource: SpawnpointTable = SpawnpointTable.new()
	spawnpoint_resource.from_json(stage_node_data.spawnpoint_table)
	var unbreakable_resource: UnbreakableTable = UnbreakableTable.new()
	unbreakable_resource.from_json(stage_node_data.unbreakable_table)
	var breakable_resource: BreakableTable = BreakableTable.new()
	breakable_resource.from_json(stage_node_data.breakable_table)
	stage_tab.load_from_resources(enemy_resource, spawnpoint_resource, unbreakable_resource, breakable_resource)
	_setup_pickup_tab()
	_setup_exit_from_load()

func save_node(index: int) -> Dictionary:
	var stage_node_data: Dictionary = {}
	stage_node_data["selected_scene"] = selected_scene
	stage_node_data["pickup_table"] = pickup_resource.to_json()
	var enemy_resource: EnemyTable = EnemyTable.new()
	var spawnpoint_resource: SpawnpointTable = SpawnpointTable.new()
	var unbreakable_resource: UnbreakableTable = UnbreakableTable.new()
	var breakable_resource: BreakableTable = BreakableTable.new()
	stage_tab.write_to_resources(enemy_resource, spawnpoint_resource, unbreakable_resource, breakable_resource)
	stage_node_data["enemy_table"] = enemy_resource.to_json()
	stage_node_data["spawnpoint_table"] = spawnpoint_resource.to_json()
	stage_node_data["unbreakable_table"] = unbreakable_resource.to_json()
	stage_node_data["breakable_table"] = breakable_resource.to_json()

	stage_node_data["exit_table"] = exit_resource.to_json(stage_tab.map_size)
	stage_node_data["stage_node_name"] = name
	stage_node_data["stage_node_title"] = title
	stage_node_data["stage_node_pos"] = var_to_str(position_offset)
	stage_node_data["index"] = index

	#fill the children array with -1 we later only overwrite an index in this array if it leads to a next stage
	stage_node_data["children"] = []
	stage_node_data["children"].resize(exit_resource.size())
	stage_node_data["children"].fill(-1)

	return stage_node_data

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
func _set_scene_options(stage_options: Dictionary):
	for key in stage_options.keys():
		scene_options.add_item(key)
	scene_options.selected = -1
	has_changed.emit()

## given a scene and its subfolders returns the path to that scene (if only_dir == true returns the path to the Directory containing the scene rather then the scene)
static func get_path_to_scene(scene: String, base_dir: String, file_dir: Dictionary, only_dir: bool = false):
	var ret: String = base_dir.left(len(base_dir) - 1)
	return ret + (("/" + file_dir[scene]) if !only_dir else "")

## setup the pickup tab hence loops throught all pickup enums in global and creates a UI element for it
func _setup_pickup_tab():
	var child_idx: int = 0
	var count: int = 0
	for pickup in range(globals.pickups.NONE):
		match pickup:
			globals.pickups.GENERIC_COUNT: continue
			globals.pickups.GENERIC_BOOL: continue
			globals.pickups.GENERIC_EXCLUSIVE: continue
			globals.pickups.GENERIC_BOMB: continue
		
		var pickup_element: SpinBox = pickups_tab.get_child(child_idx)
		assert(pickup_element.prefix == "Boiler:") # crash the freak out if this is not a spinbox thats intended to be overwitten
		#pickup_element.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_FILL) # This no worky probably a bug in godot itself
		pickup_element.name = globals.pickup_name_str[pickup]
		pickup_element.prefix = globals.pickup_name_str[pickup] + ": "
		if pickup_resource.pickup_weights.has(pickup):
			pickup_element.value = float(pickup_resource.pickup_weights[pickup])
		pickup_element.show()
		
		var changed_function_value: Callable = _on_pickup_weight_changed.bind(pickup)
		pickup_element.value_changed.connect(changed_function_value)
		child_idx += 1
		
	if pickup_resource.are_amounts:
		weights_vs_amount.set_pressed_no_signal(true)
		_on_weights_vs_amount_toggled(true)
	base_pickup_spawn_rate.value = pickup_resource.base_pickup_spawn_chance

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
		stage_tab.add_border_color_overwrite(exit_entry.coords, exit_entry.color)
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

## stores the new text of the scene_file
func _on_scene_options_item_selected(index: int) -> void:
	if index < 0:
		return
	selected_scene = scene_options.get_item_text(index)
	has_changed.emit()

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
	
	stage_tab.add_border_color_overwrite(Vector2i.ZERO, exit.get_node("ExitColor").color)
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
	has_changed.emit()

## deletes an exit and adjusts all indicies of exits after itself
func _on_remove_exit_button_pressed(exit: HBoxContainer):
	var exit_num: int = exit.name.to_int()
	assert(exit_num <= exit_indx, "encountered invalid index for exit")
	var exit_indx_new: int = exit_num

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
		#_on_exit_color_changed(child.get_node("ExitColor").color, child)
		exit_indx_new += 1
	
	stage_tab.remove_border_color_overwrite(exit_resource.exits[exit_num - 1].coords)
	exit_resource.remove_at(exit_num - 1)
	exit.queue_free()
	exit_indx -= 1
	has_changed.emit()
	
## updates the exit position in the exit_resource
func _on_exit_position_changed(val: float, exit: HBoxContainer, is_x: bool,):
	var exit_num: int = exit.name.to_int() - 1

	stage_tab.remove_border_color_overwrite(exit_resource.exits[exit_num].coords)
	if is_x:
		exit_resource.set_x(exit_num, int(val))
	else:
		exit_resource.set_y(exit_num, int(val))
	stage_tab.add_border_color_overwrite(exit_resource.exits[exit_num].coords, exit_resource.exits[exit_num].color)
	has_changed.emit()
	
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
	stage_tab.add_border_color_overwrite(exit_resource.exits[exit_num - 1].coords, color)
	has_changed.emit()

## updates the pickup_weight in the Pickup_resource
func _on_pickup_weight_changed(weight: float, pickup: int):
	if(pickup_resource.pickup_weights.has(pickup)):
		pickup_resource.pickup_weights[pickup] = weight
		pickup_resource.reverse_update()
		has_changed.emit()
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
	has_changed.emit()

func _on_weights_vs_amount_toggled(toggled_on: bool) -> void:
	base_pickup_spawn_rate.editable = !toggled_on
	pickup_resource.are_amounts = toggled_on
	if toggled_on:
		weights_vs_amount.text = "amount"
		pickups_tab.name = "Pickup amount"
	else:
		weights_vs_amount.text = "weights"
		pickups_tab.name = "Pickup weight"
	has_changed.emit()

func _on_base_pickup_spawn_chance_changed(value: float):
	pickup_resource.base_pickup_spawn_chance = value
