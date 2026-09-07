@tool
extends CharacterBody3D

class_name Actor
var _setup_finished: bool = false
var _monster_id: int = 0
@export var monster_id: int = 0:
	get:
		return _monster_id
	set(val):
		_update_monster_id(val)
"""@export var monster_id: int = 0:
	get:
		return _monster_id
	set(val):
		_update_monster_id(val)"""
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite3D = $Sprite
@onready var name_label: Label3D = $NameLabel

var anim_data: AnimationLibrary
var _current_spritesheet: StringName
var _mon: Monster

func _ready() -> void:
	_mon = MonRegistry.get_monster(monster_id)
	if _mon == null:
		printerr("Monster with id %04d doesn't exist! Aborting actor setup." % monster_id)
		return
	_update_animation_library()
	_set_spritesheet(&"Walk")
	_update_name()
	_setup_finished = true

func _update_monster_id(id: int) -> bool:
	var newMon = MonRegistry.get_monster(id)
	if newMon == null:
		push_error("_update_monster_id: couldn't get new monster")
		return false
	_mon = newMon
	_monster_id = id
	if not _setup_finished:
		print("setup not finished")
		return false
	_update_animation_library()
	_set_spritesheet(&"Walk")
	_update_name()
	return true

func _update_name():
	name_label.text = _mon.name

func _set_spritesheet(p_name: StringName):
	sprite.texture = _mon.get_spritesheet(p_name)
	var dim = SpriteCollab.get_index_dimensions_for_spritesheet(p_name, sprite.texture, anim_data)
	sprite.hframes = dim.x
	sprite.vframes = dim.y
	_current_spritesheet = name

# NOTE: this only has to be called if somehow, the monster changes to another
func _update_animation_library():
	anim_data = _mon.get_animdata()
	if anim_data == null:
		push_error("anim_data is null??")
	if animation_player.has_animation_library(&"AnimData"):
		#print("removing existing animation lib")
		animation_player.remove_animation_library(&"AnimData")
	animation_player.add_animation_library(&"AnimData", anim_data)

func play_animation(a_name: StringName):
	if _current_spritesheet != a_name:
		_set_spritesheet(a_name)
	animation_player.play("AnimData/" + a_name)

func stop_animation(keep_state: bool):
	animation_player.stop(keep_state)

func pause_animation():
	animation_player.pause()

func set_direction(dir: SpriteCollab.SpriteDirection):
	sprite.frame_coords.y = dir
