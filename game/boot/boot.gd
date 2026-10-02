extends Node
## Boot: hands off to the title screen once autoloads are ready.
const TITLE := "res://game/ui/title/title.tscn"

func _ready() -> void:
	await get_tree().process_frame
	if QA.active:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("qa_scene="):
				return
	if ResourceLoader.exists(TITLE):
		get_tree().change_scene_to_file(TITLE)
