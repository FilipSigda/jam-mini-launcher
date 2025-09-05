extends Control
class_name Launcher

@export_group("Directory")
@export var GAME_DIR: String = "/Users/Shared/Games/"

@export_group("Objects Refs")
@export var menu : MenuScroll
@export var preview : Previewer

@export_group("Label Refs")
@export var TitleLabel : Label
@export var DescObject : Control
@export var AuthorObject : Control

@export var AuthLabel : Label
@export var TypeLabel : Label
@export var GenreLabel : Label
@export var DescLabel : Label
@export var YearLabel : Label
@export var GradLabel : Label

#constants --------------------------------------------------------------
const ICON_SIZE = Vector2(235, 187)

const AUTHOR_OVERFLOW_OFFSET = 50.0
const AUTHOR_POSITION_OFFSET = -197


#animation constants
const TITLE_ANIM_DUR = 0.2
const TITLE_POS_OFFSET = 50.0

const DETAIL_VIEW_PULL_DUR = 1.0
const DETAIL_VIEW_ANIM_SPEED = 0.6
const DETAIL_VIEW_OFFSET = 250.0

const DESC_BASE_OFFSET = 50.0

#variables ------------------------------------------------------------

#holds all the game data at runtime
var games : Array[Game] = []

#cooldown between closing current game and launching new one
var cooldown: bool = false

#runtime variables
var current_game : int = 0
var running_pid = -1
var is_running
var quit_hold : Timer

#animation variables
var title_t = 0.0
var title_start_y = 0.0

var desc_t = 0.0
var desc_start_y = 0.0

var detail_view_target = 0.0
var detail_view_t = 0
var detail_anim_offset = 1.0

#debug variables
var is_in_debug_mode = false

# LOAD FUNCTIONS ---------------------------------------------------------------------------------
# midfied Andrew's launcher code

#load the game folder paths into an array
func _load_game_folders() -> Array[String]:
	#initialize folders array
	var folder_names : Array[String] = []
	var current_folder_name : String
	
	#open directory
	var game_dir : DirAccess = DirAccess.open(GAME_DIR)
	
	#read the whole directory
	if game_dir :
		#start at first
		game_dir.list_dir_begin()
		current_folder_name = game_dir.get_next()
		
		#while folder exists
		while current_folder_name != "":
			if game_dir.current_is_dir() and not current_folder_name.begins_with("."):
				var json_path: String = GAME_DIR + current_folder_name + "/" + current_folder_name + ".json"
				if FileAccess.file_exists(json_path):
					folder_names.append(current_folder_name)
			current_folder_name = game_dir.get_next()
	folder_names.sort()
	return folder_names

# load game info and resources
func _load_game_info(folder) -> void:
	var game = _load_game_json(folder)
	
	#load video
	game.video = load(GAME_DIR + folder + "/" + folder + ".ogv")
	
	#resize image to icon size
	var image : Image = Image.load_from_file(GAME_DIR + folder + "/" + folder + ".png")
	image.resize(int(ICON_SIZE.x),int(ICON_SIZE.y))
	game.texture = ImageTexture.create_from_image(image)
	
	#set execution path to launch the game
	game.exec_path = (GAME_DIR + folder + "/" + folder[0].to_upper() + folder.substr(1, -1) + ".app")
	
	#add to list stored at runtime
	games.append(game)

#loads each game from folder
func load_all_games(folder_names) -> void:
	for i in range(0,folder_names.size()):
		_load_game_info(folder_names[folder_names.size()-1-i])

#loads the JSON from the folder
func _load_game_json(folder_name: String) -> Game:
	#get folder
	var json_path: String = GAME_DIR + folder_name + "/" + folder_name + ".json"
	
	#init vars
	var json_string: String
	var json_dict: Game = Game.new()
	var json_file = FileAccess.open(json_path, FileAccess.READ)
	
	#go through file
	if json_file:
		json_string = json_file.get_as_text()
		var json: JSON = JSON.new()
		if json.parse(json_string) == OK:
			#passes it to the GAME class so we can handle the formatting there
			json_dict.loadFromJsonDict(json.get_data())
	return json_dict

# DISPLAY FUNCTIONS -------------------------------------------------------------------------------
# run only after games are loaded in
func DisplayIcons():
	var texarr : Array[Texture2D] = []
	for game in games:
		texarr.push_front(game.texture)
	menu.initialize(texarr)

#runs when menu updates
func on_cursor_update(cursor):
	current_game = cursor
	update_preview_video(games[cursor])
	fade_in_Title(games[cursor].game_title)
	fade_in_desc(games[cursor])

#updates the video of the game preview
func update_preview_video(game:Game):
	preview.setGamePreview(null,game.video)

#initializes all the animation for the title (fading in and down)
func fade_in_Title(text:String):
	TitleLabel.text = text 
	title_t = TITLE_ANIM_DUR
	
	#resize to center title based on text size
	
	#get rect
	var top_left = TitleLabel.get_character_bounds(0).position
	var temp = TitleLabel.get_character_bounds(TitleLabel.get_total_character_count()-1)
	var bot_right = temp.position + temp.size
	var result_rect = Rect2(top_left,top_left - bot_right)
	
	TitleLabel.size = result_rect.size
	
	#change position to center rect
	TitleLabel.global_position = Vector2(get_viewport_rect().get_center().x - TitleLabel.size.x/2,TitleLabel.global_position.y)
	animate_title(0)

