extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	if pickup_owner is Player: #If this is a human
		# Increase the bomb level ONLY for the person who obtained it
		pickup_owner.lock_bomb_count.rpc(1)
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.lock_bomb_count(1)
	elif pickup_owner is Boss:
		pass # this is handled by counting on usage
