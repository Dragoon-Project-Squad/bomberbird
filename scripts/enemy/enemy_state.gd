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

func _move(_delta):
	#Update position
	if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.enemy.synced_position = self.enemy.position
	else:
		# The client simply updates the position to the last known one.
		self.enemy.position = self.enemy.synced_position
	
	# Also update the animation based on the last known player input state
	if self.enemy.stunned: return
	if self.enemy is Boss:
		self.enemy.velocity = self.enemy.movement_vector.normalized() * (self.enemy.movement_speed + 20 * self.enemy.pickups.held_pickups[globals.pickups.SPEED_UP])
	else:
		self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed
	self.enemy.move_and_slide()
