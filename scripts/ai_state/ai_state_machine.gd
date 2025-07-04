extends Node

@export var initial_state : State
@onready var player: Player = get_parent()

var current_state : State
var states : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.state_changed.connect(_on_state_changed)
			child.aiplayer = player
			globals.game.stage_has_changed.connect(child._on_new_stage)
	
	if initial_state:
		initial_state._enter()
		current_state = initial_state

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_state && !player.time_is_stopped && !player.stop_movement && !player.is_dead && !player.stunned && !player.outside_of_game:
		current_state._update(delta)

func _physics_process(delta):
	if current_state && !player.time_is_stopped && !player.stop_movement && !player.is_dead && !player.stunned && !player.outside_of_game:
		current_state._physics_update(delta)

func _on_state_changed(state, new_state):
	if(state != current_state):
		return
	#print(state.name, " -> ", new_state)
	
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
