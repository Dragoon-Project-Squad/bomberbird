extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Node2D):
	super(pickup_owner)
	if pickup_owner is HumanPlayer: #If this is a human
		pickup_owner.do_invulnerability.rpc(Player.INVULNERABILITY_POWERUP_TIME)
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.do_invulnerability(Player.INVULNERABILITY_POWERUP_TIME)
	elif pickup_owner is Boss:
		pickup_owner.do_invulnerability(Player.INVULNERABILITY_POWERUP_TIME)
