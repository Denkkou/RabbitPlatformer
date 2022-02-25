extends KinematicBody2D
###################################
# To-Do's
# CORE
# Add delays to actions like jumping and ticking through dialogue
# Particle system to signify movement, landing and jumping
# Additional abilities such as dash, shield, double jump
# 	(Restrict current double jump)
#
# OPTIONAL
# Coyote time system - potentially identical to last OR new system
# Add a small raycast (?) to determine an early-jump when near floor
# Consider developing more animations and adding an animation tree
###################################

# player mechanic values
export(float) var _gravity = 400
export(float) var _max_fall_speed = 400
export(float) var _jump_strength = -175
export(float) var _double_jump_strength = -175
export(float) var _bounce_velocity = -100
export(float) var _max_move_speed = 75
export(float) var _dampening = 500
export(float) var _acceleration = 700
export(float) var _friction = 2000

# references
export(Resource) var _runtime_data = _runtime_data as RuntimeData
export(NodePath) onready var _animator = get_node(_animator) as AnimationPlayer
export(NodePath) onready var _sprite = get_node(_sprite) as Sprite
export(NodePath) onready var _raycast = get_node(_raycast) as RayCast2D

# public variables
# private variables
var _velocity: Vector2 = Vector2(0, 0)
var _can_double_jump: bool = false
var _started_fall: bool = false
var _squash_speed: float = 0.3
var _ray_length: int = 8


# built-in methods
func _physics_process(delta):
	if _runtime_data.current_gameplay_state == Enums.GameplayState.FREEWALK:
		# player control
		_handle_movement(delta)
		_handle_jump()
		
		# keep animations separate from game logic
		_handle_animations()
		
		# apply gravity
		_apply_gravity(delta)
		
		# apply all changes this frame, stop grav accumulation
		_velocity.y = move_and_slide(_velocity, Vector2.UP).y
		
		# handle player bouncing
		_handle_bounce()
		
	else:
		_pause_dialogue_animations()


# private methods
func _handle_movement(delta) -> void:
	# push down if hitting head
	if is_on_ceiling():
		_velocity.y = 10
	
	if Input.is_action_pressed("move_right"):
		# slide when turning at top speed
		if _velocity.x < -_max_move_speed:
			_velocity.x += _dampening * delta
		# speed up when not at top speed
		elif _velocity.x < _max_move_speed:
			_velocity.x += _acceleration * delta 
	elif Input.is_action_pressed("move_left"):
		if _velocity.x > _max_move_speed:
			_velocity.x -= _dampening * delta
		elif _velocity.x > -_max_move_speed:
			_velocity.x -= _acceleration * delta
	else:
		_velocity.x -= min(abs(_velocity.x), _friction * delta) \
			* sign(_velocity.x)


func _handle_jump() -> void:
	if is_on_floor():
		# initial jump
		if Input.is_action_just_pressed("jump"):
			_velocity.y = _jump_strength
			_can_double_jump = true
	else:
		# variable jump
		if _velocity.y < 0 and not Input.is_action_pressed("jump"):
			_velocity.y = max(_velocity.y, _jump_strength / 2)
			
		# double jump
		if Input.is_action_just_pressed("jump") and _can_double_jump:
			_velocity.y = _double_jump_strength
			_can_double_jump = false


func _handle_bounce():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var collider = collision.collider
		var is_stomping = (
			collider is Enemy and
			is_on_floor() and
			collision.normal.is_equal_approx(Vector2.UP)
		)
		
		if is_stomping:
			_velocity.y = _bounce_velocity
			(collider as Enemy).die()


func _apply_gravity(delta) -> void:
	_velocity.y += _gravity * delta
	_velocity.y = min(_velocity.y, _max_fall_speed)


# potentially replace later with animation tree
func _handle_animations() -> void:
	# idle animation
	if _velocity == Vector2.ZERO:
		_animator.play("IDLE")
	
	# moving right or left
	if _velocity.x > 0 and Input.is_action_pressed("move_right"):
		_sprite.set_flip_h(false)
		_raycast.set_cast_to(Vector2(_ray_length, 0))
		if is_on_floor():
			_animator.play("RUNNING")
	
	if _velocity.x < 0 and Input.is_action_pressed("move_left"):
		_sprite.set_flip_h(true)
		_raycast.set_cast_to(Vector2(-_ray_length, 0))
		if is_on_floor():
			_animator.play("RUNNING")
	
	# jumping
	if Input.is_action_just_pressed("jump"):
		_animator.play("JUMPING")
	
	# handle falling using a flag to prevent looping
	if _started_fall == false and _velocity.y > 0:
		_started_fall = true
		_animator.play("FALLING")
	elif is_on_floor():
		# needs a fix to handle falling after double jump
		_started_fall = false


func _pause_dialogue_animations() -> void:
	if _runtime_data.current_gameplay_state == Enums.GameplayState.IN_DIALOGUE:
		_animator.stop(false)
	else:
		_animator.play()


# sprite deformation effects [UNUSED]
func _squash_effect() -> void:
	_sprite.scale = Vector2(1.2, 0.8)
func _stretch_effect() -> void:
	_sprite.scale = Vector2(1.2, 0.6)
func _undeform_sprite() -> void:
	_sprite.scale.x = lerp(_sprite.scale.x, 1, _squash_speed)
	_sprite.scale.y = lerp(_sprite.scale.y, 1, _squash_speed)
