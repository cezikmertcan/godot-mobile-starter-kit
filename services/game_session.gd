extends Node

signal session_changed

var current_level := 1
var last_level_number := 1
var last_result := "none"
var last_base_reward := 0
var last_reward_id := ""
var _level_resolved := false


func _ready() -> void:
	_load_progression()


func begin_level() -> void:
	_load_progression()
	last_result = "playing"
	last_base_reward = 0
	last_reward_id = ""
	_level_resolved = false
	session_changed.emit()


func complete_level() -> int:
	if _level_resolved:
		return last_base_reward
	_level_resolved = true
	last_level_number = current_level
	last_result = "complete"
	last_base_reward = 25 + (current_level - 1) * 5
	last_reward_id = "level_%d_complete" % current_level
	RewardService.grant_once(last_reward_id, last_base_reward, "level_complete")

	var progression := SaveService.get_progression()
	progression["levels_completed"] = int(progression.get("levels_completed", 0)) + 1
	progression["current_level"] = current_level + 1
	SaveService.update_progression(progression)
	current_level += 1
	session_changed.emit()
	return last_base_reward


func fail_level() -> void:
	if _level_resolved:
		return
	_level_resolved = true
	last_level_number = current_level
	last_result = "failed"
	last_base_reward = 0
	last_reward_id = ""
	session_changed.emit()


func retry_level() -> void:
	current_level = last_level_number
	_level_resolved = false
	last_result = "playing"
	last_base_reward = 0
	last_reward_id = ""
	session_changed.emit()


func _load_progression() -> void:
	var progression := SaveService.get_progression()
	current_level = maxi(1, int(progression.get("current_level", 1)))
