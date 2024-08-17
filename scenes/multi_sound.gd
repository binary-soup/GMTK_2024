extends AudioStreamPlayer
class_name MultiSound

var data : Array
var bag : Array


func set_sounds(sounds: Array) -> void:
	data = sounds.duplicate()
	bag = sounds.duplicate()


func play_rand() -> void:
	var index := randi() % bag.size()
	
	var s : AudioStream = bag[index]
	bag.remove_at(index)
	
	if bag.is_empty():
		bag = data.duplicate()
	
	stream = s
	play()
