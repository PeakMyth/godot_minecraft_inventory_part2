# 继承Resource类（Resource是Godot里专门存数据的模板，好管理）
extends Resource

# 给这个模板起个类名ItemData，后面其他脚本能直接调用这个类
class_name ItemData

@export_group("item_information")
@export var id: int #物品唯一编号
@export var name: String #物品名称
@export var texture: Texture2D #物品图标
@export var max_stack: int = 64 #物品最大堆叠数
@export var description: String = "" #物品描述，默认空值（不一定用得上））
@export var max_use_times: int = 1 # 最大使用次数，默认1（即消耗品）。

@export_group("mouse_button")
@export var use_mouse_left: bool = false # 是否允许鼠标左键使用（比如斧头、稿子设为true）
@export var use_mouse_right: bool = true # 是否允许鼠标右键使用（比如苹果、香蕉设为true）
