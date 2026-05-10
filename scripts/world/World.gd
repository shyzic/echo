extends Node2D

@onready var ground: TileMapLayer = $GroundTilemap
@onready var entities: Node2D = $EntitiesContainer
@onready var player: CharacterBody2D = $EntitiesContainer/Player
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

const SCENE_PATHS := {
	"Tree":        "res://scenes/entities/Tree.tscn",
	"Stone":       "res://scenes/entities/Stone.tscn",
	"Letter":      "res://scenes/entities/Letter.tscn",
	"Anchor":      "res://scenes/entities/Anchor.tscn",
	"Chasm":       "res://scenes/entities/Chasm.tscn",
	"Bridge":      "res://scenes/entities/Bridge.tscn",
	"Door":        "res://scenes/entities/Door.tscn",
	"Key":         "res://scenes/entities/Key.tscn",
	"Switch":      "res://scenes/entities/Switch.tscn",
	"Monster":     "res://scenes/entities/Monster.tscn",
	"Npc":         "res://scenes/entities/Npc.tscn",
	"HeartShrine": "res://scenes/entities/HeartShrine.tscn",
	"Diary":       "res://scenes/entities/Diary.tscn",
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
	_spawn_border()
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

	# Story POIs
	var npc := _spawn("Npc", gen.pois.HUT)
	if npc:
		npc.dialogue_key = "mother_intro"
		npc.entity_id = "mother"

	# Diary on the table inside hut
	var diary := _spawn("Diary", gen.pois.HUT + Vector2i(2, 1))
	if diary:
		diary.entity_id = "father_diary"

	var shrine := _spawn("HeartShrine", gen.pois.HEART)
	if shrine:
		shrine.entity_id = "heart_shrine"

	# Monsters
	for spawn in gen.monster_spawns:
		var m := _spawn("Monster", spawn.pos)
		if m:
			m.add_to_group("monster")

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
				var chasm := _spawn("Chasm", pos)
				var bridge := _spawn("Bridge", pos)
				if chasm: chasm.entity_id = id + "_chasm"
				if bridge: bridge.entity_id = id + "_bridge"
				GameState.puzzle_states[id] = false
			"KeyLockGate":
				var door := _spawn("Door", pos)
				var key := _spawn("Key", pos + Vector2i(4, 0))
				if door: door.entity_id = id + "_door"
				if key:  key.entity_id  = id + "_key"
				GameState.puzzle_states[id] = false
			"EchoSwitchesGate":
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

func _spawn_border() -> void:
	# 4 invisible StaticBody2D walls outside map edges (hard collision)
	var mw := Const.MAP_W_TILES * Const.TILE_SIZE
	var mh := Const.MAP_H_TILES * Const.TILE_SIZE
	_add_border_wall(Vector2(mw / 2.0, -16),      Vector2(mw + 64, 32))  # top
	_add_border_wall(Vector2(mw / 2.0, mh + 16),  Vector2(mw + 64, 32))  # bottom
	_add_border_wall(Vector2(-16, mh / 2.0),       Vector2(32, mh + 64)) # left
	_add_border_wall(Vector2(mw + 16, mh / 2.0),   Vector2(32, mh + 64)) # right

	# Dense tree ring along the actual border tiles (visual dark forest)
	var w := Const.MAP_W_TILES
	var h := Const.MAP_H_TILES
	for x in w:
		_spawn_border_tree(Vector2i(x, 0))
		_spawn_border_tree(Vector2i(x, 1))
		_spawn_border_tree(Vector2i(x, h - 1))
		_spawn_border_tree(Vector2i(x, h - 2))
	for y in range(2, h - 2):
		_spawn_border_tree(Vector2i(0, y))
		_spawn_border_tree(Vector2i(1, y))
		_spawn_border_tree(Vector2i(w - 1, y))
		_spawn_border_tree(Vector2i(w - 2, y))

func _spawn_border_tree(tile_pos: Vector2i) -> void:
	if not _scenes.has("Tree"):
		return
	var node: Node = _scenes["Tree"].instantiate()
	node.position = _wp(tile_pos)
	# Darken border trees to indicate impenetrable forest
	if node.has_node("Sprite2D"):
		node.get_node("Sprite2D").modulate = Color(0.3, 0.35, 0.3, 1.0)
	entities.add_child(node)

func _add_border_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	entities.add_child(body)

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
