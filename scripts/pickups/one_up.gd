extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	super(pickup_owner)
	if pickup_owner is HumanPlayer: #If this is a human
		pickup_owner.increase_live.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		pass
	elif pickup_owner is Boss:
		pass # this is handled by counting on usage
