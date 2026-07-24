class_name FatherAldric
extends NPCBase

func _ready() -> void:
	npc_name = "Father Aldric"
	robe_color = Color(0.1, 0.09, 0.11)
	trim_color = Color(0.55, 0.48, 0.2)
	super._ready()

func _get_dialogue_tree() -> Dictionary:
	return {
		"start": {
			"speaker": "Father Aldric",
			"line": "You crossed the gate. That should not have been possible for someone like you.",
			"choices": [
				{"text": "What do you mean, 'someone like me'?", "next": "boundary"},
				{"text": "Who are you?", "next": "who"},
				{"text": "I'm looking for the source of the bell.", "next": "bell"},
			]
		},
		"boundary": {
			"speaker": "Father Aldric",
			"line": "The Hollow chooses who may enter. It has not opened the gate to an outsider in a generation — until tonight.",
			"choices": [
				{"text": "What is this place, really?", "next": "place"},
				{"text": "I need to find the bell.", "next": "bell"},
			]
		},
		"who": {
			"speaker": "Father Aldric",
			"line": "Aldric. I keep what remains of this church — and what remains of the truth no one else will speak.",
			"choices": [
				{"text": "What truth?", "next": "place"},
				{"text": "I need to find the bell.", "next": "bell"},
			]
		},
		"place": {
			"speaker": "Father Aldric",
			"line": "Three bloodlines share this town under an old, uneasy truce. Vampires. Witches. Wolves. And beneath us, something older still is stirring.",
			"choices": [
				{"text": "Why did the bell ring tonight?", "next": "bell"},
			]
		},
		"bell": {
			"speaker": "Father Aldric",
			"line": "It rings on its own when the old wards weaken. Something has already slipped loose near the graveyard. Go — but be careful what you wake.",
			"choices": [
				{"text": "[End conversation]", "next": ""},
			]
		},
	}

func _on_dialogue_finished() -> void:
	GameManager.set_story_flag("met_aldric")

func fear_reaction() -> void:
	DialogueManager.say("Father Aldric", "By the old blood... what *are* you?", 3.5)
