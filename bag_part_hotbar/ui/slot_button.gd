extends Button

signal mouse_button_left_press   # 鼠标左键点击信号
signal mouse_button_right_press  # 鼠标右键点击信号

@onready var slot_background: ColorRect = $SlotBackground
@onready var center_container: CenterContainer = $SlotBackground/CenterContainer

# 存储当前格子关联的库存（Inventory类型，和bag_ui传入的库存一致）
var slot_inventory: Inventory

# 当前格子对应的库存索引（位置，比如第0格、第1格，和库存数组slots的索引一一对应）
var slot_index: int

# 定义变量：存储当前格子里的物品显示节点（SlotItem类型，对应slot_item脚本）
var slot_button_slot_item: SlotItem

func _ready() -> void:
	# 设置按钮可响应的鼠标按键（左键+右键），避免只响应左键或右键
	button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT
	reset_color()

func reset_color(): # 重置格子背景颜色的函数
	slot_background.color = Color(0.5, 0.5, 0.5, 0.8) # 设置ColorRect的颜色

# 放入物品显示节点的函数
func insert(SI: SlotItem):
	# 把传入的物品显示节点（SI）赋值给当前格子的变量，记录当前格子有物品
	slot_button_slot_item = SI
	# 格子有物品时，修改背景颜色
	slot_background.color = Color(0.7, 0.7, 0.7, 0.8)
	# 把物品显示节点（图标+数量）添加到居中容器里
	center_container.add_child(slot_button_slot_item)
	
	# 容错判断：如果当前物品没有对应的库存格子数据（slot_为空），直接返回，避免报错
	# 防止出现“物品显示节点存在，但没有库存数据”的情况，导致调用insert_slot报错
	if !slot_button_slot_item.slot_:
		return
	
	# 调用库存的insert_slot函数，同步插入物品到库存
	slot_inventory.insert_slot(slot_index, slot_button_slot_item.slot_)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# 如果是鼠标左键按下
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 发送鼠标左键点击信号
			mouse_button_left_press.emit()
		
		# 如果是鼠标右键按下
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed: 
			# 发送鼠标右键点击信号
			mouse_button_right_press.emit() 

# 抓取物品函数（核心函数，被bag_ui脚本调用，取出当前格子里的物品）
func take_item():
	# 把当前格子里的物品显示节点，赋值给临时变量take_item_（记录要抓取的物品）
	var take_item_ = slot_button_slot_item
	
	# 意思是：告诉库存“这个格子里的物品被抓走了，你把这个库存格子清空”
	slot_inventory.remove_slot(slot_button_slot_item.slot_)
	
	# 从居中容器里移除物品显示节点（让物品从格子里“消失”，准备跟随鼠标）
	if center_container.get_child_count() != 0:
		center_container.remove_child(slot_button_slot_item)
	# 把当前格子的物品节点设为null（表示格子里没有物品了，重置格子状态）
	slot_button_slot_item = null
	
	# 调用重置颜色函数，把格子背景恢复为默认灰色（空格子状态）
	reset_color()
	
	# 返回抓取到的物品节点（给bag_ui脚本，让它控制物品跟随鼠标）
	return take_item_

# 判断格子是否为空的函数（被bag_ui脚本调用，判断当前格子能不能放物品）
func is_empty():
	# 逻辑：如果slot_button_slot_item是null（没有物品），就返回true（空）；否则返回false（有物品)
	# !slot_button_slot_item 表示“非空判断”，null的非值就是true
	return !slot_button_slot_item

# 右键功能：放入一个物品
# 接收鼠标上的物品数据，实现“单个放入”当前格子，返回是否放入成功
# mouse_slot: 参数，鼠标上物品的Slot数据（包含物品类型、数量）
# -> bool：函数返回值是布尔值（true=放入成功，false=放入失败）
func put_one_item(mouse_slot: Slot) -> bool:
	# 情况1：当前格子是空的，可以直接放入1个物品
	if is_empty():
		# 创建新的Slot对象，也就是新的库存数据格子（深拷贝，避免和鼠标物品数据冲突）
		var new_slot = Slot.new()  
		# 新物品类型，和鼠标上的物品一致（比如都是苹果）
		new_slot.item = mouse_slot.item 
		# 只放入1个，所以数量设为1
		new_slot.count = 1
		
		# 创建新的物品显示节点（slot_item场景实例化，和第六期、第十二期一致）
		var new_slot_item = preload("res://ui/slot_item.tscn").instantiate()
		# 给新物品节点设置Slot数据（物品+数量）
		new_slot_item.slot_ = new_slot
		# 调用当前格子的insert函数，把新物品插入格子（UI层面显示）
		insert(new_slot_item)
		
		# 减少鼠标上物品的数量（放入1个，鼠标上就少1个）
		mouse_slot.count -= 1
		
		# 放入成功，返回true
		return true
		
	
	# 情况2：当前格子不为空（判断是否能放入1个相同物品）
	else:
		# 获取当前格子里已有的物品数据（Slot）
		var existing_slot = slot_button_slot_item.slot_
		
		# 判断：当前格子物品和鼠标物品ID一致（相同物品）
		if existing_slot.item.id == mouse_slot.item.id:
			# 再判断：当前格子物品数量 < 最大堆叠数（格子没满，能继续堆叠）
			if existing_slot.count < existing_slot.item.max_stack:
				# 当前格子物品数量+1（放入1个，堆叠起来）
				existing_slot.count += 1
				
				# 减少鼠标上物品的数量（放入1个，鼠标上少1个）
				mouse_slot.count -= 1
				
				# 放入成功，返回true
				return true
	
	
	# 所有情况都不满足（格子非空、物品不同或格子已满），放入失败，返回false
	return false

func clear_slot():
	if slot_button_slot_item:
	# 从居中容器里移除物品显示节点（让物品从格子里“消失”，准备跟随鼠标）
		#center_container.remove_child(slot_button_slot_item)
		for i in center_container.get_children():
			center_container.remove_child(i)
	# 把当前格子的物品节点设为null（表示格子里没有物品了，重置格子状态）
		slot_button_slot_item = null
	
	# 调用重置颜色函数，把格子背景恢复为默认灰色（空格子状态）
	reset_color()
