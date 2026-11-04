extends "res://scripts/basic_enemy.gd"

@export var nivel_marca_requerido:int = 2

var _escudo_activo:bool = true

@onready var escudo_sprite: Sprite2D = $Shield

func _permite_golpe() -> bool:
	if not _escudo_activo:
		return true
	for runa in marcas_activas:
		if runa._nivel_marca >= nivel_marca_requerido:
			return true
	return false

func _al_detonar() -> void:
	_escudo_activo = false
	escudo_sprite.visible = false

func _permite_dano_runa() -> bool:
	return not _escudo_activo
	
