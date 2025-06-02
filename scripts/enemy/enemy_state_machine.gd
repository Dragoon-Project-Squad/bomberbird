class_name EnemyStateMachine extends Node

@export var enabled_state: EnemyState
@export var disabled_state: EnemyState

var current_state: EnemyState
var states: Dictionary = {}
var target = null
var stop_process: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.state_changed.connect(_on_state_changed)
			child.enemy = get_parent()
			child.state_machine = self
			globals.game.stage_has_changed.connect(child._on_new_stage)
	
	if disabled_state:
		disabled_state._enter()
		current_state = disabled_state 

func _process(delta):
	if current_state && !stop_process:
		current_state._update(delta)

func _physics_process(delta):
	if current_state && !stop_process:
		current_state._physics_update(delta)

func _on_state_changed(state: EnemyState, new_state: String) -> void:
	if(state != current_state):
		push_error("enemy state machine failed as a state tried to change that is not the current state")
		return

	if current_state:
		current_state._exit()

	current_state = states.get(new_state.to_lower())
	if !current_state:
		push_error("enemy state machine failed state: " + new_state + " does not exists")
		return
	
	current_state._enter()

func enable():
	if current_state: current_state._exit()
	enabled_state._enter();
	current_state = enabled_state

func disable():
	if current_state: current_state._exit()
	disabled_state._enter();
	current_state = disabled_state
