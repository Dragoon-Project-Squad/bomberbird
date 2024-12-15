extends CharacterBody2D
@onready var rock_sfx_player := $RockSound

@rpc("call_local")
func exploded(by_who):
	rock_sfx_player.play()
	$"../../Score".increase_score(by_who)
	$"AnimationPlayer".play("explode")