#sets all the other data besides title
func fade_in_desc(game:Game):
	#parse the arrays
	var strg = ""
	var genres = ""
	for i in game.author:
		strg += i
		if(i != game.author[game.author.size()-1]):
			strg += ', '
	for i in game.genres:
		genres += i
		if(i != game.genres[game.genres.size()-1]):
			genres += ', '
	
	#display values
	AuthLabel.text = strg
	TypeLabel.text = game.type
	GenreLabel.text = genres
	DescLabel.text = game.description
	YearLabel.text = "Released: " + game.creation_year
	GradLabel.text = "Graduated: " + str(game.grad_year)
	desc_t = TITLE_ANIM_DUR
	
	
	#check if the author text is larger than the 2 lines allocated by default ----------
	#get the visual position of the last character in the label of the authors
	var last_char = AuthLabel.get_character_bounds(AuthLabel.text.length()-1)
	#adjust by offset
	last_char.position = last_char.position - AuthLabel.get_character_bounds(0).position
	
	# compare author text
	if(last_char.position.y > 0):
		AuthorObject.position.y = AUTHOR_POSITION_OFFSET
	else:
		AuthorObject.position.y = AUTHOR_POSITION_OFFSET + AUTHOR_OVERFLOW_OFFSET
	
	animate_desc(0)

#runs when player presses the hide desc
func pull_up_desc():
	detail_view_target = DETAIL_VIEW_OFFSET
	detail_view_t = DETAIL_VIEW_PULL_DUR
	animate_desc(0)

#runs when player presses the pull desc
func pull_down_desc():
	detail_view_target = 0
	detail_view_t = DETAIL_VIEW_PULL_DUR
	animate_desc(0)

#handles the animations
func animate_title(delta):
	#clamp to avoid bounce effect
	title_t = clampf(title_t,0,TITLE_ANIM_DUR)
	
	#calculate position
	TitleLabel.global_position.y = lerpf(TitleLabel.global_position.y,(title_t/TITLE_ANIM_DUR) * -TITLE_POS_OFFSET + title_start_y,0.4)
	
	#add alpha modulation to match the animation
	var c = Color.WHITE
	c.a = 1-(title_t/TITLE_ANIM_DUR) 
	TitleLabel.modulate = c
	
	#time counters
	if(title_t > 0):
		title_t -= delta

func animate_desc(delta):
	#clamp to avoid bounce effect
	desc_t = clampf(desc_t,0,TITLE_ANIM_DUR)
	var _detail_t = clampf(detail_view_t,0,DETAIL_VIEW_PULL_DUR)
	#calculate positions
	detail_anim_offset = lerpf(detail_anim_offset,detail_view_target,DETAIL_VIEW_ANIM_SPEED)
	
	#start moving
	DescObject.global_position.y = lerpf(DescObject.global_position.y,
	(desc_t/TITLE_ANIM_DUR) * DESC_BASE_OFFSET 
	- detail_anim_offset
	+ desc_start_y,
	0.4)
	
	#modify transparancy with the menu
	var c = Color.WHITE
	c.a = 1-(desc_t/TITLE_ANIM_DUR) 
	DescObject.modulate = c
	
	#time counters
	if(DESC_BASE_OFFSET > 0):
		desc_t -= delta
	if(detail_view_t > 0):
		detail_view_t -= delta

#running games ------------------------------------------------------------------------------------
func close_game():
	if is_running and (OS.is_process_running(running_pid) or is_in_debug_mode):
		if(!is_in_debug_mode):
			OS.kill(running_pid)
			is_running = false
			running_pid = -1

func start_game():
	if cooldown:
		return
	
	var g : Game = games[current_game]
	
	var exec_path : String = g.exec_path
	if exec_path:
		if(!is_in_debug_mode):
			running_pid = OS.create_process(exec_path, ["-f"])
		else:
			running_pid = 999999999999999
		is_running = true

# OTHER -------------------------------------------------------------------------------------------
# cooldown between launching and closing a game
func _start_cooldown(duration: float) -> void:
	cooldown = true
	await get_tree().create_timer(duration).timeout
	cooldown = false

# PROCESSING -------------------------------------------------------------------------------------
func _ready():
	var default = games.size() - 1
	#loads in all the games
	load_all_games(_load_game_folders())
	
	current_game = games.size() - 1
	
	#Display all in menu
	menu.on_cursor_changed.connect(on_cursor_update)
	DisplayIcons()
	update_preview_video(games[default])
	title_start_y = TitleLabel.global_position.y
	desc_start_y = DescObject.global_position.y
	fade_in_Title(games[default].game_title)
	fade_in_desc(games[default])
	
	#setup runtime processes
	quit_hold = Timer.new()
	quit_hold.timeout.connect(close_game)
	quit_hold.wait_time = 3.0
	get_tree().root.call_deferred("add_child",quit_hold)

func _process(delta: float) -> void:
	#while game is running
	
	#autocorrect if PID is closed externally
	if is_running and (not OS.is_process_running(running_pid) || is_in_debug_mode):
		is_running = false
		_start_cooldown(0.5)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
		await get_tree().create_timer(0.3).timeout
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)
		return
	
	if(Input.is_action_just_pressed("down")):
		pull_down_desc()
	if(Input.is_action_just_pressed("up")):
		pull_up_desc()
	
	#handle the title animation
	animate_title(delta)
	animate_desc(delta)

func _input(_event: InputEvent) -> void:
	if is_running:
		if Input.is_action_just_pressed("quit"):
			quit_hold.start()
		if Input.is_action_just_released("quit"):
			quit_hold.stop()
	else:
		if Input.is_action_just_pressed("click"):
			start_game()
