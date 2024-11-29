extends Node2D

### Variáveis ###
# Configuração e controle de jogo
var lixo_scenes = []  # Lista para armazenar os tipos de lixo
var current_lixo = null  # Lixo atualmente em cena
var velocidade_queda = 300
var velocidade_movimento = 900
var x_min = -80
var x_max = 3000
var pontos = 0  # Pontuação do jogador
var acertos = 0  # Contador de acertos do jogador
var max_acertos = 10  # Número de acertos necessários para vencer
var erros = 0  # Contador de erros do jogador
var max_erros = 5  # Número máximo de erros antes de Game Over
var erro_contabilizado = false  # Variável para evitar erro duplo por lixo
var jogo_pausado = false  # Estado do jogo pausado

# Interface
var score_label = null  # Referência ao Label de pontuação
var vidas_label = null  # Referência ao Label de vidas
var vidas_container = null  # Referência ao Container de vidas

### Inicialização ###
func _ready():
	# Carregar todas as cenas de lixo com seus tipos
	lixo_scenes = [
		{'scene': preload("res://Lixo/vidro1.tscn"), 'tipo': 'vidro'},
		{'scene': preload("res://Lixo/vidro2.tscn"), 'tipo': 'vidro'},
		{'scene': preload("res://Lixo/metal1.tscn"), 'tipo': 'metal'},
		{'scene': preload("res://Lixo/metal2.tscn"), 'tipo': 'metal'},
		{'scene': preload("res://Lixo/plastico1.tscn"), 'tipo': 'plastico'},
		{'scene': preload("res://Lixo/plastico2.tscn"), 'tipo': 'plastico'},
		{'scene': preload("res://Lixo/papel1.tscn"), 'tipo': 'papel'},
		{'scene': preload("res://Lixo/papel2.tscn"), 'tipo': 'papel'},
		{'scene': preload("res://Lixo/organico1.tscn"), 'tipo': 'organico'},
		{'scene': preload("res://Lixo/organico2.tscn"), 'tipo': 'organico'},
	]
	spawn_lixo()

	# Obter referências aos Labels e Container de vidas
	score_label = $ScoreLabel
	vidas_label = $PontosLabel
	vidas_container = $VidasContainer  # Referência ao Container de vidas

	atualizar_pontuacao()
	atualizar_vidas()

	# Conectar o botão de pause com Callable
	$PauseButton.connect("pressed", Callable(self, "_on_pause_button_pressed"))

### Atualização ###
func _process(delta):
	if jogo_pausado:
		return  # Não processa a lógica do jogo quando pausado

	if current_lixo:
		# Rotação do lixo
		current_lixo.rotation += 1.5 * delta

		# Movimento horizontal
		if Input.is_action_pressed("ui_left"):
			current_lixo.position.x -= velocidade_movimento * delta
		elif Input.is_action_pressed("ui_right"):
			current_lixo.position.x += velocidade_movimento * delta

		# Teletransporte horizontal
		if current_lixo.position.x < 0:
			current_lixo.position.x = 1024
		elif current_lixo.position.x > 1024:
			current_lixo.position.x = 0

		# Movimento de queda
		current_lixo.position.y += velocidade_queda * delta

		# Verificar se o lixo saiu da tela
		if current_lixo.position.y > 800 and not erro_contabilizado:
			contabilizar_erro()
			reset_lixo()

### Controle de Lixo ###
func spawn_lixo():
	if current_lixo:
		current_lixo.queue_free()  # Remove o lixo atual da cena
	var random_index = randi() % lixo_scenes.size()
	var lixo_info = lixo_scenes[random_index]
	current_lixo = lixo_info['scene'].instantiate()
	current_lixo.set_meta("tipo", lixo_info['tipo'])  # Define o tipo de lixo
	add_child(current_lixo)
	
	# Corrigindo a função randi_range para gerar valores dentro da tela
	current_lixo.position = Vector2(randi_range(0, 1024), 0)
	
	erro_contabilizado = false  # Reseta a contagem de erro para o próximo lixo
	print("Lixo spawnado:", current_lixo.get_meta("tipo"))

func reset_lixo():
	spawn_lixo()

### Lógica de Colisões ###
func _on_lixeiraverde_body_entered(body):
	if body == current_lixo and current_lixo.get_meta("tipo") == "vidro":
		registrar_acerto()
	else:
		contabilizar_erro()

func _on_lixeiraamarela_body_entered(body):
	if body == current_lixo and current_lixo.get_meta("tipo") == "metal":
		registrar_acerto()
	else:
		contabilizar_erro()

func _on_lixeiravermelha_body_entered(body):
	if body == current_lixo and current_lixo.get_meta("tipo") == "plastico":
		registrar_acerto()
	else:
		contabilizar_erro()

func _on_lixeiraazul_body_entered(body):
	if body == current_lixo and current_lixo.get_meta("tipo") == "papel":
		registrar_acerto()
	else:
		contabilizar_erro()

func _on_lixeiramarrom_body_entered(body):
	if body == current_lixo and current_lixo.get_meta("tipo") == "organico":
		registrar_acerto()
	else:
		contabilizar_erro()

### Lógica de Jogo ###
func registrar_acerto():
	$somAcerto.play()
	if not erro_contabilizado:
		acertos += 1
		pontos += 100
		atualizar_pontuacao()
		if acertos >= max_acertos:
			tela_vitoria()
		reset_lixo()

func contabilizar_erro():
	$somErro.play()
	if not erro_contabilizado:
		erro_contabilizado = true
		erros += 1
		atualizar_vidas()
		if erros >= max_erros:
			game_over()
		else:
			reset_lixo()

### Interface e Controle ###
func atualizar_pontuacao():
	score_label.text = "Pontos: " + str(pontos)

func atualizar_vidas():
	var vidas_restantes = max_erros - erros
#   vidas_label.text = "Vidas: " + str(vidas_restantes)

	# Remover todos os filhos do container
	for child in vidas_container.get_children():
		vidas_container.remove_child(child)
		child.queue_free()

	# Adicionar corações atualizados
	for i in range(max_erros):
		var coracao_texture = ImageTexture.new()
		if i < vidas_restantes:
			coracao_texture = coracao_vermelho
		else:
			coracao_texture = coracao_cinza
		var sprite = Sprite2D.new()  # Criar um novo Sprite2D
		sprite.texture = coracao_texture  # Definir a textura do sprite
		vidas_container.add_child(sprite)  # Adicionar o sprite ao container

		# Ajustar a posição dos corações no container (se necessário)
		sprite.position = Vector2(i * 500, 0)  # Ajuste a distância entre os corações

func _on_pause_button_pressed():
	if jogo_pausado:
		resume()
	else:
		pause()

func pause():
	jogo_pausado = true
	$PauseButton.text = "Voltar"

func resume():
	jogo_pausado = false
	$PauseButton.text = "Pausar"

### Estados do Jogo ###
func game_over():
	get_tree().change_scene_to_file("res://cenas/game_over.tscn")

func tela_vitoria():
	get_tree().change_scene_to_file("res://cenas/ganhou.tscn")

# Variáveis para os corações
var coracao_vermelho = preload("res://AssetsSG/coracao_vermelho.png")
var coracao_cinza = preload("res://AssetsSG/coracao_cinza.png")
