extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Player):
	if pickup_owner.is_in_group("player"): #If this is a human
		# Increase the bomb level ONLY for the person who obtained it
		pickup_owner.increment_bomb_count.rpc()
	else: #This is an AI
		pickup_owner.increment_bomb_count()
