extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		print("Enemy reached the end!")
		var main = get_tree().get_root().get_node("Main")
		if main:
			main.subtract_life()
			# main.enemy_removed() is already called in main.gd's _on_life_point_body_entered
		
		body.queue_free()
