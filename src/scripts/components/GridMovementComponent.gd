class_name GridMovementComponent extends Node

@export var grid_dimensions: Vector2
@export var actor: Actor: # i wonder if this counts as a cyclical ref
	set(value):
		actor = value
		if actor != null: update_position()
@export var position: Vector2:
	set(value):
		position = value
		if actor != null: update_position()
@export var spacing: int = 1

func _ready() -> void:
	#update_position()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_real_position() -> Vector3:
	var realPosition = position * spacing
	print(realPosition)
	return Vector3(realPosition.x, 0, realPosition.y)

func update_position() -> void:
	actor.position = get_real_position()
