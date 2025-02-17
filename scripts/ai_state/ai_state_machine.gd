extends Node

@export var initial_state : State

var current_state : State
var states : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_changed.connect(_on_state_changed)
			child.aiplayer = get_parent()
			child.world = get_parent().get_parent().get_parent()
	
	if initial_state:
		initial_state._enter()
		current_state = initial_state

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state:
		current_state._update(delta)

func _physics_process(delta):
	if current_state:
		current_state._physics_update(delta)

func _on_state_changed(state, new_state):
	if(state != current_state):
		return
	
	var next_state = states.get(new_state.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state._exit()
	
	next_state._enter()
