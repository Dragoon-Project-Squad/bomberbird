extends Node2D
@onready var unbreakable_sfx_player := $UnbreakableSound

func _ready():
	# Make sure the bounding collider is disabled
	#$SolidCollider/Shape.disabled = true
	$AnimationPlayer.play("slam")

func _on_hit_detection_body_entered(body: Node2D) -> void:
	### Explode only on authority.
	if is_multiplayer_authority() && body.has_method("exploded"):
		var world = get_tree().get_root().get_node("World")
		var floor_tile_layer: TileMapLayer = world.get_node("Floor")
		# Check if body is on same tile
		if floor_tile_layer.map_to_local(floor_tile_layer.local_to_map(body.position)) == floor_tile_layer.map_to_local(floor_tile_layer.local_to_map(self.position)):
			body.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	## Enable area collider to check if they're under the unbreakable
	#$AreaCollider.disabled = false
	## Prevent being pushed before killed
	await get_tree().create_timer(0.05).timeout
