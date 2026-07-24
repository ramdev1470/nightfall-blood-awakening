extends Node
## Lightweight branching dialogue tree.
## A tree is: { "node_id": { "speaker": String, "line": String,
##                            "choices": [ {"text": String, "next": String}, ... ],
##                            "on_enter": Callable (optional), "auto_close": bool (optional) } }

signal line_shown(speaker: String, line: String, choices: Array)
signal dialogue_ended

var is_open := false
var _tree: Dictionary = {}
var _current_id: String = ""
var _on_finish: Callable = Callable()

func start(tree: Dictionary, start_id: String, on_finish: Callable = Callable()) -> void:
	_tree = tree
	_on_finish = on_finish
	is_open = true
	GameManager.set_phase(GameManager.GamePhase.DIALOGUE)
	_show_node(start_id)

## Single non-branching auto-closing line — used for barks / reaction lines.
func say(speaker: String, line: String, duration: float = 3.2) -> void:
	is_open = true
	line_shown.emit(speaker, line, [])
	await get_tree().create_timer(duration).timeout
	if is_open:
		close()

func choose(index: int) -> void:
	var node: Dictionary = _tree.get(_current_id, {})
	var choices: Array = node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var next_id: String = choices[index].get("next", "")
	if next_id.is_empty():
		close()
	else:
		_show_node(next_id)

func _show_node(node_id: String) -> void:
	if not _tree.has(node_id):
		close()
		return
	_current_id = node_id
	var node: Dictionary = _tree[node_id]
	if node.has("on_enter"):
		(node["on_enter"] as Callable).call()
	line_shown.emit(node.get("speaker", ""), node.get("line", ""), node.get("choices", []))
	if node.get("auto_close", false):
		await get_tree().create_timer(3.4).timeout
		if is_open and _current_id == node_id:
			close()

func close() -> void:
	is_open = false
	_tree = {}
	_current_id = ""
	GameManager.set_phase(GameManager.GamePhase.EXPLORATION)
	dialogue_ended.emit()
	if _on_finish.is_valid():
		_on_finish.call()
		_on_finish = Callable()
