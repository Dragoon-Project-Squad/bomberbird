extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Node2D):
	if pickup_owner is HumanPlayer: #If this is a human
		pickup_owner.start_invul.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.start_invul()
	elif pickup_owner is Boss:
		pickup_owner.start_invul()
