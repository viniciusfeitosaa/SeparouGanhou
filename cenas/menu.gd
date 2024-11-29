extends Node2D

func _on_jogar_pressed():
	get_tree().change_scene_to_file("res://cenas/explicação.tscn")

func _on_sair_pressed():
	get_tree().quit()


func _on_musica_finished():
	$Musica.play()
