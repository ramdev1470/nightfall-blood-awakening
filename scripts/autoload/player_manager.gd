extends Node

signal stats_changed
signal race_changed(race: String)
signal died
signal blood_surge_activated

var player: NightfallPlayer
var race := "Human"
var level := 1
var experience := 0
var gold := 15
var humanity := 50
var corruption := 0
var health := 100.0
var max_health := 100.0
var mana := 60.0
var max_mana := 60.0
var is_dead := false

func set_health(value: float) -> void:
	if is_dead:
		return
	health = clampf(value, 0.0, max_health)
	stats_changed.emit()
	if health <= 0.0 and not is_dead:
		is_dead = true
		died.emit()

func set_mana(value: float) -> void:
	mana = clampf(value, 0.0, max_mana)
	stats_changed.emit()

func set_race(value: String) -> void:
	race = value
	race_changed.emit(race)

func trigger_blood_surge() -> void:
	blood_surge_activated.emit()

func reset_for_new_chapter() -> void:
	is_dead = false
	health = max_health
	mana = max_mana

func to_save_data() -> Dictionary:
	return {"race": race, "level": level, "experience": experience, "gold": gold, "humanity": humanity, "corruption": corruption, "health": health, "mana": mana}

func apply_save_data(data: Dictionary) -> void:
	race = str(data.get("race", "Human"))
	level = int(data.get("level", 1))
	experience = int(data.get("experience", 0))
	gold = int(data.get("gold", 15))
	humanity = int(data.get("humanity", 50))
	corruption = int(data.get("corruption", 0))
	set_health(float(data.get("health", max_health)))
	set_mana(float(data.get("mana", max_mana)))
