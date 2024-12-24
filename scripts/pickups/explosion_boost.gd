extends Pickup

func _on_body_entered(body: Node2D) -> void:
	if not is_multiplayer_authority():
		# Activate only on authority.
		return
	if body.is_in_group("player") or body.is_in_group("ai_player"):
		if body.is_in_group("player"): #If this is a human
			# Increase the bomb level ONLY for the person who obtained it
			body.increase_bomb_level.rpc()
		else: #This is an AI
			body.increase_bomb_level()
		# Either way, play pickup sound
		pickup_sfx_player.play()
		print(body.explosion_boost_count)
		# Remove powerup
		queue_free()
