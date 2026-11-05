class_name Hud
extends CanvasLayer

@export var objetivo_inicial: String = ""

@onready var _barra_vida: Range = $PanelIzq/BarraVida
@onready var _icono_runas: TextureRect = $PanelIzq/Runa/Icono
@onready var _label_runas: Label = $PanelIzq/Runa/EtiquetaRunas
@onready var _label_objetivo: Label = $Objetivo

var _gestor: Node
var _runas_previas := -1

func _ready() -> void:
	_icono_runas.visible = _icono_runas.texture != null
	set_objetivo(objetivo_inicial)

	var jugador := get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		push_warning("HUD: no hay nodo en el grupo 'jugador'")
		return

	_barra_vida.max_value = jugador.vida_max
	_barra_vida.value = jugador.vida_max
	jugador.vida_cambiada.connect(_on_vida_cambiada)
	_gestor = jugador.gestor_runas

func _process(_delta: float) -> void:
	if _gestor == null:
		return
	var v = _gestor.runas_vailable
	var n: int = v.size() if v is Array else int(v)
	if n != _runas_previas:
		_runas_previas = n
		_label_runas.text = "x %d" % n

func _on_vida_cambiada(vida: int, maximo: int) -> void:
	_barra_vida.max_value = maximo
	_barra_vida.value = vida

func set_objetivo(texto: String) -> void:
	_label_objetivo.text = texto
	_label_objetivo.visible = texto != ""
