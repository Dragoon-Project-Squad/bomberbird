class_name LevelGraph extends GraphEdit

signal has_loaded(file_name: String)
signal has_saved(file_name: String)
signal has_changed
signal has_closed

const SAVE_PATH: String = "user://user_campaigns"
const PERMANENT_SAVE_PATH: String = "res://campaign"
const VERSION: String = "post_v0.9.9.0_1"

@onready var entry_point: GraphNode = $EntryPoint

var file_name_input: SuggestionLineEdit
var stage_node_preload := preload("res://scenes/level_graph/stage_node.tscn")
var stage_node_indx: int = 0
var selected_nodes: Dictionary = {}
var node_clipboard: Array[Dictionary] = []
var file_name: String
var is_saved: bool = true
var confirmation_dialog: ConfirmationDialog

func _ready():
	# create and add the add stage buttonm
	var add_stage_node_button: Button = Button.new()
	add_stage_node_button.text = "Add Node"
	add_stage_node_button.pressed.connect(_add_stage_node)
	get_menu_hbox().add_child(add_stage_node_button)


	# create and add the SuggestionLineEdit
	file_name_input = SuggestionLineEdit.new()
	file_name_input.name = "LoadSaveLEdit"
	has_saved.connect(file_name_input._on_graph_edit_saved)
	file_name_input.text_changed.connect(func (new_text: String): file_name = new_text)
	get_menu_hbox().add_child(file_name_input)

	# create and add the load button
	var load_button: Button = Button.new()
	load_button.text = "load"
	load_button.pressed.connect(_on_load_pressed)
	get_menu_hbox().add_child(load_button)
	
	# create and add the save button
	var save_button: Button = Button.new()
	save_button.text = "save"
	save_button.pressed.connect(_on_save_pressed)
	get_menu_hbox().add_child(save_button)

	# create and add the close button
	var close_button: Button = Button.new()
	close_button.text = "close"
	close_button.pressed.connect(_on_close_pressed)
	get_menu_hbox().add_child(close_button)
	var contr: Control = get_menu_hbox().add_spacer(false)
	contr.custom_minimum_size = Vector2(10, 0)
	contr.update_minimum_size()

	# create and add the clear_all button
	var clear_all_button: Button = Button.new()
	clear_all_button.text = "CLEAR"
	clear_all_button.pressed.connect(_on_clear_all_pressed)
	get_menu_hbox().add_child(clear_all_button)
	
	confirmation_dialog = ConfirmationDialog.new()
	add_child(confirmation_dialog)

	self.right_disconnects = true
	has_changed.connect(func (): self.is_saved = false)
	has_saved.connect(func (_file_name): self.is_saved = true)
	has_loaded.connect(func (_file_name): self.is_saved = true)

