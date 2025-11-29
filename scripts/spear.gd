extends CharacterBody2D

var target
var Speed = 1000
var pathName = ""
var bulletDamage

func _physics_process(delta: float) -> void:
	var pathSpawnerNode = get_tree().get_root().get_node("Main/PathSpawner")
	
	for i in pathSpawnerNode.get_child_count():
		if pathSpawnerNode.get_child(i).name == pathName:
			target = pathSpawnerNode.getchild(i).getchild(0).getchild(0).global_positon
			
	velocity = global_position.direction_to(target) + Speed
	
	look_at(target)
	
	move_and_slide()	
