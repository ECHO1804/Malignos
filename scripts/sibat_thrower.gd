extends StaticBody2D

var Bullet = preload("res://scenes/spear.tscn")
var bulletDamage = 5
var pathName
var currTargets = []
var curr


func _on_range_body_entered(body: Node2D) -> void:
	if "enemy" in body.name:
		var tempArray = []
		currTargets = get_node("Tower").get_overlapping_bodies()
		
		for i in currTargets:
			if "enemy" in i.name:
				tempArray.append(i)
		
		var currTarget = null
		
		pathName = currTarget.get_parent().name
		
		var tempBullet = Bullet.instantiate()
		tempBullet.pathName = pathName
		tempBullet.bulletDamage = bulletDamage
		get_node("BulletContainer").add_child(tempBullet)
		tempBullet.global_position = $Aim.global_position
		


func _on_range_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
