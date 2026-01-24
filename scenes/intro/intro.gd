extends Control

@onready var presents = $AndTDG
@onready var a_fangame = $AFangame

@onready var sky = %Sky
@onready var sun = %Sun
@onready var land = %Land
@onready var doki = %Doki

@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal intro_screen_shown(input_cancelled)

func anim_intro() -> void:
	animation_player.play("intro")

# Called in Main Menu by MenuMusic with no input from player
func end_intro(intro_ended_via_input : bool = false ) -> void:
	if animation_player.is_playing():
		animation_player.stop()
	get_node("/root/MainMenu").reveal_main_menu()
	intro_screen_shown.emit(intro_ended_via_input)
	queue_free()

func _process(_delta: float) -> void:
	if Input.is_anything_pressed():
		Wwise.post_event("snd_click", get_parent())
		end_intro(true)
