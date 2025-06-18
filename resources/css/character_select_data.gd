class_name CharacterSelectDataResource
extends Resource

# Select Texture Paths
@export var EGGOON_SELECT_TEXTURE_PATH: String = "res://assets/css/eggoon.png"
@export var NORMALGOON_SELECT_TEXTURE_PATH: String = "res://assets/css/normalgoon.png"
@export var CHONKGOON_SELECT_TEXTURE_PATH: String = "res://assets/css/chonkgoon.png"
@export var LONGGOON_SELECT_TEXTURE_PATH: String = "res://assets/css/longgoon.png"
@export var DAD_SELECT_TEXTURE_PATH: String = "res://assets/css/dad.png"
@export var BHDOKI_SELECT_TEXTURE_PATH: String = "res://assets/css/bhdoki.png"
@export var RETRODOKI_SELECT_TEXTURE_PATH: String = "res://assets/css/retrodoki.png"
@export var ALTGIRLDOKI_SELECT_TEXTURE_PATH: String = "res://assets/css/altdoki.png"
@export var CROWKI_SELECT_TEXTURE_PATH: String = "res://assets/css/crowki.png"
@export var TOMATODOKI_SELECT_TEXTURE_PATH: String = "res://assets/css/tomato.png"
@export var SECRET1_SELECT_TEXTURE_PATH: String = "res://assets/css/wisp.png"
@export var SECRET2_SELECT_TEXTURE_PATH: String = "res://assets/css/maidmint.png"


# Player Texture Paths
@export var EGGOON_PLAYER_TEXTURE_PATH: String = "res://assets/player/eggoon_walk.png"
@export var NORMALGOON_PLAYER_TEXTURE_PATH: String = "res://assets/player/normalgoon_walk.png"
@export var CHONKGOON_PLAYER_TEXTURE_PATH: String = "res://assets/player/chonkgoon_walk.png"
@export var LONGGOON_PLAYER_TEXTURE_PATH: String = "res://assets/player/longgoon_walk.png"
@export var DAD_PLAYER_TEXTURE_PATH: String = "res://assets/player/dad_walk.png"
@export var BHDOKI_PLAYER_TEXTURE_PATH: String = "res://assets/player/bhdoki_walk.png"
@export var RETRODOKI_PLAYER_TEXTURE_PATH: String = "res://assets/player/retrodoki_walk.png"
@export var ALTGIRLDOKI_PLAYER_TEXTURE_PATH: String = "res://assets/player/altdoki_walk.png"
@export var CROWKI_PLAYER_TEXTURE_PATH: String = "res://assets/player/crowki_walk.png"
@export var TOMATODOKI_PLAYER_TEXTURE_PATH: String = "res://assets/player/tomatodoki_walk.png"
@export var SECRET1_PLAYER_TEXTURE_PATH: String = "res://assets/player/wisp_walk.png"
@export var SECRET2_PLAYER_TEXTURE_PATH: String = "res://assets/player/maidmint_walk.png"

# Mount Texture Paths
@export var EGGOON_MOUNT_TEXTURE_PATH: String = "res://assets/css/eggoon.png"
@export var NORMALGOON_MOUNT_TEXTURE_PATH: String = "res://assets/css/normalgoon.png"
@export var CHONKGOON_MOUNT_TEXTURE_PATH: String = "res://assets/css/chonkgoon.png"
@export var LONGGOON_MOUNT_TEXTURE_PATH: String = "res://assets/css/longgoon.png"
@export var DAD_MOUNT_TEXTURE_PATH: String = "res://assets/css/dad.png"
@export var BHDOKI_MOUNT_TEXTURE_PATH: String = "res://assets/css/bhdoki.png"
@export var RETRODOKI_MOUNT_TEXTURE_PATH: String = "res://assets/css/retrodoki.png"
@export var ALTGIRLDOKI_MOUNT_TEXTURE_PATH: String = "res://assets/css/altdoki.png"
@export var CROWKI_MOUNT_TEXTURE_PATH: String = "res://assets/css/crowki.png"
@export var TOMATODOKI_MOUNT_TEXTURE_PATH: String = "res://assets/css/tomato.png"
@export var SECRET1_MOUNT_TEXTURE_PATH: String = "res://assets/css/wisp.png"
@export var SECRET2_MOUNT_TEXTURE_PATH: String = "res://assets/css/maidmint.png"

