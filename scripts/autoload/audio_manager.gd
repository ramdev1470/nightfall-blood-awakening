extends Node
## Procedural audio. Every sound in this game is synthesized at runtime so the
## project never references a missing sound file.

const MIX_RATE := 22050.0

var master_volume := 0.85
var _players: Array[AudioStreamPlayer] = []
var _player_cursor := 0
const POOL_SIZE := 8

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func _next_player() -> AudioStreamPlayer:
	var p := _players[_player_cursor]
	_player_cursor = (_player_cursor + 1) % _players.size()
	return p

## Generic decaying-tone synth. freq in Hz, duration in seconds.
func _make_tone(freq: float, duration: float, wave: String = "sine", decay: float = 3.0, noise_mix: float = 0.0) -> AudioStreamWAV:
	var frame_count := int(MIX_RATE * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq * 997)
	for i in frame_count:
		var t := float(i) / MIX_RATE
		var envelope := exp(-decay * t)
		var sample := 0.0
		match wave:
			"sine":
				sample = sin(TAU * freq * t)
			"square":
				sample = sign(sin(TAU * freq * t))
			"saw":
				sample = 2.0 * (freq * t - floor(freq * t + 0.5))
		if noise_mix > 0.0:
			sample = lerp(sample, rng.randf_range(-1.0, 1.0), noise_mix)
		sample *= envelope
		var v := int(clampf(sample, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	stream.data = bytes
	return stream

func _play(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_variance: float = 0.0) -> void:
	var p := _next_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	p.play()

func play_bell() -> void:
	_play(_make_tone(196.0, 3.2, "sine", 0.9), -2.0)
	_play(_make_tone(392.0, 2.4, "sine", 1.4), -8.0)

func play_footstep() -> void:
	_play(_make_tone(90.0, 0.09, "sine", 24.0, 0.5), -14.0, 0.08)

func play_hit() -> void:
	_play(_make_tone(140.0, 0.18, "square", 14.0, 0.65), -6.0, 0.1)

func play_swing() -> void:
	_play(_make_tone(320.0, 0.12, "saw", 18.0, 0.3), -10.0, 0.15)

func play_growl() -> void:
	_play(_make_tone(70.0, 0.6, "saw", 3.5, 0.55), -6.0, 0.05)

func play_power() -> void:
	_play(_make_tone(220.0, 1.4, "sine", 1.2), -4.0)
	_play(_make_tone(660.0, 1.1, "sine", 1.8), -10.0)

func play_ui() -> void:
	_play(_make_tone(660.0, 0.08, "sine", 20.0), -8.0)

func play_death() -> void:
	_play(_make_tone(160.0, 1.6, "saw", 1.6, 0.2), -4.0)
