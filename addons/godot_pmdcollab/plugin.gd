@tool
extends EditorPlugin

var importer

func _enable_plugin() -> void:
	add_autoload_singleton("SpriteCollab", "res://addons/godot_pmdcollab/spritecollab.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("SpriteCollab")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	#add_custom_type("PC_AnimationPlayer", 'AnimationPlayer', preload("res://addons/godot_pmdcollab/src/scripts/anim_importer.gd"), preload("res://icon.svg"))
	#add_import_plugin()
	#add_custom_type("SCAnimationLibrary", "AnimationLibrary", preload("res://addons/godot_pmdcollab/sc_animation_library.gd"), preload("res://icon.svg"))
	importer = preload("res://addons/godot_pmdcollab/anim_importer.gd").new()
	add_import_plugin(importer)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	#remove_custom_type("PC_AnimationPlayer")
	#remove_custom_type("SCAnimationLibrary")
	remove_import_plugin(importer)
	importer = null
	pass
