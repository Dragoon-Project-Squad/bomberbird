class_name EnemyStateMachine extends Node

@export var enabled_state: EnemyState
@export var disabled_state : EnemyState

var current_state : EnemyState
var states : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.state_changed.connect(_on_state_changed)
			child.enemy = get_parent() # This is arguably fine because its within its own scene tree imo
			child.world = globals.current_world
			globals.game.stage_has_changed.connect(child._on_new_stage)
	
	if disabled_state:
		disabled_state._enter()
		current_state = disabled_state 

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
	current_state = next_state

func enable():
	if current_state: current_state._exit()
	enabled_state._enter();
	current_state = enabled_state

func disable():
	if current_state: current_state._exit()
	disabled_state._enter();
	current_state = disabled_state