# UI Faces Textures
@export var FACE_UI_TEXTURE: String = "res://assets/ui/ui_faces.png"
@export var EGGOON_FACE_RECT: String = var_to_str(Rect2(256, 0, 32, 32))
@export var NORMALGOON_FACE_RECT: String = var_to_str(Rect2(160, 0, 32, 32))
@export var CHONKGOON_FACE_RECT: String = var_to_str(Rect2(224, 0, 32, 32))
@export var LONGGOON_FACE_RECT: String = var_to_str(Rect2(192, 0, 32, 32))
@export var DAD_FACE_RECT: String = var_to_str(Rect2(128, 0, 32, 32))
@export var BHDOKI_FACE_RECT: String = var_to_str(Rect2(0, 0, 32, 32))
@export var RETRODOKI_FACE_RECT: String = var_to_str(Rect2(64, 0, 32, 32))
@export var ALTGIRLDOKI_FACE_RECT: String = var_to_str(Rect2(32, 0, 32, 32))
@export var CROWKI_FACE_RECT: String = var_to_str(Rect2(96, 0, 32, 32))
@export var TOMATODOKI_FACE_RECT: String = var_to_str(Rect2(288, 0, 32, 32))
@export var SECRET1_FACE_RECT: String = var_to_str(Rect2(320, 0, 32, 32))
@export var SECRET2_FACE_RECT: String = var_to_str(Rect2(352, 0, 32, 32))

# Character Dicts
var egggoon_paths = {
	"select": EGGOON_SELECT_TEXTURE_PATH, 
	"walk": EGGOON_PLAYER_TEXTURE_PATH, 
	"mount": EGGOON_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": EGGOON_FACE_RECT },
	}

var normalgoon_paths = {
	"select": NORMALGOON_SELECT_TEXTURE_PATH, 
	"walk": NORMALGOON_PLAYER_TEXTURE_PATH, 
	"mount": NORMALGOON_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": NORMALGOON_FACE_RECT },
	}
  
var chonkgoon_paths = {
	"select": CHONKGOON_SELECT_TEXTURE_PATH, 
	"walk": CHONKGOON_PLAYER_TEXTURE_PATH, 
	"mount": CHONKGOON_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": CHONKGOON_FACE_RECT },
	}
 
var longgoon_paths = {
	"select": LONGGOON_SELECT_TEXTURE_PATH, 
	"walk": LONGGOON_PLAYER_TEXTURE_PATH, 
	"mount": LONGGOON_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": LONGGOON_FACE_RECT },
	}
  
var dad_paths = {
	"select": DAD_SELECT_TEXTURE_PATH, 
	"walk": DAD_PLAYER_TEXTURE_PATH, 
	"mount": DAD_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": DAD_FACE_RECT },
	}
 
var bhdoki_paths = {
	"select": BHDOKI_SELECT_TEXTURE_PATH, 
	"walk": BHDOKI_PLAYER_TEXTURE_PATH, 
	"mount": BHDOKI_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": BHDOKI_FACE_RECT },
	}
  
var retrodoki_paths = {
	"select": RETRODOKI_SELECT_TEXTURE_PATH, 
	"walk": RETRODOKI_PLAYER_TEXTURE_PATH, 
	"mount": RETRODOKI_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": RETRODOKI_FACE_RECT },
	}
  
var altgirldoki_paths = {
	"select": ALTGIRLDOKI_SELECT_TEXTURE_PATH, 
	"walk": ALTGIRLDOKI_PLAYER_TEXTURE_PATH, 
	"mount": ALTGIRLDOKI_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": ALTGIRLDOKI_FACE_RECT },
	}
  
var crowki_paths = {
	"select": CROWKI_SELECT_TEXTURE_PATH, 
	"walk": CROWKI_PLAYER_TEXTURE_PATH, 
	"mount": CROWKI_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": CROWKI_FACE_RECT },
	}
  
var tomatodoki_paths = {
	"select": TOMATODOKI_SELECT_TEXTURE_PATH, 
	"walk": TOMATODOKI_PLAYER_TEXTURE_PATH, 
	"mount": TOMATODOKI_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": TOMATODOKI_FACE_RECT },
	}
  
var secretone_paths = {
	"select": SECRET1_SELECT_TEXTURE_PATH, 
	"walk": SECRET1_PLAYER_TEXTURE_PATH, 
	"mount": SECRET1_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": SECRET1_FACE_RECT },
	}
  
var secrettwo_paths = {
	"select": SECRET2_SELECT_TEXTURE_PATH, 
	"walk": SECRET2_PLAYER_TEXTURE_PATH, 
	"mount": SECRET2_MOUNT_TEXTURE_PATH,
	"face": { "path": FACE_UI_TEXTURE, "rect": SECRET2_FACE_RECT },
	}
	
var DEFAULT_PLAYER_2_SELECT = NORMALGOON_SELECT_TEXTURE_PATH
var DEFAULT_PLAYER_3_SELECT = CHONKGOON_SELECT_TEXTURE_PATH
var DEFAULT_PLAYER_4_SELECT = LONGGOON_SELECT_TEXTURE_PATH
