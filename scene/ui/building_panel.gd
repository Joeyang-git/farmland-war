## 建筑列表面板，挂载于 UILayer（CanvasLayer）上。
## 在运行时用代码构建所有 UI 元素，不依赖单独的 .tscn。
extends CanvasLayer

## 可建造建筑配置表
const BUILDINGS: Array[Dictionary] = [
	{
		"label":   "Home",
		"scene":   "res://scene/building/home.tscn",
		"size":    2,
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(416, 0, 48, 48),
	},
	{
		"label":   "Chicken",
		"scene":   "res://scene/building/chicken.tscn",
		"size":    1,
		"texture": "res://assets/imgs/TilesetHouse.png",
		"region":  Rect2(464, 272, 16, 16),
	},
]

## 类型在 LSP 完成索引前暂用 Node，运行时仍为 game 实例
var _game: Node = null


func _ready() -> void:
	_game = get_tree().get_first_node_in_group("game_root")
	if _game == null:
		push_error("BuildingPanel: 找不到 game_root 组节点")
		return
	_game.building_placed.connect(_on_building_placed)
	_build_panel()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = -52.0
	panel.offset_bottom = 0.0
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	for cfg: Dictionary in BUILDINGS:
		hbox.add_child(_make_item(cfg))


func _make_item(cfg: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(44, 44)
	btn.tooltip_text        = cfg["label"]
	btn.expand_icon         = true

	var atlas    := AtlasTexture.new()
	atlas.atlas  = load(cfg["texture"]) as Texture2D
	atlas.region = cfg["region"] as Rect2
	btn.icon     = atlas

	var scene_path: String = cfg["scene"]
	var size:       int    = cfg["size"]

	# 鼠标按下时立刻开始拖拽，松手时由 game.gd 完成放置
	btn.button_down.connect(func() -> void:
		if btn.disabled:
			return
		var packed := load(scene_path) as PackedScene
		_game.start_drag(packed, size, btn)
	)
	return btn


func _on_building_placed(_item: Node) -> void:
	pass
