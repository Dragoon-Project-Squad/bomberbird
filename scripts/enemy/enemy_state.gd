class_name EnemyState extends Node

signal state_changed

var enemy: Enemy
var world: World

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
