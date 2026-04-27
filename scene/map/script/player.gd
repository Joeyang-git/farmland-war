class_name player
extends Node

var uid: int = 0
var user_type: player_const.USER_TYPE = player_const.USER_TYPE.HUMAN
## 联机时填 multiplayer.get_unique_id()；单机填 0
var peer_id: int = player_const.LOCAL_PEER_ID
var cells: Array[Vector2i] = []

## 是否为本机玩家；单机时只要 user_type==HUMAN 即为本机，联机时比对 peer_id
var is_local: bool:
	get:
		if user_type != player_const.USER_TYPE.HUMAN:
			return false
		if peer_id == player_const.LOCAL_PEER_ID:
			return true
		return peer_id == get_tree().get_multiplayer().get_unique_id()
