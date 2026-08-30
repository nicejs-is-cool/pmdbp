extends Node

# does godot have like, ANY kind of weak dictionary

func _check_if_mon_exists(id: int) -> bool:
	return DirAccess.dir_exists_absolute("res://src/assets/monster/%04d" % id) and FileAccess.file_exists("res://src/assets/monster/%04d/data.tres" % id)

func get_monster(id: int): # TODO: better error checking, it wont warn you if the data.tres is missing
	if not _check_if_mon_exists(id):
		return null
	var mon: Monster = load("res://src/assets/monster/%04d/data.tres" % id)
	mon.id = id
	#mon.set_id(id)
	return mon
