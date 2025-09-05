extends Control
class_name MenuScroll

@export var icon_prefab : PackedScene

@export var topRowContainer : Node2D
@export var backRowContainer : Node2D
@export var fps_text : Label

@export var texArr : Array[Texture2D]
@export var screenCenter : float = 500

#arbitrary value dictating the arc of the icons in the menu
@export var icon_chain_arc : float = 120

@export var empty_texture : Texture2D

var interactable_icon_refs : Array[TextureRect]
var icon_refs : Array[TextureRect] = []

var cursorPos : int = 0
var speed = 0.1
var holding_dir_loop_delay = 0.5
var looping_delay = 0
var held_duration = 0
var last_move = 0

@warning_ignore("unused_signal")
signal on_cursor_changed

func _ready() -> void:
	screenCenter = get_viewport_rect().get_center().x - 50
	fps_text.text = ""

#instantiates all the icons and sets them up for viewing
func initialize(arr:Array[Texture2D]) -> void:
	if(arr):
		texArr = arr
	for i in range(0,texArr.size()):
		var icon_instance = icon_prefab.instantiate()
		icon_instance.texture = texArr[i]
		icon_instance.material = icon_instance.material.duplicate()
		icon_instance.global_position.x += icon_instance.size.x * icon_instance.scale.x * i
		topRowContainer.add_child(icon_instance);
		icon_refs.push_back(icon_instance)
	cursorPos = icon_refs.size() - 1
	interactable_icon_refs = icon_refs.duplicate()
	
	#creates dummy slots
	var image = empty_texture.get_image()
	image.resize(235, 187)
	var resized_texture = ImageTexture.create_from_image(image)
	
	for i in range(0,5):
		var icon_instance = icon_prefab.instantiate()
		icon_instance.texture = resized_texture
		backRowContainer.add_child(icon_instance);
		icon_instance.global_position.x += 0 - icon_instance.size.x * icon_instance.scale.x * i
		icon_instance.material = icon_instance.material.duplicate()
		icon_refs.push_front(icon_instance)
	for i in range(0,5):
		var icon_instance = icon_prefab.instantiate()
		icon_instance.texture = resized_texture
		backRowContainer.add_child(icon_instance);
		icon_instance.global_position.x += 0 - icon_instance.size.x * icon_instance.scale.x * i
		icon_instance.material = icon_instance.material.duplicate()
		icon_refs.push_back(icon_instance)
	update_icon_positions(false)

func _process(delta: float) -> void:
	if Global.game_running:
		return
	
	#moving the icons
	if(Input.is_action_just_pressed('right')):
		looping_delay=0
		held_duration=0
		last_move=-1
		move_cursor(-1);
	
	if(Input.is_action_just_pressed('left')):
		looping_delay=0
		held_duration=0
		last_move=1
		move_cursor(1);
	
	#holding speeds up menu
	if(Input.is_action_pressed('right') || Input.is_action_pressed('left')):
		looping_delay += delta
		held_duration += delta
		if(looping_delay > clampf(0.25-held_duration/10,0.05,0.25)):
			looping_delay = 0
			move_cursor(last_move)
	
	#debug FPS
	#fps_text.text = "fps: "+str(Engine.get_frames_per_second()) + '\n' + str(cursorPos) + " \n" + str(looping_delay)
	
	update_icon_positions();

# handles moving the cursor left and right
func move_cursor(menu_float:int):
	#updating the position
	cursorPos += menu_float
	
	#Bounding the position
	if(cursorPos < 0):
		cursorPos = interactable_icon_refs.size()-1
		looping_delay=0
		held_duration=0
	if(cursorPos > interactable_icon_refs.size()-1):
		cursorPos = 0
		looping_delay=0
		held_duration=0
	
	emit_signal("on_cursor_changed",cursorPos)
	# reset moving things
	update_icon_positions(true)

#handles the visual aspect of updating the icons in the menu
func update_icon_positions(smooth=true):
	for i in range(0,icon_refs.size()):
		
		var icon = icon_refs[i]
		
		# posx is created to take the cursorPos and translate it into the correct position for each icon
		var posx = (
			icon.size.x * i * icon.scale.x + # offset based on position in array
			(cursorPos + 6 - icon_refs.size()) * icon.size.x * icon.scale.x + #center the list on the selected game
			screenCenter # apply offset to the screen center
			- (icon.size.x * icon.scale.x) / 4
		)
		
		if(smooth):
			icon.global_position.x = lerpf(icon.global_position.x,posx,speed);
		else:
			icon.global_position.x = posx;
		
		if icon.material != null:
			icon.material.set_shader_parameter("xpos",-(screenCenter - icon.global_position.x)/icon_chain_arc)
			icon.material.set_shader_parameter("num",-1/icon_chain_arc)

func set_cursor(menu_pos:int):
	cursorPos = menu_pos
	
	#Bounding the position
	if(cursorPos < 0):
		cursorPos = interactable_icon_refs.size()-1
		looping_delay=0
		held_duration=0
	if(cursorPos > interactable_icon_refs.size()-1):
		cursorPos = 0
		looping_delay=0
		held_duration=0
	
	emit_signal("on_cursor_changed",cursorPos)
	# reset moving things
	update_icon_positions(true)
