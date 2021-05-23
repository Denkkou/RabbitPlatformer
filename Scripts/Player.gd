extends KinematicBody2D

#attached nodes
onready var animatedSprite = $AnimatedSprite

#particles
export(PackedScene) var stepDust
export(PackedScene) var jumpDust
export(PackedScene) var fallDust
export(PackedScene) var turnDust
var hasAlreadyEmitted = false

#modifiable values
export(int) var gravity = 400
export(int) var acceleration = 700
export(int) var deceleration = 500
export(int) var friction = 2000
export(int) var currentFriction = 2000
export(int) var maxHorizontalSpeed = 100
export(int) var maxFallSpeed = 400
export(int) var jumpHeight = -175
export(int) var doubleJumpHeight = -150
export(float) var squashSpeed = 0.3

#states
enum {IS_GROUNDED, IS_AGAINST_WALL, IS_JUMPING, IS_DOUBLE_JUMPING, CAN_DOUBLE_JUMP, DOUBLE_JUMP_PRESSED, COYOTE_TIME}
var state = [false, false, false, false, false, false, false]

var playerSpeed = Vector2(0, 0)
var motion = Vector2.ZERO

#unlocked ability flags
var unlocked_DoubleJump : bool = true
var unlocked_FastFall : bool = true
#var unlocked_Dash : bool = false

func _ready():
	pass

#runs every frame at 60fps
func _physics_process(delta):
	CheckGrounding()
	PlayerInput(delta)
	HandleParticles()
	ApplyPhysics(delta)

#handle player grounding
func CheckGrounding():
	#check for coyote time on ground exit
	if(state[IS_GROUNDED] && !is_on_floor()):
		state[IS_GROUNDED] = false
		state[COYOTE_TIME] = true
		yield(get_tree().create_timer(0.2), "timeout")
		state[COYOTE_TIME] = false
	
	#squash effect when landing
	if(!state[IS_GROUNDED] && is_on_floor()):
		animatedSprite.scale = Vector2(1.2, 0.8)
	
	#set grounding appropriately
	state[IS_GROUNDED] = is_on_floor()
	
	if(state[IS_GROUNDED]):
		state[IS_JUMPING] = false
		state[CAN_DOUBLE_JUMP] = true
		motion.y = 0
		playerSpeed.y = 0

#handle player input
func PlayerInput(delta):
	PlayerInputMovement(delta)
	PlayerInputJump(delta)

#handle player movement inputs
func PlayerInputMovement(delta):
	#RIGHT MOVEMENT
	if(Input.get_joy_axis(0, 0) > 0.3) || Input.is_action_pressed("userRight"):
		if(playerSpeed.x < -100):
			playerSpeed.x += deceleration * delta
			if(state[IS_GROUNDED]): pass #animatedSprite.play("TURN")
		elif(playerSpeed.x < maxHorizontalSpeed):
			playerSpeed.x += acceleration * delta
			animatedSprite.flip_h = false
			if(state[IS_GROUNDED]): animatedSprite.play("RUN")
		else:
			if(state[IS_GROUNDED]): animatedSprite.play("RUN")
	#LEFT MOVEMENT
	elif(Input.get_joy_axis(0, 0) < -0.3) || Input.is_action_pressed("userLeft"):
		if(playerSpeed.x > 100):
			playerSpeed.x -= deceleration * delta
			if(state[IS_GROUNDED]): pass #animatedSprite.play("TURN")
		elif(playerSpeed.x > -maxHorizontalSpeed):
			playerSpeed.x -= acceleration * delta
			animatedSprite.flip_h = true
			if(state[IS_GROUNDED]): animatedSprite.play("RUN")
		else:
			if(state[IS_GROUNDED]): animatedSprite.play("RUN")
	#ALL MOVEMENT STOPPED
	else:
		if(state[IS_GROUNDED]): animatedSprite.play("IDLE")
			
		#gradual slowdown
		playerSpeed.x -= min(abs(playerSpeed.x), currentFriction * delta) * sign(playerSpeed.x)

