extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	var is_mounted := false
	if body is Player:
		is_mounted = body.is_mounted
	if not is_mounted:
		super(body)

func apply_power_up(pickup_owner):
	super(pickup_owner)
	if pickup_owner is HumanPlayer: #If this is a human
		pickup_owner.mount_dragoon.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.mount_dragoon()
	elif pickup_owner is Boss:
		pass # this is handled by counting on usage
