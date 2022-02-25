extends KinematicBody2D
class_name Enemy

# quick prototype enemy script
var _velocity = Vector2.ZERO
var _gravity = 400

func _ready():
	pass


func _physics_process(delta):
	_velocity.y += _gravity * delta
	move_and_slide(_velocity, Vector2.UP)


func die() -> void:
	queue_free()
