extends Pickup

func _ready():
	animated_sprite.play("idle")
	
func _on_body_entered(body: Node2D) -> void:
	if not is_multiplayer_authority():
		# Activate only on authority.
		return
	if body.is_in_group("player") or body.is_in_group("ai_player"):
		#Prevent anyone else from colliding with this pickup
		hide_and_disable.rpc()
		if pickup_owner == null: #Only ever let this be assigned once
			pickup_owner = body
		if pickup_owner.is_in_group("player"): #If this is a human
			# Increase the bomb level ONLY for the person who obtained it
			pickup_owner.maximize_bomb_level.rpc()
		else: #This is an AI
			pickup_owner.maximize_bomb_level()
		#print(pickup_owner.explosion_boost_count)
		# Ensure powerup has time to play before pickup is destroyed
		pickup_sfx_player.play()
		await pickup_sfx_player.finished
		# Remove powerup
		queue_free()
