class_name Grid2D extends Resource

@export var _array: PackedByteArray
@export var width: int
@export var height: int

func _init(width: int, height: int) -> void:
	_array = PackedByteArray()
	_array.resize(width * height)
	self.width = width
	self.height = height

func is_valid_position(x: int, y: int) -> bool:
	return x > -1 and x < self.width and y > -1 and y < self.height

func index_pos(x: int, y: int) -> int:
	return (clamp(y, 0, self.height)*self.height) + clamp(x, 0, self.width)

func get_pos(x: int, y: int) -> int:
	return _array[index_pos(x, y)]

func set_pos(x: int, y: int, value: int) -> bool:
	if not is_valid_position(x, y): return false
	if value > 255: return false # need to check if its signed or unsigned
	_array[index_pos(x, y)] = value
	return true
