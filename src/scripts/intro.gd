extends Node
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.play(&"move")
	pass

func _process(_delta: float):
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"move":
		get_tree().change_scene_to_file("res://src/scenes/main.tscn")
