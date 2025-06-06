extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Player):
	if pickup_owner.is_in_group("player"): #If this is a human
		pickup_owner.decrease_speed.rpc()
	else: #This is an AI
		pickup_owner.decrease_speed()
