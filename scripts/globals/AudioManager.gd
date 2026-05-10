extends Node

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 8
var ambient_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}

func _ready() -> void:
	for i in sfx_pool_size:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.volume_db = -10.0
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -8.0
	_build_sfx_table()

func _build_sfx_table() -> void:
	var names := ["pickup", "anchor", "shift", "ping", "death", "switch", "door", "heartbeat"]
	for n in names:
		var path := "res://assets/audio/sfx/%s.ogg" % n
		if ResourceLoader.exists(path):
			sfx_streams[n] = load(path)

func play(name: String) -> void:
	var stream = sfx_streams.get(name, null)
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

func play_ambient(reality: int) -> void:
	var path := "res://assets/audio/ambient/%s.ogg" % ("light" if reality == 0 else "echo")
	if ResourceLoader.exists(path):
		var s = load(path)
		if ambient_player.stream != s:
			ambient_player.stream = s
			ambient_player.play()
