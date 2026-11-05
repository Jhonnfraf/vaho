extends "res://scripts/enemy.gd"

@export var velocidad_persecucion: float = 90.0
@export var zona_muerta: float = 4.0
@export var dano: int = 1
@export var cooldown_ataque : float = 1.0
@export var frame_golpe : int = 2

@onready var _area_ataque : Area2D = $AreaAtaque
@onready var _area_ataque_shape : CollisionShape2D = $AreaAtaque/CollisionShape2D
@onready var _vision_area : Area2D = $VisionArea
@onready var _vision_area_shape : CollisionPolygon2D = $VisionArea/CollisionPolygon2D
@onready var _rayo_suelo: RayCast2D = $RayoSuelo


var _objetivo: Node2D = null
var _gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _cuerpo_ataque: Node2D = null
var _jugador_visible := false
var _jugador_en_rango := false
var _atacando := false
var _cooldown := 0.0
var _mirando := 1.0

func _ready() -> void:
	super._ready()
	sprite.play("Idle")
	_vision_area.body_entered.connect(_on_vision_body_entered)
	_vision_area.body_exited.connect(_on_vision_body_exited)
	_area_ataque.body_entered.connect(_on_ataque_body_entered)
	_area_ataque.body_exited.connect(_on_ataque_body_exited)
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity*delta
	if _cooldown > 0.0:
		_cooldown -= delta
	
	var direccion := 0.0
	if not _muerto and not _en_hit and not _atacando and not _jugador_en_rango and _jugador_visible and is_instance_valid(_objetivo):
		var dx := _objetivo.global_position.x - global_position.x
		if absf(dx) > zona_muerta:
			direccion = signf(dx)
	
	velocity.x = direccion * velocidad_persecucion
	move_and_slide()
	
	if _muerto or _en_hit:
		_atacando = false
		return
	if _atacando:
		return
	
	if _puede_atacar():
		_iniciar_ataque()
		return
		
	_voltear(direccion)
	_actualizar_animacion(direccion)
	
func _actualizar_animacion(direccion : float) -> void:
	if direccion != 0.0:
		sprite.flip_h = direccion < 0.0
		sprite.play("Walk")
	else:
		sprite.play("Idle")
		
func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_objetivo = body
		_jugador_visible = true

func _on_vision_body_exited(body: Node2D) -> void:
	if body == _objetivo:
		_jugador_visible = false
		_objetivo = null
		velocity.x = 0.0

func _on_ataque_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		_cuerpo_ataque = body
		_jugador_en_rango = true


func _on_ataque_body_exited(body: Node2D) -> void:
	if body == _cuerpo_ataque:
		_jugador_en_rango = false
		_cuerpo_ataque = null

func _puede_atacar() -> bool:
	return _jugador_en_rango and _cooldown <= 0.0 \
		and is_instance_valid(_cuerpo_ataque) and _cuerpo_ataque.esta_vivo()

func _iniciar_ataque() -> void:
	_atacando = true
	velocity.x = 0.0
	_voltear(signf(_cuerpo_ataque.global_position.x - global_position.x))
	sprite.play("Attack")


func _voltear(direccion: float) -> void:
	if direccion == 0.0 or direccion == _mirando:
		return
	_mirando = direccion
	sprite.flip_h = direccion < 0.0

	_vision_area_shape.scale.x = direccion
	_vision_area_shape.position.x = absf(_vision_area_shape.position.x) * direccion

	_area_ataque_shape.scale.x = direccion
	_area_ataque_shape.position.x = absf(_area_ataque_shape.position.x) * direccion

	_rayo_suelo.scale.x = direccion
	_rayo_suelo.position.x = absf(_rayo_suelo.position.x) * direccion
	
		

func _on_sprite_frame_changed() -> void:
	if not _atacando or sprite.animation != "Attack":
		return
	if sprite.frame == frame_golpe and _jugador_en_rango and is_instance_valid(_cuerpo_ataque):
		_cuerpo_ataque.recibir_dano(dano)


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "Attack":
		_atacando = false
		_cooldown = cooldown_ataque
