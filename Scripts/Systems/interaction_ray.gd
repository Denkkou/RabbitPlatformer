extends RayCast2D

export(Resource) onready var _runtime_data = _runtime_data as RuntimeData

func _input(event) -> void:
	var collided_area: Area2D = get_collider()
	
	if collided_area is InteractableNPC:
		if Input.is_action_just_pressed("interact") \
			and _runtime_data.current_gameplay_state == Enums.GameplayState.FREEWALK:
			GameEvents.emit_signal("interact_pressed", collided_area)
