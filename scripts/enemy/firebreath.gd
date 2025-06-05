extends Node2D

const max_range = 3

signal breath_finished

@onready var fire_ball_sprites: Array[Sprite2D] = [$Fireball, $Fireball11, $Fireball12, $Fireball2, $Fireball21, $Fireball3]
@onready var fire_ball_area: Array[Node] = $Area2D.get_children()

var breath_range: int
var curr_range: int = 0

func _ready():
	stop_breath()

func stop_breath() -> void:
	$AnimationPlayer.play("RESET")
	for sprite in fire_ball_sprites:
		sprite.hide()
	for area in fire_ball_area:
		area.set_deferred("disabled", 1)
	await $AnimationPlayer.animation_finished
	breath_finished.emit()

func start_breath(set_breath_range: int) -> Signal:
	assert(set_breath_range > 0)
	assert(set_breath_range <= max_range)
	self.curr_range = 0
	match set_breath_range:
		1: self.breath_range = 2
		2: self.breath_range = 4
		3: self.breath_range = 6
	$AnimationPlayer.play("breath")
	return breath_finished

func _animation_continue() -> void:
	if curr_range == breath_range: return
	for i in range(0, len(self.fire_ball_area)):
		if i <= curr_range:
			fire_ball_sprites[i].show()
			fire_ball_area[i].set_deferred("disabled", 0)
		else:
			fire_ball_sprites[i].hide()
			fire_ball_area[i].set_deferred("disabled", 1)
	self.curr_range += 1

func _on_body_entered(body: Node2D) -> void:
	if is_multiplayer_authority() && body.has_method("exploded"):
		if self not in body.get_children():
			body.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID)
