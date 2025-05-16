extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Player):
	if pickup_owner.is_in_group("player"): #If this is a human
		# ONLY for the person who obtained it
		pickup_owner.enable_wallclip.rpc()
	else: #This is an AI
		# TODO: Needs messing with the A* mapper do it later
		pickup_owner.enable_wallclip()
