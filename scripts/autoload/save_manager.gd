extends Node

const SAVE_PATH := "user://nightfall_save.json"

func save_game() -> bool:
	var player_position := Vector3.ZERO
	if is_instance_valid(PlayerManager.player):
		player_position = PlayerManager.player.global_position
	var data := {
		"player": PlayerManager.to_save_data(),
		"inventory": InventoryManager.to_save_data(),
		"quests": QuestManager.to_save_data(),
		"position": {"x": player_position.x, "y": player_position.y, "z": player_position.z}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	GameManager.notify("Game saved.")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		GameManager.notify("No save file found.")
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		GameManager.notify("Save file could not be read.")
		return false
	PlayerManager.apply_save_data(parsed.get("player", {}))
	InventoryManager.apply_save_data(parsed.get("inventory", {}))
	QuestManager.apply_save_data(parsed.get("quests", {}))
	if is_instance_valid(PlayerManager.player):
		var position_data: Dictionary = parsed.get("position", {})
		PlayerManager.player.global_position = Vector3(float(position_data.get("x", 0)), float(position_data.get("y", 1.2)), float(position_data.get("z", 8)))
	GameManager.notify("Game loaded.")
	return true
