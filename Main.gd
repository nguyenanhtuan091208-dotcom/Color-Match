extends Node2D

# ==============================
# GAME SETTINGS
# ==============================

const ROWS = 8
const COLS = 8
const CELL_SIZE = 64
const EMPTY = -1

const SAVE_PATH = "user://color_match_save.cfg"

# ==============================
# GAME VARIABLES
# ==============================

var board = []
var selected_cell = Vector2i(-1, -1)

var score = 0
var current_level = 1
var target_score = 500
var max_unlocked_level = 1

var candy_colors = [
	Color("#FF5252"),
	Color("#FFD740"),
	Color("#40C4FF"),
	Color("#69F0AE"),
	Color("#E040FB")
]

# ==============================
# START GAME
# ==============================

func _ready():
	randomize()
	load_progress()
	create_board()
	queue_redraw()

# ==============================
# CREATE BOARD
# ==============================

func create_board():
	board.clear()

	for row in range(ROWS):
		var new_row = []

		for col in range(COLS):
			var candy = randi_range(0, 4)
			new_row.append(candy)

		board.append(new_row)

# ==============================
# PLAYER INPUT
# ==============================

func _input(event):

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_click(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed:
			handle_click(event.position)

func handle_click(mouse_pos):

	var screen_size = get_viewport_rect().size

	var board_width = COLS * CELL_SIZE
	var board_height = ROWS * CELL_SIZE

	var start_x = (screen_size.x - board_width) / 2
	var start_y = (screen_size.y - board_height) / 2

	if mouse_pos.x < start_x or mouse_pos.x >= start_x + board_width:
		return

	if mouse_pos.y < start_y or mouse_pos.y >= start_y + board_height:
		return

	var col = int((mouse_pos.x - start_x) / CELL_SIZE)
	var row = int((mouse_pos.y - start_y) / CELL_SIZE)

	var clicked_cell = Vector2i(row, col)

	if selected_cell == Vector2i(-1, -1):
		selected_cell = clicked_cell

	elif selected_cell == clicked_cell:
		selected_cell = Vector2i(-1, -1)

	elif abs(selected_cell.x - row) + abs(selected_cell.y - col) == 1:
		swap_and_check(clicked_cell)

	else:
		selected_cell = clicked_cell

	queue_redraw()

# ==============================
# SWAP CANDIES
# ==============================

func swap_and_check(clicked_cell):

	var first = selected_cell
	var second = clicked_cell

	swap_candies(first, second)

	var matches = find_matches()

	if matches.is_empty():
		swap_candies(first, second)
	else:
		resolve_matches()

	selected_cell = Vector2i(-1, -1)
	queue_redraw()

func swap_candies(first, second):

	var temp = board[first.x][first.y]

	board[first.x][first.y] = board[second.x][second.y]
	board[second.x][second.y] = temp

# ==============================
# FIND MATCHES
# ==============================

func find_matches():

	var matched = {}

	for row in range(ROWS):
		for col in range(COLS - 2):

			var candy = board[row][col]

			if candy == EMPTY:
				continue

			if candy == board[row][col + 1] and candy == board[row][col + 2]:

				var k = col

				while k < COLS and board[row][k] == candy:
					matched[Vector2i(row, k)] = true
					k += 1

	for col in range(COLS):
		for row in range(ROWS - 2):

			var candy = board[row][col]

			if candy == EMPTY:
				continue

			if candy == board[row + 1][col] and candy == board[row + 2][col]:

				var k = row

				while k < ROWS and board[k][col] == candy:
					matched[Vector2i(k, col)] = true
					k += 1

	return matched

# ==============================
# CLEAR MATCHES AND GRAVITY
# ==============================

func resolve_matches():

	var matches = find_matches()

	while not matches.is_empty():

		score += matches.size() * 10

		for cell in matches.keys():
			board[cell.x][cell.y] = EMPTY

		for col in range(COLS):

			var write_row = ROWS - 1

			for row in range(ROWS - 1, -1, -1):

				if board[row][col] != EMPTY:
					board[write_row][col] = board[row][col]
					write_row -= 1

			for row in range(write_row, -1, -1):
				board[row][col] = randi_range(0, 4)

		matches = find_matches()

	check_level_progress()
	save_progress()
	queue_redraw()

# ==============================
# LEVEL SYSTEM
# ==============================

func check_level_progress():

	while score >= target_score:

		current_level += 1

		max_unlocked_level = max(
			max_unlocked_level,
			current_level
		)

		target_score += 300

		print("LEVEL UP!")
		print("Current Level: ", current_level)

# ==============================
# SAVE PROGRESS
# ==============================

func save_progress():

	var config = ConfigFile.new()

	config.set_value("progress", "current_level", current_level)
	config.set_value("progress", "score", score)
	config.set_value("progress", "max_unlocked_level", max_unlocked_level)

	config.save(SAVE_PATH)

# ==============================
# LOAD PROGRESS
# ==============================

func load_progress():

	var config = ConfigFile.new()

	var error = config.load(SAVE_PATH)

	if error == OK:

		current_level = config.get_value(
			"progress",
			"current_level",
			1
		)

		score = config.get_value(
			"progress",
			"score",
			0
		)

		max_unlocked_level = config.get_value(
			"progress",
			"max_unlocked_level",
			1
		)

	else:

		current_level = 1
		score = 0
		max_unlocked_level = 1

	target_score = 500 + (current_level - 1) * 300

# ==============================
# DRAW GAME
# ==============================

func _draw():

	var screen_size = get_viewport_rect().size

	var board_width = COLS * CELL_SIZE
	var board_height = ROWS * CELL_SIZE

	var start_x = (screen_size.x - board_width) / 2
	var start_y = (screen_size.y - board_height) / 2

	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color("#20243A")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x, start_y - 85),
		"COLOR MATCH",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		28,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x, start_y - 55),
		"LEVEL: " + str(current_level),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		22,
		Color("#69F0AE")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x + 270, start_y - 55),
		"SCORE: " + str(score),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("#FFD740")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x + 270, start_y - 30),
		"TARGET: " + str(target_score),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	for row in range(ROWS):
		for col in range(COLS):

			var x = start_x + col * CELL_SIZE
			var y = start_y + row * CELL_SIZE

			draw_rect(
				Rect2(x, y, CELL_SIZE - 2, CELL_SIZE - 2),
				Color("#343B58")
			)

			var center = Vector2(
				x + CELL_SIZE / 2,
				y + CELL_SIZE / 2
			)

			var candy_type = board[row][col]

			if candy_type != EMPTY:

				draw_circle(
					center,
					23,
					candy_colors[candy_type]
				)

				draw_circle(
					center + Vector2(-7, -7),
					5,
					Color(1, 1, 1, 0.45)
				)

			if selected_cell == Vector2i(row, col):

				draw_rect(
					Rect2(x + 2, y + 2, CELL_SIZE - 6, CELL_SIZE - 6),
					Color.WHITE,
					false,
					4.0
				)