## when called all ports with an index larger them [param from] will be reindexed to + [param step]
## [param node] StringName of the node whos port should be reindexed
## [param from] int Port index from which all after will be reindexed
## [param step] int the step that wil be reindex to (e.g. -1 to subtract 1 from each port)
func reindex_ports(node: StringName, from: int, step: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port > from:
			disconnect_node(from_node, from_port, to_node, to_port)
			connect_node(from_node, from_port + step, to_node, to_port)

## removes all connection to the given [param port] from the node [param node]
## [param node] StringName of the node whos port should be removed
## [param port] int of the port removed
func remove_ports(node: StringName, port: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port == port:
			disconnect_node(from_node, from_port, to_node, to_port)

## adds a new & empty StageNode (called by signal)
func _add_stage_node():
	var stage_node: StageNode = stage_node_preload.instantiate()
	stage_node_indx += 1
	
	stage_node.name = "StageNode" + str(stage_node_indx)
	stage_node.title = "Stage Node " + str(stage_node_indx)
	
	add_child(stage_node)
	move_child(stage_node, 1 + stage_node_indx)

	stage_node.has_changed.connect(func (): self.has_changed.emit())
	stage_node.position_offset = (self.scroll_offset + self.size / 2) / self.zoom - stage_node.size / 2;
	stage_node.pickup_resource.update()
	stage_node._setup_pickup_tab()
	has_changed.emit()
	
## clears the graph (removing all nodes and connections with the exeption of the starting node)
func clear_graph():
	selected_nodes.clear()
	for child in get_children():
		if !child is StageNode: continue
		child.name = "REMOVING" + child.name
		child.queue_free()
	stage_node_indx = 0
	has_changed.emit()

## loads the graph stored in graph_data
## [param graph_data] LevelGraphData the resource to load the data from
func load_graph(graph_data: Dictionary):
	self.clear_connections()
	clear_graph()
	if graph_data == {}: 
		has_loaded.emit(file_name)
		return
	for node in graph_data.nodes:
		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		stage_node.has_changed.connect(func (): self.has_changed.emit())
		stage_node.load_stage_node(node)
	for connection in graph_data.connections:
		connect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)
	has_loaded.emit(file_name)

## loads the selected graph if it exists
## takes the global value file_name to check if such a LevelGraphData file exists and if it does load it
func _on_load_pressed():
	if is_saved:
		_on_load_confirmed()
		return

	for sig_arr in confirmation_dialog.get_ok_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)
	for sig_arr in confirmation_dialog.get_cancel_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)

	confirmation_dialog.title = "load file?"
	confirmation_dialog.dialog_text = "you have unsaved progress\nAre you sure you wish to load a different file?\nprogress will be lost"
	confirmation_dialog.get_ok_button().pressed.connect(_on_load_confirmed, CONNECT_ONE_SHOT)
	confirmation_dialog.get_cancel_button().pressed.connect(confirmation_dialog.hide, CONNECT_ONE_SHOT)
	confirmation_dialog.popup_centered()

func _on_load_confirmed():
	confirmation_dialog.hide()
	load_graph(load_json_file(file_name))
	self.grab_focus()

func _on_save_pressed():
	if !FileAccess.file_exists(SAVE_PATH + "/" + file_name + ".json"): 
		_on_save_confirmed()
		self.grab_focus()
		return

	for sig_arr in confirmation_dialog.get_ok_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)
	for sig_arr in confirmation_dialog.get_cancel_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)

	confirmation_dialog.title = "overwriting file?"
	confirmation_dialog.dialog_text = "are you sure you wish to overwrite file: " + file_name + "?"
	confirmation_dialog.get_ok_button().pressed.connect(_on_save_confirmed, CONNECT_ONE_SHOT)
	confirmation_dialog.get_cancel_button().pressed.connect(confirmation_dialog.hide, CONNECT_ONE_SHOT)
	confirmation_dialog.popup_centered()

## saves the current graph
func _on_save_confirmed():
	confirmation_dialog.hide()
	if file_name == "": # stops saving a graph as ".res"
		file_name_input.editable = 0
		await get_tree().create_timer(0.2).timeout
		file_name_input.editable = 1
		return
	var graph_data: Dictionary = {}
	graph_data["version"] = VERSION
	graph_data["connections"] = self.get_connection_list()
	graph_data["stage_node_indx"] = self.stage_node_indx
	graph_data["entry_point_pos"] = entry_point.position
	var node_arr: Array[Dictionary] = []
	graph_data["nodes"] = node_arr
	var start_node: StageNode
	for connection in connections:
		if connection.from_node != "EntryPoint": continue
		start_node = get_node(str(connection.to_node))
		break
	if start_node != null:
		_save_bfs(start_node, graph_data["nodes"])

	var file_access := FileAccess.open(SAVE_PATH + "/" + file_name + ".json", FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return

	file_access.store_line(JSON.stringify(graph_data))
	file_access.close()
	has_saved.emit(file_name)
	self.grab_focus()

func _on_close_pressed():
	if is_saved:
		_on_close_confirmed()
		return

	for sig_arr in confirmation_dialog.get_ok_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)
	for sig_arr in confirmation_dialog.get_cancel_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)

	confirmation_dialog.title = "close editor?"
	confirmation_dialog.dialog_text = "you have unsaved progress.\nAre you sure you wish to close the editor?\nprogress will be lost"
	confirmation_dialog.get_ok_button().pressed.connect(_on_close_confirmed, CONNECT_ONE_SHOT)
	confirmation_dialog.get_cancel_button().pressed.connect(confirmation_dialog.hide, CONNECT_ONE_SHOT)
	confirmation_dialog.popup_centered()

