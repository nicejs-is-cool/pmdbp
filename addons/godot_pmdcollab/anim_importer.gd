@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "pmdcollab.animdata.xml.importer"

func _get_visible_name() -> String:
	return "SpriteCollab Animation Data"

func _get_recognized_extensions() -> PackedStringArray:
	return ["xml"]

func _get_save_extension() -> String:
	return "tres"

func _get_resource_type() -> String:
	return "AnimationLibrary"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [] # todo

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var anims = AXP.load_anxml(source_file)
	if anims == null:
		return Error.FAILED
	# TODO: spritecollab/shadowsize metadata
	var lib = AnimationLibrary.new()
	for animationRaw in anims.animations:
		var animationData = AXP.get_animation(anims, animationRaw.name)
		if animationData == null:
			printerr("animationData is null for %s, wtf?" % animationRaw.name)
			continue
		var animationGD = AXP.animation_to_gd(animationData)
		if animationGD == null:
			printerr("failed to convert animationData to a Godot Animation for %s" % animationData.name)
			continue
		animationGD.set_meta("spritecollab_data", animationRaw)
		lib.add_animation(animationData.name, animationGD) # todo: err check
	return ResourceSaver.save(lib, "%s.%s" % [save_path, _get_save_extension()])
