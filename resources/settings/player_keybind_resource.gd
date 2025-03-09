class_name PlayerKeybindResource
extends Resource

const MOVE_UP := "move_up"
const MOVE_LEFT := "move_left"
const MOVE_DOWN := "move_down"
const MOVE_RIGHT := "move_right"
const SET_BOMB := "set_bomb"
const DETONATE_RC := "detonate_rc"
const PUNCH_ACTION := "punch_action"
const SECONDARY_ACTION := "secondary_action"
const PAUSE := "pause"

@export var DEFAULT_MOVE_UP_KEY = InputEventKey.new()
@export var DEFAULT_MOVE_LEFT_KEY = InputEventKey.new()
@export var DEFAULT_MOVE_DOWN_KEY = InputEventKey.new()
@export var DEFAULT_MOVE_RIGHT_KEY = InputEventKey.new()
@export var DEFAULT_SET_BOMB_KEY = InputEventKey.new()
@export var DEFAULT_DETONATE_RC_KEY = InputEventKey.new()
@export var DEFAULT_PUNCH_ACTION_KEY = InputEventKey.new()
@export var DEFAULT_SECONDARY_ACTION_KEY = InputEventKey.new()
@export var DEFAULT_PAUSE_KEY = InputEventKey.new()

var move_up_key = InputEventKey.new()
var move_left_key = InputEventKey.new()
var move_down_key = InputEventKey.new()
var move_right_key = InputEventKey.new()
var set_bomb_key = InputEventKey.new()
var detonate_rc_key = InputEventKey.new()
var punch_action_key = InputEventKey.new()
var secondary_action_key = InputEventKey.new()
var pause_key = InputEventKey.new()
