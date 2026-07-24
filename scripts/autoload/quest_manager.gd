extends Node

signal quest_updated(quest_id: String)

var quests: Dictionary = {
	"arrival": {"title": "The Hollow Has Chosen", "objective": "Find the bell tower in the town square.", "state": "active"}
}

func set_quest_state(quest_id: String, state: String, objective := "") -> void:
	if not quests.has(quest_id):
		quests[quest_id] = {"title": quest_id.capitalize(), "objective": objective, "state": state}
	else:
		quests[quest_id].state = state
		if not objective.is_empty():
			quests[quest_id].objective = objective
	quest_updated.emit(quest_id)

func active_quest() -> Dictionary:
	for quest in quests.values():
		if quest.state == "active":
			return quest
	return {}

func to_save_data() -> Dictionary:
	return quests.duplicate(true)

func apply_save_data(data: Dictionary) -> void:
	quests = data.duplicate(true)
