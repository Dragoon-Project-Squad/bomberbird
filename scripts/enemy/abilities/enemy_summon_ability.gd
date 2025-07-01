extends EnemyState
# Handles enemies with the ability of summoning other enemies

@export var summon_path: String = "res://scenes/enemies/gas_cloud.tscn"

func _enter() -> void:
	var summon: Enemy = globals.game.enemy_pool.request(summon_path)
	summon.place(self.enemy.position, summon_path)
	summon.enable(false)

	globals.current_world.alive_enemies.append(summon)
	globals.game.clock_pickup_time_paused.connect(summon.stop_time)
	globals.game.clock_pickup_time_unpaused.connect(summon.start_time)

	summon.enemy_died.connect(func ():
		self.enemy.detection_handler._set_check()
		globals.current_world.alive_enemies.erase(summon)
		globals.game.clock_pickup_time_paused.disconnect(summon.stop_time)
		globals.game.clock_pickup_time_unpaused.disconnect(summon.start_time)
		if globals.current_world.alive_enemies.is_empty():
			globals.current_world.all_enemied_died.emit(0),
		CONNECT_ONE_SHOT
		)
	state_changed.emit(self, "wander")
