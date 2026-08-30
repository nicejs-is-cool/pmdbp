extends Node

const PORTRAIT_SIZE = Vector2i(40, 40)
const SPRITESHEET_INDEX_SIZE = Vector2i(5, 8)
const ASYMMETRICAL_PORTRAITS_START = Vector2i(4, 0)

enum Portrait {
	NORMAL,
	HAPPY,
	PAIN,
	ANGRY,
	WORRIED,
	SAD,
	CRYING,
	SHOUTING,
	TEARY_EYED,
	DETERMINED,
	JOYOUS,
	INSPIRED,
	SURPRISED,
	DIZZY,
	SPECIAL0,
	SPECIAL1,
	SIGH,
	STUNNED,
	SPECIAL2,
	SPECIAL3,
}
enum SpriteDirection {
	SOUTH,
	SOUTHEAST,
	EAST,
	NORTHEAST,
	NORTH,
	NORTHWEST,
	WEST
}

func vec2i_to_index(vec: Vector2i) -> int:
	return (vec.x * SPRITESHEET_INDEX_SIZE.x) + (vec.y * SPRITESHEET_INDEX_SIZE.y)

# assumes a SC spritesheet
func get_portrait_dimensions(index: int) -> Rect2i:
	var indexVec = Vector2i(index % SPRITESHEET_INDEX_SIZE.x, index / SPRITESHEET_INDEX_SIZE.x)
	#print("indexVec=",indexVec)
	return Rect2i(indexVec*PORTRAIT_SIZE, PORTRAIT_SIZE)

func get_portrait_from_texture(texture: Texture2D, index: int) -> AtlasTexture:
	var rect = get_portrait_dimensions(index)
	var text = AtlasTexture.new()
	text.atlas = texture
	text.region = rect
	return text

func asym_portrait(index: int) -> int:
	return index + vec2i_to_index(ASYMMETRICAL_PORTRAITS_START)

# doing it this way to avoid allocations
func get_index_dimensions_for_spritesheet(ss_name: StringName, spritesheet: Texture2D, animlib: AnimationLibrary):
	var anim = animlib.get_animation(ss_name)
	if anim == null:
		return null
	var data: Dictionary = anim.get_meta(&"spritecollab_data")
	if data == null:
		return null
	var frameWidth: int = data.frameWidth
	var frameHeight: int = data.frameHeight
	# quick 'n dirty
	return Vector2i(spritesheet.get_width() / frameWidth, spritesheet.get_height() / frameHeight)
