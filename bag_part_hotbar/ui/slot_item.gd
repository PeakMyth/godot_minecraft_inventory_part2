extends Control

class_name SlotItem

@onready var item_texture: TextureRect = $ItemTexture
@onready var amount_label: Label = $AmountLabel
@onready var use_progress_bar: ProgressBar = $UseProgressBar

# 定义变量：存储当前物品对应的库存格子数据
var slot_: Slot



# 物品显示更新函数（核心函数，用来同步库存数据到图标和数量）
func slot_item_update():
	# 如果没有库存格子数据，或者库存格子里没有物品，直接返回，避免报错
	if !slot_ or !slot_.item: return
	
	# 有物品时，显示物品图标,图标等于库存物品的图标
	item_texture.visible = true
	item_texture.texture = slot_.item.texture
	
	# 判断物品数量：如果数量大于1，显示数量标签；等于1，不显示
	if slot_.count >1:
		amount_label.visible = true
		 # 把数量（整数）转换成字符串，显示在标签上
		amount_label.text = str(slot_.count)
	else :
		amount_label.visible = false
		
	# 工具耐久度进度条显示（核心修改，区分消耗品和工具）
	# 条件：消耗品（max_use_times=1）或工具未使用（is_used=false），隐藏进度条
	if slot_.item.max_use_times == 1 or !slot_.is_used:
		use_progress_bar.visible = false
	else:
		# 设置进度条最大值（等于工具最大使用次数）
		use_progress_bar.max_value = slot_.item.max_use_times
		# 进度条当前值（等于工具当前剩余耐久度）
		use_progress_bar.value = slot_.current_use_times
		
		# 计算进度条比例（当前耐久度/最大耐久度，0.0-1.0）
		var use_ratio = float(slot_.current_use_times) / use_progress_bar.max_value
		
		# 计算进度条颜色（从绿色→黄色→红色，直观区分剩余耐久）
		var fill_color = calculate_progress_color(use_ratio)
		
		# 获取进度条填充样式，设置填充颜色
		var fill_style_box = use_progress_bar.get_theme_stylebox("fill")
		
		if fill_style_box:
			fill_style_box.bg_color = fill_color
		
		# 显示进度条
		use_progress_bar.visible = true

# 计算进度条颜色（从绿色到黄色到红色）
func calculate_progress_color(ratio: float) -> Color:
	# ratio: 0.0-1.0，0表示用完，1表示全新
	# hue (0.0 - 0.3)
	
	# 使用HSV颜色空间，简单但效果不错
	var hue = ratio * 0.3  # 0.3对应绿色，0.0对应红色
	return Color.from_hsv(hue, 0.8, 0.9)  # 高饱和度，中等亮度
