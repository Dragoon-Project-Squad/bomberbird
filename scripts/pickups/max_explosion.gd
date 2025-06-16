extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	super(pickup_owner)
	if pickup_owner is HumanPlayer: #If this is a human
		# Increase the bomb level ONLY for the person who obtained it
		pickup_owner.maximize_bomb_level.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.maximize_bomb_level()
	elif pickup_owner is Boss:
		pass # this is handled by counting on usage
