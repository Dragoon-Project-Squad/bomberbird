extends Pickup

func _ready():
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Player):
	if pickup_owner.is_in_group("player"): #If this is a human
		# Increase the bomb level ONLY for the person who obtained it
		pickup_owner.enable_punch.rpc()
	else: #This is an AI
		pickup_owner.enable_punch()
