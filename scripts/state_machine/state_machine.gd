class_name StateMachine
extends Node

signal state_changed(previous: State, current: State)

@export var initial_state: NodePath
var current_state: State

func _ready() -> void:
	for child in get_children():
		if child is State:
			child.machine = self
	current_state = get_node_or_null(initial_state) as State
	if current_state:
		current_state.enter(null)

func _process(delta: float) -> void:
	if current_state:
		current_state.process_state(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process_state(delta)

func transition_to(next_state: State) -> void:
	if next_state == null or next_state == current_state:
		return
	var previous := current_state
	if current_state:
		current_state.exit()
	current_state = next_state
	current_state.enter(previous)
	state_changed.emit(previous, current_state)
