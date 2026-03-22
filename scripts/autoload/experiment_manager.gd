extends Node

var player_id = "unknown"

var data = {
	"player_id": "",
	"levels": []
}

func set_player_id(id):
	player_id = id
	data["player_id"] = id

func add_level_data(level_name, wall_hits, time_seconds):
	var level_data = {
		"level": level_name,
		"wall_hits": wall_hits,
		"time": time_seconds
	}
	
	data["levels"].append(level_data)
	
	save_to_file()

func save_to_file():
	var json_string = JSON.stringify(data, "\t")
	
	var file_path = "user://test_" + player_id + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
