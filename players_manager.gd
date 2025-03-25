#Abstract Layer between world/gamestate and players
#TODO: Move player related functions (evtl as static) from world and/or gamestate into here
class_name PlayerManager extends Node2D

func _init():
	globals.player_manager = self

func _on_hurry_up_start() -> void:
	if gamestate.misobon_mode == gamestate.misobon_states.OFF:
		return
	for player in get_children():
		if player is MultiplayerSpawner: continue
		player.hurry_up_started = true
		if !player.is_dead: continue
		if !is_multiplayer_authority(): continue
		player.misobon_player.play_despawn_animation.rpc()
		player.misobon_player.disable.rpc(true)
