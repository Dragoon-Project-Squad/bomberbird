class_name Exit extends Node2D

@export var exit_id: int

@onready var exit_col_shape: CollisionShape2D = get_node("ExitArea/ExitCollisionShape")

var in_use: bool = false
var used: bool = false

@rpc("call_local")
func disable():
	in_use = false
	self.position = Vector2.ZERO
	self.hide()
	exit_col_shape.set_deferred("disabled", 1)

@rpc("call_local")
@warning_ignore("SHADOWED_VARIABLE")
func place(pos: Vector2, exit_id: int):
	in_use = true
	used = false
	self.position = pos
	self.exit_id = exit_id
	self.show()
	exit_col_shape.set_deferred("disabled", 0)

func _on_exit_body_entered(body: Node2D):
	if body is Breakable:
		body.exploded(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID) #TODO: change this to crushed as soon as we have that implemented
	elif used: return
	elif body is HumanPlayer:
		globals.game.next_stage(exit_id)
		used = true
