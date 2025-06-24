class_name Exit extends Node2D


@export var exit_id: int

var exit_col_shape: CollisionShape2D

var in_use: bool = false
var used: bool = false
var enabled_signal_fun: Callable = enable.bind(true)

func _ready() -> void:
	disable()

@rpc("call_local")
func disable():
	exit_col_shape = get_node("ExitArea/ExitCollisionShape")
	in_use = false
	used = false
	self.position = Vector2.ZERO
	self.hide()
	exit_col_shape.set_deferred("disabled", 1)

func enable(_tile: int = 0, cell: Vector2i = Vector2i.ZERO, is_signal: bool = false):
	# if the signal is not for this exit do not enable and reconnect the signal
	exit_col_shape = get_node("ExitArea/ExitCollisionShape")
	if world_data.tile_map.local_to_map(self.position) != cell && is_signal: return
	self.show.call_deferred()
	exit_col_shape.set_deferred("disabled", 0)
	if is_signal:
		world_data.world_data_changed.disconnect(enabled_signal_fun)

@rpc("call_local")
@warning_ignore("SHADOWED_VARIABLE")
func place(pos: Vector2, exit_id: int):
	in_use = true
	used = false
	self.position = pos
	self.exit_id = exit_id
	assert(!world_data.is_tile(world_data.tiles.UNBREAKABLE, pos), "attempted to spawn an exit on a unbreakable")
	if world_data.is_tile(world_data.tiles.BREAKABLE, pos):
		#TODO: maybe make some visual on this position to indicate that a portal is hidden under the breakable at this position
		world_data.world_data_changed.connect(enabled_signal_fun)
	else:
		enable()

func _on_exit_body_entered(body: Node2D):
	if used: return
	elif body is HumanPlayer:
		used = true
		globals.game.next_stage(exit_id, body)
