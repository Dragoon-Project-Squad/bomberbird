#Abstract Layer between world/gamestate and players
#TODO: Move player related functions (evtl as static) from world and/or gamestate into here
class_name PlayerManager extends Node2D

func _on_restriction_start_timer_timeout() -> void:
	if gamestate.misobon_mode == gamestate.misobon_states.OFF:
		return
	for player in get_children():
		player.hurry_up_started = true
		if !player.is_dead: continue
		if !is_multiplayer_authority(): continue
		player.misobon_player.play_despawn_animation.rpc()
		player.misobon_player.disable.rpc(true)
