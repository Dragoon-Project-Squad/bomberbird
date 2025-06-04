extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	if pickup_owner is HumanPlayer: #If this is a human
		# ONLY for the person who obtained it
		pickup_owner.enable_wallclip.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		# TODO: Needs messing with the A* mapper do it later
		pickup_owner.enable_wallclip()
	elif pickup_owner is Boss:
		pickup_owner.enable_wallclip()
