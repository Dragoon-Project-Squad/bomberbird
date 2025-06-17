extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	super(pickup_owner)
	if pickup_owner is HumanPlayer:
		# Increase the bomb level ONLY for the person who obtained it
		pickup_owner.increase_speed.rpc()
	elif pickup_owner is AIPlayer:
		pickup_owner.increase_speed()
	elif pickup_owner is Boss:
		pickup_owner.increase_speed()
