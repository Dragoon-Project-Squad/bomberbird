extends Node

@export var initial_state : MisobonAiState
@onready var player = get_parent()

var current_state : MisobonAiState
var states: Dictionary = {}


func _ready():
	for state_node in get_children():
		if state_node is MisobonAiState:
			states[state_node.name.to_lower()] = state_node
			state_node.state_changed.connect(_on_state_changed)
			state_node.player = player
			state_node.raycasts = player.get_node("Raycasts")
	
	if initial_state:
		initial_state._enter()
		current_state = initial_state

func _process(delta):
	if current_state && player.controllable:
		current_state._update(delta)

func _on_state_changed(state, new_state):
	if(state != current_state):
		return
	
	var next_state = states.get(new_state.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state._exit()
	
	next_state._enter()
	current_state = next_state

func reset():
	for state in states.keys():
		states[state]._reset()
	if current_state: current_state._exit()
	if initial_state:
		initial_state._enter()
		current_state = initial_state
