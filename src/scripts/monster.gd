extends Resource

class_name Monster

# id is set at runtime by the registry, when everything is loaded up
var id: int
@export var name: StringName

func _get_path(p: String) -> String:
	return "res://src/assets/monster/%04d/%s" % [id, p]

func get_spritesheet(ss_name: StringName) -> Texture2D:
	return load(_get_path("sprites/%s-Anim.png" % ss_name))

func get_animdata():
	return load(_get_path("sprites/AnimData.xml"))

func get_portraits_texture():
	return load(_get_path("portrait_atlas.png"))

func get_portrait(index: int) -> AtlasTexture:
	return SpriteCollab.get_portrait_from_texture(get_portraits_texture(), index)
