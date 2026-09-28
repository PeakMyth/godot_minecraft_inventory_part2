extends Control

# 快捷栏对应的库存数据
# 关联玩家的库存（hot_bar_inventory：后续由玩家脚本赋值）
@onready var hot_bar_inventory: Inventory
# 获取所有快捷栏格子节点
# 从HBoxContainer下获取所有子节点，即所有hot_bar_slot格子
@onready var hot_bar_slots: Array = $PanelContainer/MarginContainer/HBoxContainer.get_children()
@onready var selector: Sprite2D = $selector

# 快捷栏选中索引（默认0，对应快捷栏第1格，后续可扩展数字键切换选中）
var selected_index: int = 0

# 滚轮冷却
var scroll_cooldown: bool = false
# 滚轮冷却时间
var CD_time := 0.05

func hot_bar_ready() -> void:
	# 初始化时，先同步一次快捷栏显示（避免快捷栏为空）
	hot_bar_update()
	# 连接库存更新信号：当背包库存变动时，自动调用update函数，同步快捷栏显示
	hot_bar_inventory.inventory_update.connect(hot_bar_update)

# 批量更新所有快捷栏格子，与背包快捷栏库存同步
func hot_bar_update() -> void:
	# 循环遍历所有快捷栏格子（i是循环索引，从0开始）
	for i in range(hot_bar_slots.size()):
		# 1. 获取背包快捷栏中第i个库存格子（和快捷栏格子一一对应）
		var inventory_slot: Slot = hot_bar_inventory.slots[i]
		# 2. 调用当前快捷栏格子的update_to_slot函数，同步显示对应库存物品
		hot_bar_slots[i].update_to_slot(inventory_slot)
		

# 输入处理函数（监听鼠标右键点击，触发快捷栏物品使用）
func _input(event: InputEvent) -> void:
	# 容错判断：只有快捷栏可见时，才监听输入
	if visible:
		# 输入是鼠标右键，且是按下状态
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			hot_bar_inventory.use_item(selected_index)
		
		# 鼠标左键按下（工具使用，触发use_tool函数）
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			hot_bar_inventory.use_tool(selected_index)
		
		switch_item()

# 快捷栏切换总逻辑
func switch_item():
	# 监听 1-9 数字键切换快捷栏
	for i in range(min(9, hot_bar_slots.size())):
		# 对应的快捷键按下
		if Input.is_action_just_pressed("hot_bar" + str(i + 1)):
			# 调用移动移动选择框函数
			move_selector(i)
	
	# 滚轮向上事件按下
	if Input.is_action_just_pressed("scroll_up"):
		# 如果还在冷却，直接返回
		if scroll_cooldown:
			return
		
		# 设置滚轮冷却
		scroll_cooldown = true
		# 设置新的当前快捷栏索引
		var new_selected_index = (selected_index - 1) % hot_bar_slots.size()
		# 如果新的快捷栏索引小于0，就将新的快捷栏索引设置成最后一个格子的索引
		if new_selected_index < 0:
			new_selected_index = hot_bar_slots.size() - 1
		# 更新选中索引
		move_selector(new_selected_index)
		
		# 设置滚轮冷却时间时间
		var timer = get_tree().create_timer(CD_time)
		await timer.timeout
		scroll_cooldown = false
	
	# 滚轮向下事件按下
	elif Input.is_action_just_pressed("scroll_down"):
		# 如果还在冷却，直接返回
		if scroll_cooldown:
			return
		
		# 设置滚轮冷却
		scroll_cooldown = true
		# 设置新的当前快捷栏索引
		var new_selected_index = (selected_index + 1) % hot_bar_slots.size()
		# 更新选中索引
		move_selector(new_selected_index)
		
		# 设置滚轮冷却时间时间
		var timer = get_tree().create_timer(CD_time)
		await timer.timeout
		scroll_cooldown = false

# 更新选中索引 + 移动选择框UI到对应格子
func move_selector(new_selected_index: int):
	# 更新当前选中的快捷栏索引
	selected_index = new_selected_index
	# 让选择框中心点对齐当前选中格子的中心点，实现跟随效果
	selector.global_position = (hot_bar_slots[selected_index].global_position + hot_bar_slots[selected_index].size / 2)
