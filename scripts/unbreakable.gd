extends CharacterBody2D
@onready var unbreakable_sfx_player := $UnbreakableSound


func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		## Explode only on authority.
		body.exploded.rpc(0)
