extends Node2D

@onready var ground: TileMapLayer = $GroundTilemap
@onready var entities: Node2D = $EntitiesContainer
@onready var player: CharacterBody2D = $EntitiesContainer/Player
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

const SCENE_PATHS := {
	"Tree":    "res://scenes/entities/Tree.tscn",
	"Stone":   "res://scenes/entities/Stone.tscn",
	"Letter":  "res://scenes/entities/Letter.tscn",
	"Anchor":  "res://scenes/entities/Anchor.tscn",
	"Chasm":   "res://scenes/entities/Chasm.tscn",
	"Bridge":  "res://scenes/entities/Bridge.tscn",
	"Door":    "res://scenes/entities/Door.tscn",
	"Key":     "res://scenes/entities/Key.tscn",
	"Switch":  "res://scenes/entities/Switch.tscn",
}

var _scenes: Dictionary = {}

func _ready() -> void:
	RealityManager.reality_changed.connect(_on_reality_changed)
	_preload_scenes()
	var gen := ProcGen.generate(GameState.current_seed)
	GameState.current_seed = gen.seed
	_apply_tiles(gen.grid)
	_spawn_all(gen)
	_spawn_puzzles(gen)
	player.position = _wp(gen.pois.HOME)

func _preload_scenes() -> void:
	for key in SCENE_PATHS:
		if ResourceLoader.exists(SCENE_PATHS[key]):
			_scenes[key] = load(SCENE_PATHS[key])

func _apply_tiles(grid: Array) -> void:
	for y in grid.size():
		for x in grid[y].size():
			ground.set_cell(Vector2i(x, y), 0, Vector2i(grid[y][x], 0))

func _spawn_all(gen: Dictionary) -> void:
	for spawn in gen.entity_spawns:
		_spawn(spawn.type, spawn.pos)

	var letter_spawns: Array = gen.letter_spawns
	for i in letter_spawns.size():
		var node = _spawn("Letter", letter_spawns[i])
		if node:
			node.entity_id = "letter_%d" % (i + 1)

	for pos in gen.anchor_spawns:
		_spawn("Anchor", pos)

	var poi_tex = load("res://assets/ui/poi_marker.png")
	if poi_tex:
		_add_poi_marker(gen.pois.HOME,  Color(1.0, 0.3, 0.3), poi_tex)
		_add_poi_marker(gen.pois.HUT,   Color(0.3, 0.5, 1.0), poi_tex)
		_add_poi_marker(gen.pois.HEART, Color(1.0, 0.9, 0.1), poi_tex)

func _spawn_puzzles(gen: Dictionary) -> void:
	for puzzle in gen.puzzle_spawns:
		var pos: Vector2i = puzzle.pos
		var id: String = puzzle.id
		match puzzle.type:
			"RealityBridgeGate":
				# Chasm kills in Light, Bridge covers it in Echo
				var chasm := _spawn("Chasm", pos)
				var bridge := _spawn("Bridge", pos)
				if chasm: chasm.entity_id = id + "_chasm"
				if bridge: bridge.entity_id = id + "_bridge"
				GameState.puzzle_states[id] = false

			"KeyLockGate":
				# Door blocks path, Key is nearby
				var door := _spawn("Door", pos)
				var key := _spawn("Key", pos + Vector2i(4, 0))
				if door: door.entity_id = id + "_door"
				if key:  key.entity_id  = id + "_key"
				GameState.puzzle_states[id] = false

			"EchoSwitchesGate":
				# Two Echo-only switches must both be activated to open door
				var door := _spawn("Door", pos)
				var sw1  := _spawn("Switch", pos + Vector2i(-4, -4))
				var sw2  := _spawn("Switch", pos + Vector2i( 4, -4))
				if door: door.entity_id = id + "_door"
				if sw1:  sw1.entity_id  = id + "_sw1"
				if sw2:  sw2.entity_id  = id + "_sw2"
				if door and sw1 and sw2:
					var gate := EchoSwitchGate.new()
					gate.setup([sw1, sw2], door)
					entities.add_child(gate)
				GameState.puzzle_states[id] = false

func _spawn(type: String, tile_pos: Vector2i) -> Node:
	if not _scenes.has(type):
		return null
	var node: Node = _scenes[type].instantiate()
	node.position = _wp(tile_pos)
	entities.add_child(node)
	return node

func _add_poi_marker(tile_pos: Vector2i, tint: Color, tex: Texture2D) -> void:
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.modulate = tint
	spr.position = _wp(tile_pos)
	entities.add_child(spr)

func _wp(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * Const.TILE_SIZE + Const.TILE_SIZE * 0.5,
		tile_pos.y * Const.TILE_SIZE + Const.TILE_SIZE
	)

func _on_reality_changed(_new: Variant) -> void:
	var target := Const.TINT_ECHO if RealityManager.is_echo() else Const.TINT_LIGHT
	var tw := create_tween()
	tw.tween_property(canvas_modulate, "color", target, RealityManager.FADE_TIME)

	if is_instance_valid(player) and player.has_node("PointLight2D"):
		var pl: PointLight2D = player.get_node("PointLight2D")
		if RealityManager.is_echo():
			pl.visible = true
			var tw2 := create_tween()
			tw2.tween_property(pl, "energy", 1.0, RealityManager.FADE_TIME)
		else:
			var tw2 := create_tween()
			tw2.tween_property(pl, "energy", 0.0, RealityManager.FADE_TIME)
			await tw2.finished
			pl.visible = false

	AudioManager.play_ambient(RealityManager.current)
