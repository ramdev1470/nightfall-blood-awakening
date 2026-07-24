extends Node

signal inventory_changed

var items: Dictionary = {"Healing Tonic": 2, "Town Map": 1}

func add_item(item_id: String, amount := 1) -> void:
	items[item_id] = int(items.get(item_id, 0)) + amount
	inventory_changed.emit()

func remove_item(item_id: String, amount := 1) -> bool:
	var available := int(items.get(item_id, 0))
	if available < amount:
		return false
	if available == amount:
		items.erase(item_id)
	else:
		items[item_id] = available - amount
	inventory_changed.emit()
	return true

func to_save_data() -> Dictionary:
	return items.duplicate()

func apply_save_data(data: Dictionary) -> void:
	items = data.duplicate()
	inventory_changed.emit()
