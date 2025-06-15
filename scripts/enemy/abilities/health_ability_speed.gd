extends Node

@export var speed_boost: float = 1.5
@export var alternative_sprite_sheet: Texture2D
var already_applied: bool = false
var old_sprite: Texture2D

func apply():
	if self.already_applied: return
	get_parent().movement_speed *= self.speed_boost
	if self.alternative_sprite_sheet:
		self.old_sprite = get_parent().sprite.texture
		get_parent().sprite.texture = self.alternative_sprite_sheet

func reset():
	if self.old_sprite:
		get_parent().sprite.texture = self.old_sprite
