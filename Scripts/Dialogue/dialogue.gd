extends Resource

# Template of a Dialogue Resource Object
class_name Dialogue

export(Texture) var avatar_texture
export(String) var speaker_name
export(Array, String, MULTILINE) var dialogue_slides
