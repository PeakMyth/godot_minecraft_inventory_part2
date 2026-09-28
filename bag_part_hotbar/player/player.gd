extends CharacterBody2D

@onready var bag_ui: Control = $CanvasLayer/bag_ui
@onready var hot_bar: Control = $CanvasLayer/HotBar


# 玩家专属库存变量
@export var player_inventory: Inventory

# 是否处于背包打开状态，默认状态为不打开
var is_bag_open: bool = false

func  _ready() -> void:
	hot_bar.hot_bar_inventory = player_inventory
	hot_bar.hot_bar_ready()

# 输入事件检测函数（Godot默认函数，检测玩家的按键、鼠标等输入）
func _input(event):
	if event.is_action_pressed("inventory_key"):
		toggle_bag()


# 背包切换函数
func toggle_bag():
	if is_bag_open == true:
		bag_ui.close_bag()
		is_bag_open = false
		hot_bar.visible = true
		
	elif is_bag_open == false:
		bag_ui.open_bag(player_inventory)
		is_bag_open = true
		hot_bar.visible = false
