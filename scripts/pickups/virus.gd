extends Pickup

func _init() -> void:
	indestructable = true #Viruses don't blow up to bombs.
	
func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Node2D):
	super(pickup_owner)
	if pickup_owner.is_in_group("player"): #If this is a human
		pickup_owner.virus.rpc()
	else: #This is an AI
		pickup_owner.virus()
