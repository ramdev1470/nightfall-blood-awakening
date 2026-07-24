class_name State
extends Node

## Reusable state contract. A state does work; its parent machine owns transitions.
var machine: StateMachine

func enter(_previous: State) -> void:
	pass

func exit() -> void:
	pass

func process_state(_delta: float) -> void:
	pass

func physics_process_state(_delta: float) -> void:
	pass
