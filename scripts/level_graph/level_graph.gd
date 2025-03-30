extends GraphEdit

const SAVE_PATH: String = "res://resources/level_graph/saved_graphs"

@onready var entry_point: GraphNode = $EntryPoint

var stage_node_preload := preload("res://scenes/level_graph/stage_node.tscn")
var stage_node_indx: int = 0
var selected_nodes: Dictionary = {}
var node_clipboard: Array[StageNodeData] = []
var file_name: String

func _ready():
	# create and add the add stage buttonm
	var add_stage_node_button: Button = Button.new()
	add_stage_node_button.text = "Add Node"
	add_stage_node_button.pressed.connect(_add_stage_node)
	get_menu_hbox().add_child(add_stage_node_button)

	# create and add the SuggestionLineEdit
	var file_name_input: SuggestionLineEdit = SuggestionLineEdit.new()
	file_name_input.name = "LoadSaveLEdit"
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

	
	self.right_disconnects = true

## all ports with an index larger them 'from' will be reindexed to + 'step'
func reindex_ports(node: StringName, from: int, step: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port > from:
			disconnect_node(from_node, from_port, to_node, to_port)
			connect_node(from_node, from_port + step, to_node, to_port)

## removes all connection to the given 'port' from the node 'node'
func remove_ports(node: StringName, port: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port == port:
			disconnect_node(from_node, from_port, to_node, to_port)

## adds a new & empty StageNode
func _add_stage_node():
	var stage_node: StageNode = stage_node_preload.instantiate()
	stage_node_indx += 1
	
	stage_node.name = "StageNode" + str(stage_node_indx)
	stage_node.title = "Stage Node " + str(stage_node_indx)
	
	add_child(stage_node)
	move_child(stage_node, 1 + stage_node_indx)

	stage_node.position_offset = (self.scroll_offset + self.size / 2) / self.zoom - stage_node.size / 2;
	stage_node.pickup_resource.update()
	stage_node._setup_pickup_tab()
	
func clear_graph():
	for child in get_children():
		if !child is StageNode: continue
		child.name = "REMOVING" + child.name
		child.queue_free()
	stage_node_indx = 0

## loads the graph stored in graph_data
func load_graph(graph_data: LevelGraphData):
	self.clear_connections()
	clear_graph()
	for node in graph_data.nodes:
		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		stage_node.load_stage_node(node)
	for connection in graph_data.connections:
		connect_node(connection.from_node, connection.from_port, connection.to_node, connection.to_port)

		
## loads the selected graph if it exists
func _on_load_pressed():
	if ResourceLoader.exists(SAVE_PATH + "/" + file_name + ".res"):
		load_graph(ResourceLoader.load(SAVE_PATH + "/" + file_name + ".res"))
	else:
		print("No savedata loaded")

## saves the current graph
func _on_save_pressed():
	var graph_data = LevelGraphData.new()
	graph_data.setup_local_to_scene()
	graph_data.connections = self.get_connection_list()
	graph_data.stage_node_indx = self.stage_node_indx
	graph_data.entry_point_pos = entry_point.position
	var start_node: StageNode
	for connection in connections:
		if connection.from_node != "EntryPoint": continue
		start_node = get_node(str(connection.to_node))
		break
	if start_node != null:
		_save_bfs(start_node, graph_data.nodes)
	if ResourceSaver.save(graph_data, SAVE_PATH + "/" + file_name + ".res") == OK:
		print("Graph saved at: ", SAVE_PATH + "/" + file_name + ".res")
	else:
		print("saving graph failed")

func _on_close_pressed():
	if !get_parent(): 
		get_tree().quit()
	else:
		self.queue_free()

## a Factory that creates StageNodeData's from StageNode
func _save_node(node: StageNode, index: int) -> StageNodeData:
	var node_data = StageNodeData.new()
	node_data.curr_enemy_options = node.curr_enemy_options
	node_data.selected_scene_file = node.selected_scene_file
	node_data.selected_scene_path = node.selected_scene_path
	node_data.pickup_resource = node.pickup_resource.duplicate()
	node_data.enemy_resource = node.enemy_resource.duplicate()
	node_data.exit_resource = node.exit_resource.duplicate()
	node_data.spawn_point_arr = node.spawn_point_arr.duplicate()
	node_data.stage_node_name = node.name
	node_data.stage_node_title = node.title
	node_data.stage_node_pos = node.position_offset
	node_data.index = index

	#fill the children array with -1 we later only overwrite an index in this array if it leads to a next stage
	node_data.children.resize(node.exit_resource.size())
	node_data.children.fill(-1)
	return node_data

## A bfs graph traversale inwhich each node will be saved to the StageNodeData array. A bfs is used to also store the array indices of the children to each entry
func _save_bfs(starting_node: StageNode, node_array: Array[StageNodeData]):
	var start_node_data: StageNodeData = _save_node(starting_node, 0)
	node_array.append(start_node_data)
	var queue: Array[StageNodeData] = [start_node_data]
	var visited: Dictionary = {starting_node: true}
	while !queue.is_empty():
		var curr_node: StageNodeData = queue.pop_front()
		for connection in connections:
			if connection.from_node != curr_node.stage_node_name: continue
			# connectes to nothing so indicate this
			if connection.to_node == "":
				curr_node.children.append(-1)
				continue
			
			var child: StageNode = self.get_node(str(connection.to_node))
			# If we have seen this child already just tell the resource its connected to it
			if visited.has(child): 
				curr_node.children[connection.from_port] = visited[child].index
				continue
			# If we have not seen this child yet create a new resource and append it to the array
			var child_node_res: StageNodeData = _save_node(child, len(node_array))
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

## disconnect on request
func _on_disconnect_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)

## delete nodes when used pressed the DELETE key
func _on_delete_nodes_request(nodes: Array[StringName]):
	for node_name in nodes:
		if node_name == "EntryPoint": continue
		get_node(str(node_name)).queue_free()

func _on_node_selected(node: Node) -> void:
	if node.name == "EntryPoint": return
	selected_nodes[node] = null

func _on_node_deselected(node: Node) -> void:
	if node.name == "EntryPoint": return

	selected_nodes.erase(node)

func _on_copy_nodes_request():
	var index: int = 0
	node_clipboard.clear()
	node_clipboard.resize(len(selected_nodes.keys()))
	for node in selected_nodes.keys():
		node_clipboard[index] = _save_node(node, index)
		node_clipboard[index].stage_node_pos -= Vector2(200, 200)
		node_clipboard[index].stage_node_title = "copy of " + node_clipboard[index].stage_node_title
		index += 1

func _on_cut_nodes_request() -> void:
	var index: int = 0
	node_clipboard.clear()
	node_clipboard.resize(len(selected_nodes.keys()))
	for node in selected_nodes.keys():
		node_clipboard[index] = _save_node(node, index)
		node_clipboard[index].stage_node_pos -= Vector2(200, 200)
		node_clipboard[index].titel = "copy of " + node_clipboard[index].title
		index += 1
		node.queue_free()
		selected_nodes.erase(node)

func _on_paste_nodes_request():
	for node in selected_nodes.keys():
		node.selected = false
	selected_nodes.clear()
	for node in node_clipboard:
		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		stage_node.load_stage_node(node)
		selected_nodes[stage_node] = null
		stage_node.selected = true

func _on_duplicate_nodes_request() -> void:
	var index: int = 0
	for node in selected_nodes.keys():
		var temp_storage: StageNodeData = _save_node(node, index)
		temp_storage.stage_node_pos -= Vector2(200, 200)
		temp_storage.stage_node_title = "copy of " + temp_storage.stage_node_titel

		var stage_node: StageNode = stage_node_preload.instantiate()
		stage_node_indx += 1

		add_child(stage_node)
		move_child(stage_node, 1 + stage_node_indx)

		node.selected = false
		selected_nodes.erase(node)
		stage_node.selected = true
		selected_nodes[stage_node] = null

		stage_node.load_stage_node(temp_storage)
		selected_nodes[stage_node] = true
		stage_node.selected = true
