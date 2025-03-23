class_name StageNode extends GraphNode

const STAGE_SCENE_DIR: String = "res://scenes/sp_stages/"
const ENEMY_SCENE_DIR: String = "res://scenes/enemies/"

@onready var scene_options: OptionButton = %SceneOptions
@onready var exit_boiler: HBoxContainer = %ExitBoiler
@onready var enemy_boiler: HBoxContainer = %EnemyBoiler
@onready var pickups_tab: GridContainer = %Pickups
@onready var pickup_boiler: SpinBox = pickups_tab.get_node("PickupBoiler")

var stages_subfolders: Dictionary = {}
var enemy_subfolders: Dictionary = {}

var curr_enemy_options: Array[String] = []
var selected_scene_file: String = ""

var pickup_resource: PickupTable = PickupTable.new()
var enemy_resource: EnemyTable = EnemyTable.new()
var exit_resource: ExitTable = ExitTable.new()

var exit_indx: int = 0
var exit_in_port_color: Color = Color.SILVER

var enemy_indx: int = 0
# ----------------------------- init functions

func _ready():
	_get_file_name_from_dir(STAGE_SCENE_DIR, [], stages_subfolders)
	_set_scene_options(stages_subfolders)

	_get_file_name_from_dir(ENEMY_SCENE_DIR, [], enemy_subfolders)

	set_slot(
		0,
		true,
		0,
		exit_in_port_color,
		false,
		0,
		Color.GOLD,
	)
	$TabContainer.current_tab = 1
	_setup_pickup_tab()

func _set_scene_options(stages_subfolders_arg: Dictionary):
	for key in stages_subfolders_arg.keys():
		scene_options.add_item(key)
	scene_options.selected = -1

func _reset_enemy_options(enemy_subfolders_arg: Dictionary, subfolders: Array[String]):
	curr_enemy_options = []
	for key in enemy_subfolders_arg.keys():
		if enemy_subfolders_arg[key] != subfolders: continue
		curr_enemy_options.append(key)
	
	for i in range(1, enemy_indx + 1):	
		var enemy_option: OptionButton = enemy_boiler.get_parent().get_child(i).get_node("EnemySelect")
		_set_enemy_options(enemy_option)
		
func _set_enemy_options(enemy_option: OptionButton):
	enemy_option.clear()
	for o in curr_enemy_options:
		enemy_option.add_item(o)
	enemy_option.selected = -1


func _get_path_to_scene(scene: String, subfolders: Array[String], only_dir: bool = false):
	var ret: String = STAGE_SCENE_DIR
	for s in subfolders:
		ret += "/" + s
	return ret + ("/" + scene) if !only_dir else ""

## recursive function that gets all scenes in the given folder aswell as all subfolders adding each subfolder as an array into the subfolder_dict Dictionary
func _get_file_name_from_dir(path: String, subfolders: Array[String], subfolder_dict: Dictionary):
	var scene_dir = DirAccess.open(path)
	assert(scene_dir, "stage scene dir not found at: " + path)

	scene_dir.list_dir_begin()
	var scene_file: String = scene_dir.get_next()
	while scene_file != "":
		if scene_file.get_extension() == "tscn":
			if(subfolder_dict.has(scene_file)):
				push_error("Same filename for differente stages found: " + _get_path_to_scene(scene_file, subfolders) + " and " + _get_path_to_scene(scene_file, subfolder_dict[scene_file]) + "expect fauty behavior")
			subfolder_dict[scene_file] = subfolders.duplicate()
		elif scene_file.get_extension() == "":
			subfolders.append(scene_file)
			_get_file_name_from_dir(path + scene_file, subfolders, subfolder_dict)
			subfolders.pop_back()

		scene_file = scene_dir.get_next()

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

# ---------------------- signal functions

func _on_scene_options_item_selected(index: int) -> void:
	if index < 0:
		return
	selected_scene_file = scene_options.get_item_text(index)
	_reset_enemy_options(enemy_subfolders, stages_subfolders[selected_scene_file])

func _on_tab_container_tab_changed(tab: int) -> void:
	if tab == 0 && selected_scene_file == "":
		$TabContainer.current_tab = 1

## Create a new entry for an exit
func _on_add_exit_button_pressed() -> void:
	var exit: HBoxContainer = exit_boiler.duplicate()
	exit_indx += 1
	
	add_child(exit)
	move_child(exit, 1 + exit_indx)
	
	exit.name = "Exit" + str(exit_indx)
	exit.get_node("ExitNumber").text = str(exit_indx) + "."
	exit.show()
	
	exit_resource.append(Vector2i.ZERO, exit.get_node("ExitColor").color)
	
	set_slot(
		exit_indx,
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
		_on_exit_color_changed(child.get_node("ExitColor").color, child)
		exit_indx_new += 1
	
	exit_resource.remove_at(exit_num)
	exit.queue_free()

	exit_indx -= 1
	
func _on_exit_position_changed(val: float, exit: HBoxContainer, is_x: bool,):
	var exit_num: int = exit.name.to_int() - 1
	if is_x:
		exit_resource.set_x(exit_num, int(val))
	else:
		exit_resource.set_y(exit_num, int(val))
	
func _on_exit_color_changed(color: Color, exit: HBoxContainer):
	var exit_num: int = exit.name.to_int()
	set_slot(
		exit_num,
		false,
		0,
		exit_in_port_color,
		true,
		0,
		exit.get_node("ExitColor").color,
	)
	exit_resource.set_color(exit_num - 1, color)

## Create a new entry for an exit
func _on_add_enemy_button_pressed() -> void:
	var enemy: HBoxContainer = enemy_boiler.duplicate()
	enemy_indx += 1
	
	enemy_boiler.get_parent().add_child(enemy)
	enemy_boiler.get_parent().move_child(enemy, enemy_indx)
	
	enemy.name = "Enemy" + str(enemy_indx)
	enemy.get_node("EnemyNumber").text = str(enemy_indx) + "."
	_set_enemy_options(enemy.get_node("EnemySelect"))
	enemy.show()
	
	enemy_resource.append(Vector2i.ZERO, "")
	
	var remove_function: Callable = _on_remove_enemy_button_pressed.bind(enemy)
	var changed_function_x: Callable = _on_enemy_position_changed.bind(enemy, true)
	var changed_function_y: Callable = _on_enemy_position_changed.bind(enemy, false)
	var changed_function_file: Callable = _on_enemy_file_changed.bind(enemy)
	enemy.get_node("RemoveEnemyButton").pressed.connect(remove_function, ConnectFlags.CONNECT_ONE_SHOT)
	enemy.get_node("Position/x").value_changed.connect(changed_function_x)
	enemy.get_node("Position/y").value_changed.connect(changed_function_y)
	enemy.get_node("EnemySelect").item_selected.connect(changed_function_file)

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

func _on_enemy_position_changed(val: float, enemy: HBoxContainer, is_x: bool,):
	var enemy_num: int = enemy.name.to_int() - 1
	if is_x:
		enemy_resource.set_x(enemy_num, int(val))
	else:
		enemy_resource.set_y(enemy_num, int(val))

func _on_enemy_file_changed(index: int, enemy: HBoxContainer):
	var enemy_num: int = enemy.name.to_int() - 1
	enemy_resource.set_file(enemy_num, enemy.get_node("EnemySelect").get_item_text(index))

func _on_pickup_weight_changed(weight: float, pickup: int):
	if(pickup_resource.pickup_weights.has(pickup)):
		pickup_resource.pickup_weights[pickup] = weight
	else:
		push_error("Pickup " + globals.pickup_name_str[pickup] + " not yet implemented")
