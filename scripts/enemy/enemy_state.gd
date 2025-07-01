class_name EnemyState extends Node

signal state_changed

var enemy: Enemy
var state_machine: EnemyStateMachine

# Overwrite "_" functions as needed
func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(_delta : float) -> void:
	pass

func _physics_update(_delta : float) -> void:
	pass

func _on_new_stage():
	pass

func _reset():
	pass

func _move(_delta, speed_boost: float = 1):
	#Update position
	if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.enemy.synced_position = self.enemy.position
	else:
		# The client simply updates the position to the last known one.
		self.enemy.position = self.enemy.synced_position
	
	# Also update the animation based on the last known player input state
	self.enemy.last_movement_vector = self.enemy.movement_vector.normalized()
	if self.enemy.stunned: return
	self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed * speed_boost
	self.enemy.move_and_slide()
