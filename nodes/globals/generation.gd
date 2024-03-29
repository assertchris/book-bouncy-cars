extends Node

@export_file("*.txt") var words_file

var generator : RandomNumberGenerator

func _ready() -> void:
	generator = RandomNumberGenerator.new()
	generator.randomize()

func get_three_words_phrase() -> String:
	return " ".join(get_words(generator))

func get_words(generator : RandomNumberGenerator, number : int = 3) -> PackedStringArray:
	var words := get_all_words()
	var size := words.size()

	var chosen := []

	for i in range(3):
		chosen.append(words[generator.randi() % size])

	return PackedStringArray(chosen)

func get_all_words() -> PackedStringArray:
	var file = File.new()
	file.open(words_file, File.READ)

	var content = file.get_as_text()

	file.close()

	return content.split("\n", false)

func get_hash_from_words(words : PackedStringArray) -> int:
	var complete = ""

	for word in words:
		complete += word.trim_prefix(" ").trim_suffix(" ").to_lower()

	return complete.hash()

func get_deep_corner_array(image: Image, offset_segment: int) -> Array:
	var rows = []

	for y in Constants.segment_height:
		var row = []

		for x in Constants.segment_width:
			var cell = Types.cells.none

			match image.get_pixel(x + (offset_segment * Constants.segment_width), y).to_html(false):
				Types.cell_colors[Types.cells.grass]:
					cell = Types.cells.grass
				Types.cell_colors[Types.cells.road]:
					cell = Types.cells.road
				Types.cell_colors[Types.cells.player_1_start]:
					cell = Types.cells.player_1_start
				Types.cell_colors[Types.cells.player_2_start]:
					cell = Types.cells.player_2_start
				Types.cell_colors[Types.cells.waypoint]:
					cell = Types.cells.waypoint

			row.push_back(cell)

		rows.push_back(row)

	return rows

@export var layout_texture : Texture2D

func get_map(user_three_words_phrase = null) -> Dictionary:
	var three_words = null

	if typeof(user_three_words_phrase) == TYPE_STRING:
		three_words = user_three_words_phrase.split(" ")
	else:
		three_words = get_three_words_phrase().split(" ")

	generator.seed = get_hash_from_words(three_words)

	var clockwise = generator.randi() & 1

	var top_left_offset = generator.randi() % Constants.number_of_segments
	var top_right_offset = generator.randi() % Constants.number_of_segments
	var bottom_left_offset = generator.randi() % Constants.number_of_segments
	var bottom_right_offset = generator.randi() % Constants.number_of_segments

	var segments_image = layout_texture.get_image()

	var top_left_deep_corner = get_deep_corner_array(segments_image, top_left_offset)
	var top_right_deep_corner = get_deep_corner_array(segments_image, top_right_offset)
	var bottom_left_deep_corner = get_deep_corner_array(segments_image, bottom_left_offset)
	var bottom_right_deep_corner = get_deep_corner_array(segments_image, bottom_right_offset)

	var top_left_flipped_corner = get_flipped_corner_array(top_left_deep_corner, false, false)
	var top_right_flipped_corner = get_flipped_corner_array(top_right_deep_corner, true, false)
	var bottom_left_flipped_corner = get_flipped_corner_array(bottom_left_deep_corner, false, true)
	var bottom_right_flipped_corner = get_flipped_corner_array(bottom_right_deep_corner, true, true)

	var top_left_shallow_corner = get_shallow_corner_array(top_left_flipped_corner, 0, 0, Types.segment_types.top_left)
	var top_right_shallow_corner = get_shallow_corner_array(top_right_flipped_corner, 0, Constants.segment_width, Types.segment_types.top_right)
	var bottom_left_shallow_corner = get_shallow_corner_array(bottom_left_flipped_corner, Constants.segment_height, 0, Types.segment_types.bottom_left)
	var bottom_right_shallow_corner = get_shallow_corner_array(bottom_right_flipped_corner, Constants.segment_height, Constants.segment_width, Types.segment_types.bottom_right)

	var cells = []
	cells += top_left_shallow_corner.cells
	cells += top_right_shallow_corner.cells
	cells += bottom_left_shallow_corner.cells
	cells += bottom_right_shallow_corner.cells

	var waypoints = []
	waypoints += top_left_shallow_corner.waypoints
	waypoints += top_right_shallow_corner.waypoints
	waypoints += bottom_left_shallow_corner.waypoints
	waypoints += bottom_right_shallow_corner.waypoints

	return {
		"cells": cells,
		"waypoints": waypoints,
		"generator": generator,
		"three_words": three_words,
		"clockwise": clockwise,
	}

func get_flipped_corner_array(deep_corner_array: Array, should_flip_x: bool = false, should_flip_y: bool = false) -> Array:
	var new_rows = []

	for row in deep_corner_array:
		var new_row = []

		for cell in row:
			if should_flip_x:
				new_row.push_front(cell)
			else:
				new_row.push_back(cell)

		if should_flip_y:
			new_rows.push_front(new_row)
		else:
			new_rows.push_back(new_row)

	return new_rows

func get_shallow_corner_array(deep_corner_array: Array, offset_row: int, offset_cell: int, segment_type: int) -> Dictionary:
	var cells = []
	var waypoints = []

	var i = 0

	for row in deep_corner_array.size():
		for cell in deep_corner_array[row].size():
			cells.push_back({
				"y": row + offset_row,
				"x": cell + offset_cell,
				"type": deep_corner_array[row][cell],
			})

			if deep_corner_array[row][cell] == Types.cells.waypoint:
				waypoints.push_back({
					"y": row + offset_row,
					"x": cell + offset_cell,
					"segment_type": segment_type,
					"index": i,
				})

				i += 1

	return {
		"cells": cells,
		"waypoints": waypoints,
	}
