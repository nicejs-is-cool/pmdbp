extends Node
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play("Move")

func _process(_delta: float):
	pass
