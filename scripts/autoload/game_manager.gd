extends Node

signal game_started
signal notification_requested(message: String)
signal objective_requested(text: String)
signal story_flag_set(flag: String)

enum GamePhase { OPENING, EXPLORATION, DIALOGUE, COMBAT, CUTSCENE, PAUSED }
var phase := GamePhase.OPENING
var story_flags: Dictionary = {}

func _ready() -> void:
	game_started.emit()

func set_phase(next_phase: GamePhase) -> void:
	phase = next_phase

func notify(message: String) -> void:
	notification_requested.emit(message)

func set_objective(text: String) -> void:
	objective_requested.emit(text)

func set_story_flag(flag: String) -> void:
	if story_flags.has(flag):
		return
	story_flags[flag] = true
	story_flag_set.emit(flag)

func has_story_flag(flag: String) -> bool:
	return story_flags.has(flag)