## removes itself
func _on_close_confirmed():
	confirmation_dialog.hide()
	if !get_parent(): 
		get_tree().quit()
	else:
		self.queue_free()
	has_closed.emit(file_name)

func _on_clear_all_pressed():
	for sig_arr in confirmation_dialog.get_ok_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)
	for sig_arr in confirmation_dialog.get_cancel_button().pressed.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)

	confirmation_dialog.title = "clear file?"
	confirmation_dialog.dialog_text = "Are you sure you wish to clear all nodes"
	confirmation_dialog.get_ok_button().pressed.connect(
		func ():
			confirmation_dialog.hide()
			self.clear_connections()
			clear_graph(),
		CONNECT_ONE_SHOT
		)
	confirmation_dialog.get_cancel_button().pressed.connect(confirmation_dialog.hide, CONNECT_ONE_SHOT)
	confirmation_dialog.popup_centered()
	self.grab_focus()


## A bfs graph traversale inwhich each node will be saved to the StageNodeData array. A bfs is used to also store the array indices of the children to each entry
## The reason for a bfs rather then just looping through the node is so we can also store a children array that contains the indices of all of a node children inside the saved array
## [param starting_node] StageNode Node on which the bfs should start
## [param node_array] the array inwhich the algoritm will save StageNodeData resources
func _save_bfs(starting_node: StageNode, node_array: Array[Dictionary]):
	var start_node_data: Dictionary = starting_node.save_node(0)
	node_array.append(start_node_data)
	var queue: Array[Dictionary] = [start_node_data]
	var visited: Dictionary = {starting_node: start_node_data}
	while !queue.is_empty():
		var curr_node: Dictionary = queue.pop_front()
		for connection in connections:
			if connection.from_node != curr_node.stage_node_name: continue
			# connectes to nothing
			if connection.to_node == "":
				continue
			
			var child: StageNode = self.get_node(str(connection.to_node))
			# If we have seen this child already just tell the resource its connected to it
			if visited.has(child): 
				curr_node["children"][connection.from_port] = visited[child].index
				continue
			# If we have not seen this child yet create a new resource and append it to the array
			var child_node_res: Dictionary = child.save_node(len(node_array))
			curr_node.children[connection.from_port] = child_node_res.index
			node_array.append(child_node_res)
			visited[child] = child_node_res
			queue.append(child_node_res)

## Connect node on request but ensure exits remain unique and each exits leads to a different stage
func _on_connect_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	for connection in self.connections:
		if connection.to_node == to_node && connection.from_node == from_node: # attempted to connect an exit to a stage where a different exit already connects to
			return
		if connection.from_port == from_port && connection.from_node == from_node: # attempted to connect an exit thats already connected to somewhere else
			return
	connect_node(from_node, from_port, to_node, to_port)
	has_changed.emit()

## disconnect on request
func _on_disconnect_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)
	has_changed.emit()

## delete nodes when used pressed the DELETE key
func _on_delete_nodes_request(nodes: Array[StringName]):
	for node_name in nodes:
		if node_name == "EntryPoint": continue
		var node := get_node(str(node_name))
		if selected_nodes.has(node):
			selected_nodes.erase(node)
		for sig_arr in node.has_changed.get_connections():
			sig_arr.signal.disconnect(sig_arr.callable)
		node.queue_free()
	has_changed.emit()

