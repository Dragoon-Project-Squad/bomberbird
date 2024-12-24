extends CharacterBody2D
@onready var rock_sfx_player := $RockSound

@rpc("call_local")
func exploded(by_who):
	rock_sfx_player.play()
	#$"../../Score".increase_score(by_who) Rocks don't count for score
	$"AnimationPlayer".play("explode")
	# Spawn a powerup where this rock used to be.
	$"../../PickupSpawner"._spawn_pickup(self.position)
