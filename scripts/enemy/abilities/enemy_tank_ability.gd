extends EnemyState
# Handles knight's ability

var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var prep_time: float = 0.5
var fire_breath: Node2D

func _enter() -> void:
	self.enemy.stop_moving = true
	fire_breath = self.enemy.get_node("Firebreath")
	var fire_breath_range: int = 3
	var fire_breath_direction: Vector2

	match self._rand.randi_range(0, 3):
		0:
			fire_breath.rotation = 0
			fire_breath_direction = Vector2.RIGHT
			self.enemy.sprite.frame = 20
		1:
			fire_breath.rotation = PI / 2
			fire_breath_direction = Vector2.DOWN
			self.enemy.sprite.frame = 0
		2:
			fire_breath.rotation = PI
			fire_breath_direction = Vector2.LEFT
			self.enemy.sprite.frame = 12
		3:
			fire_breath.rotation = PI * 3 / 2
			fire_breath_direction = Vector2.UP
			self.enemy.sprite.frame = 6

	self.enemy.sprite.frame_changed.emit()
	for i in range(1, 4):
		if world_data.is_out_of_bounds(self.enemy.position + fire_breath_direction * i * 32) == -1: continue
		fire_breath_range = i - 1
		break
	if fire_breath_range > 0:
		self.enemy.anim_player.play("tank/fire_breath")
		self.enemy.current_anim = ""
		await get_tree().create_timer(prep_time).timeout
		if globals.game.stage_done || self.enemy.disabled: return
		await fire_breath.start_breath(fire_breath_range)
		if globals.game.stage_done || self.enemy.disabled: return
	fire_breath.rotation = 0
	state_changed.emit(self, "wander")
	
func _reset() -> void:
	self.enemy.stop_moving = false
	self.fire_breath.disable()



func _exit() -> void:
	self.enemy.stop_moving = false
