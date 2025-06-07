extends Control

func _ready() -> void:
	var ui_player_data = globals.game.game_ui.player_labels
	var textures = gamestate.characters
	var player_names = gamestate.players.duplicate()
	player_names[1] = gamestate.host_player_name 
	globals.game.queue_free()
	var sorted_player_id_by_score = sort_player_ids_by_score(ui_player_data)
	set_player_texture.rpc(sorted_player_id_by_score, textures, player_names)
	
	$AnimationPlayer.play("fade_in")
	var anim  : Animation= $Control/AnimationPlayer1.get_animation("victory")
	anim.loop_mode =(Animation.LOOP_LINEAR)
	$Control/AnimationPlayer1.play("victory")
	if $"Control/4th".visible:
		$Control/AnimationPlayer2.play("cry")

func sort_player_ids_by_score(player_scores) -> Array:
	var sorted_player_id_by_score = []
	
	for player_id in player_scores.keys():
		if sorted_player_id_by_score.is_empty():
			sorted_player_id_by_score.append(player_id)
			continue
		
		for i in sorted_player_id_by_score.size():
			if player_scores[player_id]["score"] > player_scores[sorted_player_id_by_score[i]]["score"]:
				sorted_player_id_by_score.insert(i, player_id)
				break
			
			if i == sorted_player_id_by_score.size()-1:
				sorted_player_id_by_score.append(player_id)
	
	return sorted_player_id_by_score

@rpc("call_local")
func set_player_texture(player_ids, textures, gs_players) -> void:
	$Label.text = "The winner is " + gs_players[player_ids[0]]
	for i in player_ids.size():
		match i:
			0:
				$"Control/1st".texture = load(textures[player_ids[0]])
				$"Control/1st/Label".text = gs_players[player_ids[0]]
			1:
				$"Control/2nd".texture = load(textures[player_ids[1]])
				$"Control/2nd/Label".text = gs_players[player_ids[1]]
			2:
				$"Control/3rd".texture = load(textures[player_ids[2]])
				$"Control/3rd/Label".text = gs_players[player_ids[2]]
			3:
				$"Control/4th".texture = load(textures[player_ids[3]])
				$"Control/4th/Label".text = gs_players[player_ids[3]]
	
	for i in range(gamestate.MAX_PEERS-player_ids.size(), gamestate.MAX_PEERS):
		match i:
			0:
				$"Control/1st".visible = false
			1:
				$"Control/2nd".visible = false
			2:
				$"Control/3rd".visible = false
			3:
				$"Control/4th".visible = false
				$Control/kaboom.visible = false
		

@rpc("call_local")
func _on_timer_timeout():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	gamestate.player_list_changed.emit()
