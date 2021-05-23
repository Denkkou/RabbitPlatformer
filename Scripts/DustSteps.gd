extends Particles2D

#after 2 sec delete instance
func _ready():
	yield(get_tree().create_timer(2), "timeout")
	queue_free()
