class_name Const

# === DISPLAY ===
const INTERNAL_W := 480
const INTERNAL_H := 270

# === TILES ===
const TILE_SIZE := 32
const MAP_W_TILES := 150
const MAP_H_TILES := 150

# === PLAYER ===
const PLAYER_SPEED := 90.0
const PLAYER_HITBOX := Vector2(16, 8)

# === ECHO / PING ===
const ECHO_AMBIENT_RADIUS := 48.0
const PING_RADIUS_MAX := 220.0
const PING_GROW_TIME := 0.35
const PING_HOLD_TIME := 0.8
const PING_FADE_TIME := 0.6
const PING_COOLDOWN := 0.7

# === PROCGEN ===
const PATH_WIDTH_TILES := 3
const TREE_DENSITY := 0.18
const NUM_PUZZLES := 4
const NUM_LETTERS := 6
const NUM_MONSTERS := 8
const NUM_SPIRITS := 8
const MIN_POI_DIST := 40

# === COLORS ===
const TINT_LIGHT := Color(1.0, 1.0, 1.0, 1.0)
const TINT_ECHO  := Color(0.04, 0.04, 0.10, 1.0)   # near-black — player light is the only lamp

# === TILE IDS ===
const TILE_GRASS_A       := 0
const TILE_GRASS_B       := 1
const TILE_PATH          := 2
const TILE_PATH_EDGE     := 3
const TILE_FLOOR_INTERIOR := 4
const TILE_WALL          := 5
