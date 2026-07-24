class_name PlayerLocomotionState
extends State

var player: NightfallPlayer

func enter(previous: State) -> void:
	if player == null:
		player = machine.get_parent() as NightfallPlayer
	super.enter(previous)

func physics_process_state(delta: float) -> void:
	if player:
		player.update_locomotion(delta)
