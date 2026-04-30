## 通用建筑宠物：跟随某个 [class building] 出生，在主人领地内随机踱步。
## 作为该建筑的子节点 [code]Node2D[/code] 挂载，建筑被 [method queue_free] 时随父节点一同清理。
##
## 节点结构（在父建筑的 .tscn 中定义）：
##   <Building>Pet (Node2D, 本脚本)  ← 通常 z_index = 1，避免被其他建筑挡住
##   └── AnimatedSprite2D            ← SpriteFrames 资源里需有 "idle" 与 "walk" 两个循环动画
##
## 状态机：
##   - IDLE   : 等 [member idle_min] ~ [member idle_max] 秒后尝试踱步；播放 "idle" 动画
##   - MOVING : 用 Tween 平滑插值到相邻可行格；播放 "walk" 动画
##
## 「可行格」定义：属于 [member owner_uid] 的领地、非障碍；空格可走。
## 若格上有建筑 [class building]：[class home]（主基地）占格一律不可跨入；
## 其它建筑仅当占地等级 **严格大于** 父建筑（[member building.size]）时不可跨入，
## **同级与小一级**可走（仅视觉踱步）。
##
## 用于多种动物时：在父建筑的 .tscn 里通过给 AnimatedSprite2D 配不同的 SpriteFrames
## 实现外观差异；通过 @export 字段调整每只宠物的速度 / 驻留时间。
class_name building_pet
extends Node2D

# ---------------------------------------------------------------------------
# 调参（编辑器可调）
# ---------------------------------------------------------------------------
## 单格移动用时（秒）；越小走得越急
@export var move_duration: float = 0.4
## idle 等待随机区间下限（秒）
@export var idle_min:      float = 0.5
## idle 等待随机区间上限（秒）
@export var idle_max:      float = 1.5

## SpriteFrames 中的动画名（资源里需有同名动画）
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"

enum State { IDLE, MOVING }

# ---------------------------------------------------------------------------
# 公共字段
# ---------------------------------------------------------------------------
## 主人 uid；由父建筑写入，或在 [_init_after_tree] 中从父 [class building].owner_uid 自动继承
var owner_uid: int = 0

# ---------------------------------------------------------------------------
# 内部状态
# ---------------------------------------------------------------------------
var _map: farm_map = null
@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

var _state: State = State.IDLE
var _idle_timer: float = 0.0
var _idle_duration: float = 0.0
## 父建筑占地等级（building_const.SIZE 的枚举值）；用于判定能否踩上某建筑占格
var _home_size_rank: int = 1
# ---------------------------------------------------------------------------
# 生命周期
# ---------------------------------------------------------------------------
func _ready() -> void:
	# 起始相位随机一下，避免多只宠物同步抖动
	if _sprite != null and _sprite.sprite_frames != null:
		var idle_count: int = _sprite.sprite_frames.get_frame_count(ANIM_IDLE)
		if idle_count > 0:
			_sprite.frame = randi() % idle_count
	# 延迟一帧再绑定 map / 启动逻辑：父节点 building 也走 call_deferred("_bind_map")
	call_deferred("_init_after_tree")


func _init_after_tree() -> void:
	_map = get_tree().get_first_node_in_group("map_layer") as farm_map
	# 父节点是 building 时，未显式设过 owner_uid 则跟随父建筑
	if owner_uid == 0:
		var b := get_parent() as building
		if b != null:
			owner_uid = b.owner_uid
	var pb := get_parent() as building
	if pb != null:
		_home_size_rank = pb.size as int
	_clamp_inside_territory()
	_start_idle()


func _process(delta: float) -> void:
	if _state == State.IDLE:
		_clamp_inside_territory()
	if _state != State.IDLE:
		return
	_idle_timer += delta
	if _idle_timer >= _idle_duration:
		_try_move()


# ---------------------------------------------------------------------------
# 状态切换
# ---------------------------------------------------------------------------
func _start_idle() -> void:
	_state = State.IDLE
	_idle_timer = 0.0
	_idle_duration = randf_range(idle_min, idle_max)
	_play(ANIM_IDLE)


