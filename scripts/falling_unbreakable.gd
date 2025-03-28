class_name FallingUnbreakable extends Node2D
@onready var unbreakable_sfx_player := $UnbreakableSound

@rpc("call_local")
func place(pos: Vector2):
	self.position = pos
	$AnimationPlayer.play("slam")

func crush_colliding_obj(objs: Array):
	for obj in objs:
		### Explode only on authority.
		if is_multiplayer_authority() && obj.has_method("exploded"):
			var floor_tile_layer: TileMapLayer = world_data.tile_map
			# Check if body is on same tile
			if floor_tile_layer.local_to_map(obj.position) == floor_tile_layer.local_to_map(self.position):
				obj.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	crush_colliding_obj($HitDetection.get_overlapping_bodies())
	crush_colliding_obj($HitDetection.get_overlapping_areas())

	var hurry_up_tilemap: TileMapLayer = get_parent()
	hurry_up_tilemap.place(self.position)
	
	self.position = Vector2.ZERO
