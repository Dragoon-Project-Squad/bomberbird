extends EnemyState
## Implements the target behavior 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

func _enter():
	state_changed.emit(self, "wander")
