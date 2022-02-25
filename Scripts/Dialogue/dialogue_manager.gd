extends Control

# load as NodePath, onready store target node as appropriate
export(NodePath) onready var _dialogue_text = get_node(_dialogue_text) as Label
export(NodePath) onready var _avatar = get_node(_avatar) as TextureRect
export(NodePath) onready var _speaker_name = get_node(_speaker_name) as Label

# doesn't require onready as doesn't need scene tree to be populated first
export(Resource) var _current_dialogue = _current_dialogue as Dialogue
export(Resource) var _runtime_data = _runtime_data as RuntimeData

var _current_slide_index: int = 0

func _ready() -> void:
	# access data from current dialogue resource
	_avatar.texture = _current_dialogue.avatar_texture
	_speaker_name.text = _current_dialogue.speaker_name
	show_slide()
	
	# listen for dialogue signal
	GameEvents.connect("dialogue_initiated", self, "_on_dialogue_initiated")
	GameEvents.connect("dialogue_finished", self, "_on_dialogue_finished")


func _input(event) -> void:
	# advance dialogue on click
	if Input.is_action_just_pressed("interact"):
		# prevent out of bounds
		if _current_slide_index < _current_dialogue.dialogue_slides.size() - 1:
			_current_slide_index += 1
			show_slide()
		elif _runtime_data.current_gameplay_state == Enums.GameplayState.IN_DIALOGUE:
			GameEvents.emit_dialogue_finished()


func show_slide() -> void:
	_dialogue_text.text = _current_dialogue.dialogue_slides[_current_slide_index]


# simply receives dialogue emitted and shows it
func _on_dialogue_initiated(dialogue: Dialogue) -> void:
	_runtime_data.current_gameplay_state = Enums.GameplayState.IN_DIALOGUE
	_current_dialogue = dialogue
	_current_slide_index = 0
	_avatar.texture = dialogue.avatar_texture
	_speaker_name.text = _current_dialogue.speaker_name
	show_slide()
	self.visible = true


func _on_dialogue_finished() -> void:
	_runtime_data.current_gameplay_state = Enums.GameplayState.FREEWALK
	self.visible = false
