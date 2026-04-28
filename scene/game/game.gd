## 游戏总控：管理建筑拖拽放置流程。
## UI 建筑条目调用 start_drag() 开始拖拽；此脚本负责 ghost 反馈与最终落地。
class_name game
extends Node2D

@onready var map:                TileMapLayer = $Map
@onready var building_container: Node2D       = $BuildingContainer
@onready var ghost:              Node2D       = $BuildingGhost

## 本机玩家 uid（单机固定为 1）
var local_uid: int = player_const.LOCAL_PEER_ID

var _is_dragging:  bool         = false
var _drag_scene:   PackedScene  = null
var _drag_size:    int          = 1
## 当前拖拽建筑的建造费用（金币）
var _drag_cost:    int          = 0

## 拖拽开始时记录来源 BuildingItem，放置成功后通知其禁用
signal building_placed(item: Node)
var _drag_source: Node = null


func _enter_tree() -> void:
	add_to_group("game_root")


func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return
	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_try_place()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_cancel_drag()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.keycode == KEY_ESCAPE and ke.pressed:
			_cancel_drag()


## 返回本机玩家节点；map 尚未就绪时返回 null。
func get_local_player() -> player:
	return map.players.get(local_uid) as player


## 由 UI 建筑条目调用；scene 为建筑场景，size 为格数（1/2/3），cost 为建造费用，source 为来源节点。
func start_drag(scene: PackedScene, size: int, cost: int = 0, source: Node = null) -> void:
	_drag_scene  = scene
	_drag_size   = size
	_drag_cost   = cost
	_drag_source = source
	_is_dragging = true
	_update_ghost()


func _update_ghost() -> void:
	var cell     := _mouse_to_cell()
	var cell_pos := Vector2(cell) * building_const.TILE_SIZE
	ghost.position = cell_pos
	var valid: bool = map.can_place_building(cell, _drag_size, local_uid)
	ghost.set_state(_drag_size, valid)


func _try_place() -> void:
	var cell := _mouse_to_cell()
	if map.can_place_building(cell, _drag_size, local_uid):
		var p := get_local_player()
		if p == null or p.gold < _drag_cost:
			_cancel_drag()
			return
		p.gold -= _drag_cost
		_place_building(cell)
		if _drag_source != null:
			building_placed.emit(_drag_source)
	_cancel_drag()


func _place_building(cell: Vector2i) -> void:
	var b: building = _drag_scene.instantiate() as building
	b.owner_uid = local_uid
	b.position  = Vector2(cell) * building_const.TILE_SIZE
	building_container.add_child(b)
	map.register_building(b)


func _cancel_drag() -> void:
	_is_dragging  = false
	_drag_scene   = null
	_drag_source  = null
	_drag_cost    = 0
	ghost.hide()


## 将全局鼠标位置转换为格坐标。
func _mouse_to_cell() -> Vector2i:
	var world_pos := get_global_mouse_position()
	return map.local_to_map(map.to_local(world_pos))
