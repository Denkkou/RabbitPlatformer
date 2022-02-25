extends Node

signal dialogue_initiated(dialogue)
signal dialogue_finished

signal interact_pressed

func emit_dialogue_initiated(dialogue: Dialogue) -> void:
	call_deferred("emit_signal", "dialogue_initiated", dialogue)

func emit_dialogue_finished() -> void:
	call_deferred("emit_signal", "dialogue_finished")