func _try_move() -> void:
	if _map == null:
		_start_idle()
		return

	var target_cell: Vector2i = _pick_random_target()
	if target_cell == Vector2i.MAX:
		_start_idle()
		return

	var target_world: Vector2 = _cell_to_world_center(target_cell)

	# 根据 X 方向翻转朝向（sprite sheet 只画了一向）
	if _sprite != null:
		if target_world.x > global_position.x:
			_sprite.flip_h = false
		elif target_world.x < global_position.x:
			_sprite.flip_h = true

	_state = State.MOVING
	_play(ANIM_WALK)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_world, move_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_start_idle)


## 切到指定动画，已在播则不重置帧（避免每次状态切换都从第 0 帧重启）
func _play(anim: StringName) -> void:
	if _sprite == null:
		return
	if _sprite.animation == anim and _sprite.is_playing():
		return
	_sprite.play(anim)


# ---------------------------------------------------------------------------
# 寻路 / 校验
# ---------------------------------------------------------------------------
## 当前格 4 邻接中随机挑一个可行格；都不行则返回 Vector2i.MAX
func _pick_random_target() -> Vector2i:
	var current_cell: Vector2i = _world_to_cell(global_position)
	var dirs := [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
	]
	dirs.shuffle()
	for d in dirs:
		var nb: Vector2i = current_cell + d
		if _is_walkable(nb):
			return nb
	return Vector2i.MAX


## 该格是否可行：领地内、可通行地形；空格可走。
## 主基地 [class home] 占格不可跨入；其余建筑仅占地 **严格大于** 父建筑时不可跨入。
func _is_walkable(cell: Vector2i) -> bool:
	if _map == null:
		return false
	if not _map.is_passable(cell):
		return false
	var p: player = _map.players.get(owner_uid) as player
	if p == null:
		return false
	if not cell in p.cells:
		return false
	if _map.occupied_cells.has(cell):
		var occ: building = _map.occupied_cells[cell] as building
		if occ == null:
			return true
		if occ is home:
			return false
		var occ_rank: int = occ.size as int
		if occ_rank > _home_size_rank:
			return false
	return true


# ---------------------------------------------------------------------------
# 坐标转换
# ---------------------------------------------------------------------------
func _cell_to_world_center(cell: Vector2i) -> Vector2:
	var ts: int = building_const.TILE_SIZE
	return Vector2(cell.x * ts + ts * 0.5, cell.y * ts + ts * 0.5)


func _world_to_cell(pos: Vector2) -> Vector2i:
	var ts: int = building_const.TILE_SIZE
	return Vector2i(floori(pos.x / ts), floori(pos.y / ts))


## 若宠物被拖拽到领地外或对角漂移，拉回最近合法领地格中心；
## IDLE 时每帧跑一次，拖拽后很快就能归位且不跨格瞬移太远。
func _clamp_inside_territory() -> void:
	if _map == null:
		return
	var p: player = _map.players.get(owner_uid) as player
	if p == null or p.cells.is_empty():
		return
	var cur_cell: Vector2i = _world_to_cell(global_position)
	if cell_in_owner_territory(cur_cell):
		return
	var fallback: Vector2i = nearest_owner_cell(global_position)
	if fallback == Vector2i.MAX:
		return
	global_position = _cell_to_world_center(fallback)


func cell_in_owner_territory(cell: Vector2i) -> bool:
	var p: player = _map.players.get(owner_uid) as player if _map != null else null
	if p == null:
		return false
	return cell in p.cells


## 曼哈顿距离最短；平局取欧氏更近者
func nearest_owner_cell(from_world_pos: Vector2) -> Vector2i:
	var p: player = _map.players.get(owner_uid) as player if _map != null else null
	if p == null or p.cells.is_empty():
		return Vector2i.MAX
	var best: Vector2i = p.cells[0]
	var best_md: int = 0x7FFFFFFF
	var best_d2: float = INF
	for c in p.cells:
		var center := _cell_to_world_center(c)
		var md := manhattan_i(from_world_pos - center)
		var d2: float = from_world_pos.distance_squared_to(center)
		if md < best_md or (md == best_md and d2 < best_d2):
			best_md = md
			best_d2 = d2
			best = c
	return best


func manhattan_i(v: Vector2) -> int:
	return absi(roundi(v.x)) + absi(roundi(v.y))