#handle player jump inputs
func PlayerInputJump(delta):
	if(state[COYOTE_TIME] && Input.is_action_just_pressed("userJump")):
		playerSpeed.y = jumpHeight
		state[IS_JUMPING] = true
		state[CAN_DOUBLE_JUMP] = true
	
	#jump logic
	if(state[IS_GROUNDED]):
		if((Input.is_action_just_pressed("userJump") || state[DOUBLE_JUMP_PRESSED]) && !state[IS_JUMPING]):
			playerSpeed.y = jumpHeight
			state[IS_JUMPING] = true
			state[IS_GROUNDED] = false
			animatedSprite.scale = Vector2(0.5, 1.2) #stretch on jump
			hasAlreadyEmitted = false
	else: 
		#variable jump height
		if(playerSpeed.y < 0 && !Input.is_action_pressed("userJump") && !state[IS_DOUBLE_JUMPING]):
			playerSpeed.y = max(playerSpeed.y, jumpHeight / 2)
		
		#double jump
		if(unlocked_DoubleJump && state[CAN_DOUBLE_JUMP] && Input.is_action_just_pressed("userJump") && !state[COYOTE_TIME]):
			playerSpeed.y = doubleJumpHeight
			animatedSprite.play("DOUBLEJUMP")
			state[IS_DOUBLE_JUMPING] = true
			state[CAN_DOUBLE_JUMP] = false
			animatedSprite.scale = Vector2(0.7, 1.1) #stretch on jump
		
		#animation logic
		if(!state[IS_DOUBLE_JUMPING] && playerSpeed.y < 0): animatedSprite.play("JUMPUP") #if rising
		elif(!state[IS_DOUBLE_JUMPING] && playerSpeed.y > 0): animatedSprite.play("JUMPDOWN") #if falling
		elif(state[IS_DOUBLE_JUMPING]): #&& animatedSprite.frame == 3
			state[IS_DOUBLE_JUMPING] = false
		
		if(Input.is_action_just_pressed("userJump")):
			state[DOUBLE_JUMP_PRESSED] = true
			yield(get_tree().create_timer(0.2), "timeout")
			state[DOUBLE_JUMP_PRESSED] = false
		
		#fast fall
		if(unlocked_FastFall && !state[IS_GROUNDED] && Input.is_action_pressed("userDown")):
			playerSpeed.y += (gravity * 1.1) * delta

#apply physics calculations to player
func ApplyPhysics(delta):
	#bounce down if hit ceiling
	if(is_on_ceiling()):
		motion.y = 10
		playerSpeed.y = 10
	
	#apply gravity and limit fall speed
	playerSpeed.y += gravity * delta
	playerSpeed.y = min(playerSpeed.y, maxFallSpeed)
	
	#update motion vector
	motion.y = playerSpeed.y
	motion.x = playerSpeed.x
	
	#apply motion
	motion = move_and_slide(motion, Vector2.UP)
	
	#lerp squash effect
	SquashEffect()

#return player to normal scale
func SquashEffect():
	animatedSprite.scale.x = lerp(animatedSprite.scale.x, 1, squashSpeed)
	animatedSprite.scale.y = lerp(animatedSprite.scale.y, 1, squashSpeed)
	pass

func HandleParticles():
	#running dust
	if(animatedSprite.animation == "RUN"):
		if(animatedSprite.frame == 0 && !hasAlreadyEmitted):
			EmitRunParticle()
		elif(animatedSprite.frame != 0):
			hasAlreadyEmitted = false
	
	#landing from heights dust (proportional to fallspeed)
	
	#turning at speed dust
	
	#jump and double jump dust

func EmitRunParticle():
	#calculate offset
	var particleOffset = 0
	if(motion.x < 0): particleOffset = 2 #moving left
	elif(motion.x > 0): particleOffset = -2 #moving right
	else: particleOffset = 0 #not moving
	
	#instantiate dust
	var stepInst = stepDust.instance()
	stepInst.emitting = true
	stepInst.global_position = Vector2(global_position.x + particleOffset, global_position.y)
	get_parent().add_child(stepInst)
	hasAlreadyEmitted = true
