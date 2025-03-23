extends GraphEdit

var stage_node_preload := preload("res://scenes/level_graph/stage_node.tscn")
var stage_node_indx: int = 0
var selected_nodes: Dictionary = {}

func _ready():
	var add_stage_node_button: Button = Button.new()
	add_stage_node_button.text = "Add Node"
	add_stage_node_button.pressed.connect(_add_stage_node.bind(null))
	get_menu_hbox().add_child(add_stage_node_button)
	self.right_disconnects = true

func reindex_ports(node: StringName, from: int, step: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port > from:
			disconnect_node(from_node, from_port, to_node, to_port)
			connect_node(from_node, from_port + step, to_node, to_port)

func remove_ports(node: StringName, port: int):
	for i in range(len(self.connections) -1, -1, -1):
		var from_node: StringName = self.connections[i].from_node
		var to_node: StringName = self.connections[i].to_node
		var from_port: int = self.connections[i].from_port
		var to_port: int = self.connections[i].to_port
		if from_node == node && from_port == port:
			disconnect_node(from_node, from_port, to_node, to_port)

func _add_stage_node(stage_node: StageNode):
	if stage_node == null:
		stage_node = stage_node_preload.instantiate()
	else:
		stage_node.position -= Vector2(20, 20)
	
	stage_node_indx += 1
	
	stage_node.name = "StageNode" + str(stage_node_indx)
	stage_node.title = "Stage Node " + str(stage_node_indx)
	
	add_child(stage_node)
	move_child(stage_node, 1 + stage_node_indx)
	

func _on_connect_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	for connection in self.connections:
		if connection.to_node == to_node && connection.from_node == from_node:
			return
		if connection.from_port == from_port && connection.from_node == from_node:
			return
	connect_node(from_node, from_port, to_node, to_port)

func _on_disconnect_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	disconnect_node(from_node, from_port, to_node, to_port)

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
