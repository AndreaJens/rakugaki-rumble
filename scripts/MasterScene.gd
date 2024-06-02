extends Node

signal scene_successfully_switched

# Called when the node enters the scene tree for the first time.
func _ready():
	SceneManager.switch_scene.connect(goto_scene)
	scene_successfully_switched.connect(SceneManager._on_scene_switched)

func goto_scene(path : String, type : SceneManager.SceneType):
	for child in get_children():
		remove_child(child) # Crashes without explicitly removing from the scene.
		child.queue_free()
	var new_scene = load(path).instantiate()
	_add_extra_scene_parameters(new_scene, type)
	add_child(new_scene)
	emit_signal("scene_successfully_switched")
#	# Instance the new scene.
#	current_scene = s.instantiate()
#
#	# Add it to the active scene, as child of root.
#	get_tree().root.add_child(current_scene)

func _add_extra_scene_parameters(scene, type : SceneManager.SceneType):
	match type:
		SceneManager.SceneType.Training:
			scene.preventDeath = true
			scene.debugMode = true
			scene.networkMode = false
			scene.roundsToWin = 0
		SceneManager.SceneType.SingleMatchMultiplayer:
			scene.preventDeath = false
			scene.debugMode = false
			scene.networkMode = false
			scene.roundsToWin = 3
	
