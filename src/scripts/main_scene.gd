extends Node
@onready var player: Actor = $Player
@onready var portrait: TextureRect = $UI/Portrait

func _ready():
	#player.play_animation(&"Walk")
	#player.set_direction(SpriteCollab.SpriteDirection.NORTH)
	var ptxt = MonRegistry.get_monster(player.monster_id).get_portrait(SpriteCollab.Portrait.HAPPY)
	portrait.texture = ptxt
func _process(_delta: float):
	pass
