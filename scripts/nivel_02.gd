extends Node2D

@export var salida: Area2D
@export var hud: Hud

var _vivos := 0

func _ready() -> void:
	$AudioStreamPlayer.finished.connect(_on_audio_stream_player_finished)
	if salida == null:
		push_error("Asigna el nodo 'Salida' en el Inspector de la raíz del nivel 2")
		return

	var enemigos: Array[Node] = []
	enemigos.append_array($EnemigosBasicos.get_children())
	enemigos.append_array($EnemigosEscudo.get_children())

	for enemigo in enemigos:
		if enemigo.has_signal("murio"):
			_vivos += 1
			enemigo.murio.connect(_on_enemigo_murio, CONNECT_ONE_SHOT)
		

	print("Enemigos a derrotar: ", _vivos)
	_actualizar_objetivo()
	if _vivos == 0:
		salida.abrir()

func _on_enemigo_murio() -> void:
	_vivos -= 1
	_actualizar_objetivo()
	if _vivos <= 0 and salida != null:
		salida.abrir()

func _actualizar_objetivo() -> void:
	if hud == null:
		return
	if _vivos > 1:
		hud.set_objetivo("Elimina %d enemigos" % _vivos)
	elif _vivos == 1:
		hud.set_objetivo("Elimina 1 enemigo")
	else:
		hud.set_objetivo("Ve a la salida")


func _on_audio_stream_player_finished() -> void:
	$AudioStreamPlayer.play()
