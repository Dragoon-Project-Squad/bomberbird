extends EnemyState
# Handles knight's ability

var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var prep_time: float = 0.5

func _enter() -> void:
	self.enemy.stop_moving = true
	var sprite: Sprite2D = self.enemy.get_node("sprite")
	var fire_breath: Node2D = self.enemy.get_node("Firebreath")
	var fire_breath_range: int = 3
	var fire_breath_direction: Vector2

	match self._rand.randi_range(0, 3):
		0:
			fire_breath.rotation = 0
			fire_breath_direction = Vector2.RIGHT
			sprite.frame = 20
		1:
			fire_breath.rotation = PI / 2
			fire_breath_direction = Vector2.DOWN
			sprite.frame = 0
		2:
			fire_breath.rotation = PI
			fire_breath_direction = Vector2.LEFT
			sprite.frame = 12
		3:
			fire_breath.rotation = PI * 3 / 2
			fire_breath_direction = Vector2.UP
			sprite.frame = 6

	sprite.frame_changed.emit()
	for i in range(1, 4):
		if world_data.is_out_of_bounds(self.enemy.position + fire_breath_direction * i * 32) == -1: continue
		fire_breath_range = i - 1
		break
	if fire_breath_range > 0:
		print(fire_breath_range)
		self.enemy.anim_player.play("tank/fire_breath")
		await get_tree().create_timer(prep_time).timeout
		await fire_breath.start_breath(fire_breath_range)
	fire_breath.rotation = 0
	self.enemy.stop_moving = false
	self.enemy.anim_player.play("enemy/" + self.enemy.current_anim)
	state_changed.emit(self, "wander")
