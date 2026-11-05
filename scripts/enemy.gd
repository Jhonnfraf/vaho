class_name Enemigo
extends CharacterBody2D

signal murio

@export var vida_maxima : float = 30
@export var umbral_ataque_medio : float = 700
@export var umbral_ataque_fuerte : float = 1600

var salud : float
var marcas_activas : Array[Rune] = []
var _muerto: bool = false
var _en_hit: bool = false

@onready var marca : Sprite2D = $Marca
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("Idle")
	salud = vida_maxima
	sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func marcar(runa : Rune,velocidad_impacto : float) -> void:
	if _muerto:
		return
	
	var nivel := 1
	if velocidad_impacto >= umbral_ataque_fuerte:
		nivel = 3
	elif velocidad_impacto >= umbral_ataque_medio:
		nivel = 2
	else:
		nivel = 1
	
	runa._nivel_marca = nivel
	print("Nivel Marca: ",runa._nivel_marca)
	marcas_activas.append(runa)
	marca.visible = true
	marca.modulate.a = 0.2 + (0.3 * nivel)
	
	if _permite_dano_runa():
		aplicar_dano(runa.base_damage)

func _permite_dano_runa() -> bool:
	return true

func quitar_marca(runa : Rune) -> void:
	marcas_activas.erase(runa)
	if marcas_activas.is_empty():
		marca.visible = false
		
func recibir_golpe(damage : float) -> void:
	if _muerto or not _permite_golpe():
		return
		
	aplicar_dano(damage)
	
	for runa in marcas_activas.duplicate():
		aplicar_dano(runa.base_damage * _multiplicador(runa._nivel_marca))
		runa.detonar(runa.thrower)
	
	marcas_activas.clear()
	marca.visible = false
	print("Salud enemigo: ", salud)
	_al_detonar()

func _permite_golpe() -> bool:
	return true

func _al_detonar() -> void:
	pass
	
func aplicar_dano(dano : float) -> void:
	if _muerto:
		return
	salud -= dano
	if salud <= 0.0:
		_morir()
	else:
		_en_hit = true
		sprite.play("Hit")

func _morir() -> void:
	if _muerto:
		return
	_muerto = true
	
	for runa in marcas_activas.duplicate():
		runa.detonar(runa.thrower)
	marcas_activas.clear()
	marca.visible = false
	
	set_deferred("collision_layer",0)
	sprite.play("Death")
	await sprite.animation_finished
	murio.emit()
	queue_free()

func _multiplicador(nivel : int) -> float:
	match nivel:
		1: return 1.2
		2: return 1.5
		3: return 2.0
		_: return 1.0
	


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "Hit":
		_en_hit = false
		sprite.play("Idle")
