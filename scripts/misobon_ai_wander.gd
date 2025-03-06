extends MisobonAiState

const WANDER_COOLDOWN: float = 6
const RAND_BOMB_CHANGE: float = 0.01 #Expected Value about every 100 frames a bomb is thrown randomly

var wander_cooldown: float = 0
var direction: int = 0

func _update(delta: float) -> void:
	player.wander_cooldown += delta
	
	if wander_cooldown >= 0 && is_multiplayer_authority():
		direction = rng.randi_range(-1, 1)
	
	player.progress += direction * player.MOVEMENT_SPEED * delta
	player.update_animation(
		player.get_parent().get_segmant_id(player.progress)
	)

	if rand_bombing():
		#TODO change into bombing state
		return
	
	if check_for_players():
		pass #TODO change state into bombing

#Private functions

func _rand_bombing():
	return rng.randf() < RAND_BOMB_CHANGE

func _check_for_players():
	var looking_direction: Vector2i = player.get_parent().get_direction(progress)
	for target in player_detect_area.get_overlapping_bodies():
		pass

