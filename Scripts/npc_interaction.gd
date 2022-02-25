extends Area2D

class_name InteractableNPC

export(Resource) var _dialogue = _dialogue as Dialogue


func _ready():
	GameEvents.connect("interact_pressed", self, "_on_interact")


func _on_DialogueTrigger_body_entered(body):
	print("NPC Body entered")


func _on_interact(interacted_npc: InteractableNPC):
	if interacted_npc == self:
		GameEvents.emit_dialogue_initiated(_dialogue)