## Adds a selected node to the selected_nodes set for later processing if needed
func _on_node_selected(node: Node) -> void:
	if node.name == "EntryPoint": return
	selected_nodes[node] = null

## removes a selected node to the selected_nodes set
func _on_node_deselected(node: Node) -> void:
	if node.name == "EntryPoint": return

	selected_nodes.erase(node)

## stores all nodes in the selected_nodes set as resources into its own clipboard to allow for later pasting
func _on_copy_nodes_request():
	var index: int = 0
	node_clipboard.clear()
	node_clipboard.resize(len(selected_nodes.keys()))
	for node in selected_nodes.keys():
		node_clipboard[index] = node.save_node(index)
		node_clipboard[index].stage_node_pos = var_to_str(str_to_var(node_clipboard[index].stage_node_pos) - Vector2(-50, 50))
		node_clipboard[index].stage_node_title = "copy of " + node_clipboard[index].stage_node_title
		index += 1

## stores and removes all nodes in the selected_nodes set as resources into its own clipboard to allow for later pasting
func _on_cut_nodes_request() -> void:
	var index: int = 0
	node_clipboard.clear()
	node_clipboard.resize(len(selected_nodes.keys()))
	for node in selected_nodes.keys():
		node_clipboard[index] = node.save_node(index)
		node_clipboard[index].stage_node_pos = var_to_str(str_to_var(node_clipboard[index].stage_node_pos) - Vector2(-50, 50))
		index += 1
		for sig_arr in node.has_changed.get_connections():
			sig_arr.signal.disconnect(sig_arr.callable)
		node.queue_free()
		selected_nodes.erase(node)
	has_changed.emit()

## rebuilds all nodes in the clipboard
func _on_paste_nodes_request():
	if node_clipboard.is_empty(): return
	for node in selected_nodes.keys():
		node.selected = false
	selected_nodes.clear()
	for node in node_clipboard:
		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		stage_node.has_changed.connect(func (): self.has_changed.emit())
		stage_node.load_stage_node(node)
		selected_nodes[stage_node] = null
		stage_node.selected = true
	has_changed.emit()

## duplicates all nodes in the selected_nodes set
func _on_duplicate_nodes_request() -> void:

	var index: int = 0
	for node in selected_nodes.keys():
		var temp_storage: Dictionary = node.save_node(index)
		temp_storage.stage_node_pos = var_to_str(str_to_var(temp_storage.stage_node_pos) - Vector2(-50, 50))
		temp_storage.stage_node_title = "copy of " + temp_storage.stage_node_title

		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		stage_node.has_changed.connect(func (): self.has_changed.emit())
		node.selected = false
		selected_nodes.erase(node)
		stage_node.selected = true
		selected_nodes[stage_node] = null

		stage_node.load_stage_node(temp_storage)
		selected_nodes[stage_node] = true
		stage_node.selected = true
	has_changed.emit()

static func load_json_file(json_file_name: String, file_access_level = FileAccess.READ) -> Dictionary:
	if !FileAccess.file_exists(SAVE_PATH + "/" + json_file_name + ".json"):
		print("file: ", SAVE_PATH, "/", json_file_name, ".json", " not found loading empty graph")
		return {}
	var file_access := FileAccess.open(SAVE_PATH + "/" + json_file_name + ".json", file_access_level)
	var json_string := file_access.get_line()
	file_access.close()
	
	var json: JSON = JSON.new()
	var error := json.parse(json_string)
	if error:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return {}
	return json.data

static func load_graph_to_stage_node_data_arr(json_data: Dictionary) -> Array[StageNodeData]:
	var res: Array[StageNodeData] = []
	for node_data in json_data.nodes:
		var stage_node_data: StageNodeData = StageNodeData.new()
		stage_node_data.from_json(node_data)
		res.append(stage_node_data)
	return res
