#@icon()
extends AnimationLibrary
### SpriteCollab Animation Library
class_name SCAnimationLibrary

@export_storage var _animation_data: Dictionary[StringName, Dictionary] = {}

### In this case, SpriteCollab data.
func add_animation_with_data(name: StringName, animation: Animation, data: Dictionary):
	var errCode: Error = add_animation(name, animation)
	if errCode == Error.OK:		_animation_data[name] = data
	return errCode

func remove_animation(name: StringName):
	super.remove_animation(name)
	_animation_data.erase(name)

func get_animation_data(name: StringName):
	return _animation_data.get(name)
