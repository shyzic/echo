extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 8
var ambient_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}

const SAMPLE_RATE := 22050

func _ready() -> void:
	for i in sfx_pool_size:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.volume_db = -18.0
	add_child(ambient_player)
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -10.0
	add_child(bgm_player)
	
	_build_sfx_table()

func _find_audio_file(base_path: String) -> String:
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(base_path + ext):
			return base_path + ext
	return ""

func _build_sfx_table() -> void:
	# First try to load real files, fall back to generated beeps
	var file_map := {
		"pickup":    "res://assets/audio/sfx/pickup",
		"anchor":    "res://assets/audio/sfx/anchor",
		"shift":     "res://assets/audio/sfx/shift",
		"ping":      "res://assets/audio/sfx/ping",
		"death":     "res://assets/audio/sfx/death",
		"switch":    "res://assets/audio/sfx/switch",
		"door":      "res://assets/audio/sfx/door",
		"heartbeat": "res://assets/audio/sfx/heartbeat",
		"footstep":  "res://assets/audio/sfx/footstep",
		"dialogue":  "res://assets/audio/sfx/dialogue",
		"menu":      "res://assets/audio/music/menu",
	}
	for key in file_map:
		var path = _find_audio_file(file_map[key])
		if path != "":
			sfx_streams[key] = load(path)

	# Generated fallbacks for any missing sounds
	if not sfx_streams.has("pickup"):
		sfx_streams["pickup"]    = _make_beep(880.0, 0.15)
	if not sfx_streams.has("anchor"):
		sfx_streams["anchor"]    = _make_tone_pair(528.0, 660.0, 0.35)
	if not sfx_streams.has("shift"):
		sfx_streams["shift"]     = _make_sweep(600.0, 250.0, 0.4)
	if not sfx_streams.has("ping"):
		sfx_streams["ping"]      = _make_beep(1400.0, 0.18)
	if not sfx_streams.has("death"):
		sfx_streams["death"]     = _make_sweep(300.0, 80.0, 0.8)
	if not sfx_streams.has("switch"):
		sfx_streams["switch"]    = _make_beep(2000.0, 0.07)
	if not sfx_streams.has("door"):
		sfx_streams["door"]      = _make_sweep(180.0, 120.0, 0.5)
	if not sfx_streams.has("heartbeat"):
		sfx_streams["heartbeat"] = _make_beep(90.0, 0.25)

func play(name: String) -> void:
	var stream = sfx_streams.get(name, null)
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

func play_bgm(name: String) -> void:
	var stream = sfx_streams.get(name, null)
	if stream != null and bgm_player.stream != stream:
		bgm_player.stream = stream
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_ambient(reality: int) -> void:
	# Try real files first (.ogg, .mp3, .wav)
	var base_path := "res://assets/audio/ambient/%s" % ("light" if reality == 0 else "echo")
	var path := _find_audio_file(base_path)
	if path != "":
		var s = load(path)
		if ambient_player.stream != s:
			ambient_player.stream = s
			ambient_player.play()
		return
	# Generated ambient drone
	var freq := 220.0 if reality == 0 else 110.0
	var drone := _make_drone(freq, 3.0, reality == 1)
	drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	drone.loop_begin = 0
	drone.loop_end = drone.data.size() / 2
	if not ambient_player.playing:
		ambient_player.stream = drone
		ambient_player.play()

# --- Sound generators ---

static func _make_beep(freq: float, duration: float, vol: float = 0.45) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - (t / duration)  # linear fade out
		var s := int(sin(TAU * freq * t) * vol * env * 32767)
		s = clampi(s, -32768, 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format    = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate  = SAMPLE_RATE
	wav.stereo    = false
	wav.data      = data
	return wav

static func _make_sweep(freq_start: float, freq_end: float, duration: float, vol: float = 0.4) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var progress := t / duration
		var freq := lerpf(freq_start, freq_end, progress)
		var env := 1.0 - progress * 0.7
		phase += TAU * freq / SAMPLE_RATE
		var s := int(sin(phase) * vol * env * 32767)
		s = clampi(s, -32768, 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format    = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate  = SAMPLE_RATE
	wav.stereo    = false
	wav.data      = data
	return wav

static func _make_tone_pair(freq1: float, freq2: float, duration: float, vol: float = 0.35) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var env := 1.0 - (t / duration) * 0.8
		var s := int((sin(TAU * freq1 * t) + sin(TAU * freq2 * t)) * 0.5 * vol * env * 32767)
		s = clampi(s, -32768, 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format    = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate  = SAMPLE_RATE
	wav.stereo    = false
	wav.data      = data
	return wav

static func _make_drone(freq: float, duration: float, eerie: bool, vol: float = 0.25) -> AudioStreamWAV:
	var samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / SAMPLE_RATE
		var wobble := sin(TAU * 0.3 * t) * (0.015 if eerie else 0.005)
		var s := int(sin(TAU * (freq + wobble) * t) * vol * 32767)
		if eerie:
			s += int(sin(TAU * freq * 1.5 * t) * 0.1 * 32767)
		s = clampi(s, -32768, 32767)
		data[i * 2]     = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format    = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate  = SAMPLE_RATE
	wav.stereo    = false
	wav.data      = data
	return wav
