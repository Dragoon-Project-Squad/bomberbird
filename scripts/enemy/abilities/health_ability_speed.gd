extends Node

@export var speed_boost: float = 1.5
@export var alternative_sprite_sheet: Texture2D
@onready var enemy: Enemy = get_parent()

var already_applied: bool = false
var old_sprite: Texture2D
var old_speed: float

func apply():
	if self.already_applied: return
	already_applied = true

	self.old_speed = self.enemy.movement_speed
	self.enemy.movement_speed *= self.speed_boost

	if self.alternative_sprite_sheet:
		self.old_sprite = self.enemy.sprite.texture
		self.enemy.sprite.texture = self.alternative_sprite_sheet

func reset():
	already_applied = false
	if self.old_sprite:
		self.enemy.sprite.texture = self.old_sprite
	if self.old_speed:
		self.enemy.movement_speed = old_speed
