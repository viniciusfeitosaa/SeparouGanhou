extends Sprite2D

var speed = 200

func _ready():
	position.x = randf_range(10, 790)

func _process(delta):
	position.y += speed * delta
	if position.y > get_viewport().size.y:
		queue_free() # Remove o lixo quando sai da tela
