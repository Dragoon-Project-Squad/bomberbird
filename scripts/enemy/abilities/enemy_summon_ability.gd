extends EnemyState
# Handles enemies without ability

@export var summon_path: String = "res://scenes/enemies/gas_cloud.tscn"

func _enter() -> void:
	var summon: Enemy = globals.game.enemy_pool.request(summon_path)
	summon.place(self.enemy.position, summon_path)
	summon.enable()
	summon.enemy_died.connect(self.enemy.detection_handler._set_check, CONNECT_ONE_SHOT)
	state_changed.emit(self, "wander")
