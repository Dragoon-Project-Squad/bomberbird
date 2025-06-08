extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	if pickup_owner is HumanPlayer:
		pickup_owner.unlock_bomb_count.rpc()
	elif pickup_owner is AIPlayer:
		pickup_owner.unlock_bomb_count()
	elif pickup_owner is Boss:
		pass # mine should not lock boss enemies
