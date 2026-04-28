## 逻辑玩家实体，由 map.gd 在 _collect_players() 中实例化并作为 Map 节点的子节点持有。
## game.gd 通过 map.players[local_uid] 访问本机玩家；building 通过 map.players[owner_uid] 访问自身归属者。
class_name player
extends Node

var uid: int = 0
var user_type: player_const.USER_TYPE = player_const.USER_TYPE.HUMAN
## 联机时填 multiplayer.get_unique_id()；单机填 0
var peer_id: int = player_const.LOCAL_PEER_ID
var cells: Array[Vector2i] = []

## 当前金币；由产钱建筑的 _use_skill 累加，建造时由 game.gd 扣除；最低为 0
var gold: int = 0

## 是否为本机玩家；单机时只要 user_type==HUMAN 即为本机，联机时比对 peer_id
var is_local: bool:
	get:
		if user_type != player_const.USER_TYPE.HUMAN:
			return false
		if peer_id == player_const.LOCAL_PEER_ID:
			return true
		return peer_id == get_tree().get_multiplayer().get_unique_id()
