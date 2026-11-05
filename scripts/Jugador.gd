extends CharacterBody2D
class_name Jugador

var _facing : bool = true
var _run_boost: float = 1.0

signal murio
signal vida_cambiada(vida: int, maximo: int)

enum _action {
	idle,
	caminando,
	corriendo,
	saltando,
	cayendo,
	atacando_suelo,
	atacando_aire,
	inhalando,
	exhalando,
	herido,
	muriendo
}

var _estado_actual: _action = _action.idle

#Vida
@export var vida_max: int = 10
var _vida: int
var _muerto := false
@export var duracion_hit: float = 0.3
@export var invulnerabilidad: float = 0.8
var _hit_timer := 0.0
var _invulnerable_timer := 0.0

#MOVIMIENTO CONFIG
@export var speed: float = 220.0
@export var run_multiplier: float = 2.2
@export var run_ramp_rate : float = 2.2
@export var jump_velocity: float = -800.0
@export var jump_cut_multiplier: float = 0.5

#EFECTO DE HUMO CONFIG
@onready var humo_delay_timer: Timer = $Timers/TimerHumo
@export var offset_humo : float = 25.0

#GRAVEDAD
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
#@export var gravity: float = 2666.6

#CONFIG GOLPE
@export var offset_golpe: float = 20.0
@onready var area_golpe: Area2D = $AreaGolpe
@onready var area_golpe_shape: CollisionShape2D = $AreaGolpe/CollisionShape2D
@onready var timer_golpe: Timer = $AreaGolpe/TimerGolpe

@export var duracion_golpe: float = 0.15
@export var dano_golpe: float = 10.0

#ONREADY
@onready var gestor_runas: GestorRunas = $GestorRunas

@onready var golpe_animacion : AnimatedSprite2D = $VFX/golpe_animacion
@onready var humo_correr : AnimatedSprite2D = $VFX/humo_correr
@onready var _sprite : AnimatedSprite2D = $SpritePj

func _ready() -> void:
	_vida = vida_max
	area_golpe.monitoring = false
	timer_golpe.wait_time = duracion_golpe
	timer_golpe.one_shot = true
	timer_golpe.timeout.connect(_on_timer_golpe_timeout)
	
	humo_delay_timer.wait_time = 0.1
	humo_delay_timer.timeout.connect(_play_humo_anim)
	humo_delay_timer.one_shot = true
	humo_correr.visible = false
	humo_correr.animation_finished.connect(_on_humo_finished)
	
	golpe_animacion.visible = false
	golpe_animacion.animation_finished.connect(_on_golpe_finished)

#FUnciones para controlar si el personaje esta vivo
#Recibe dano o muere
func recibir_dano(cantidad: int) -> void:
	if _muerto or _invulnerable_timer > 0.0:
		return
	_vida = maxi(_vida - cantidad, 0)
	vida_cambiada.emit(_vida, vida_max)
	if _vida == 0:
		_morir()
		return
	_entrar_hit()

func _entrar_hit() -> void:
	_estado_actual = _action.herido
	_hit_timer = duracion_hit
	_invulnerable_timer = invulnerabilidad
	area_golpe.set_deferred("monitoring", false)
	timer_golpe.stop()
	golpe_animacion.visible = false
	humo_correr.visible = false
	_sprite.play("Hit")

func esta_vivo() -> bool:
	return not _muerto

func _morir() -> void:
	_muerto = true
	_estado_actual = _action.muriendo
	velocity.x = 0.0
	area_golpe.set_deferred("monitoring", false)
	golpe_animacion.visible = false
	humo_correr.visible = false
	murio.emit()
	_sprite.play("Death")
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()

func matar() -> void:
	if _muerto:
		return
	_vida = 0
	vida_cambiada.emit(_vida, vida_max)
	_morir()

func _physics_process(delta: float) -> void:
	if _estado_actual == _action.muriendo:
		if not is_on_floor():
			velocity.y += delta * gravity
		velocity.x = 0.0
		move_and_slide()
		return
		
	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta

	if _estado_actual == _action.herido:
		_hit_timer -= delta
		if _hit_timer <= 0.0:
			_estado_actual = _action.idle
		else:
			if not is_on_floor():
				velocity.y += delta * gravity
			velocity.x = 0.0
			move_and_slide()
			return
	#Controlar velocidad de cada salto
	if not is_on_floor():
		velocity.y += delta * gravity
		
	#Movimiento horizontal del personaje
	var direction := Input.get_axis("mover_izquierda", "mover_derecha")
	
	if direction > 0:
		_facing = true
	elif direction < 0:
		_facing = false
	area_golpe_shape.position.x = absf(area_golpe_shape.position.x) * (1.0 if _facing else -1.0)
	
	#Manejo del salto del personaje
	if is_on_floor() and Input.is_action_just_pressed("saltar"):
		velocity.y = jump_velocity;
		
	#Controlador de salto de altura variable
	if Input.is_action_just_released("saltar") and velocity.y < 0  :
		velocity.y *= jump_cut_multiplier
		
	#Controlador de golpe de personaje
	if Input.is_action_just_pressed("golpe"):
		_estado_actual = _action.atacando_suelo if is_on_floor() else _action.atacando_aire
		golpe_animacion.visible = true
		_do_golpe()
	
	#Controlador de manejo de Runas
	if Input.is_action_just_pressed("lanzar_runa"):
		print(gestor_runas.runas_vailable)
		gestor_runas.try_throw(self, _facing)
	if Input.is_action_just_pressed("exhalar"):
		gestor_runas.try_exhale(self)
	if Input.is_action_just_pressed("inhalar"):
		gestor_runas.do_inhale(self)
	
	#Controlador de correr
	var run_target := 1.0
	if Input.is_action_pressed("correr") and direction != 0.0:
		run_target = run_multiplier
	if _run_boost < run_target:
		_run_boost *= pow(run_ramp_rate, delta)
	elif  _run_boost > run_target:
		_run_boost *= pow(run_ramp_rate, -delta)
	
	_run_boost = clampf(_run_boost, 1.0, run_multiplier)
	velocity.x = direction*speed*_run_boost
	if velocity.x != 0.0 and humo_delay_timer.is_stopped() and Input.is_action_pressed("correr"):
		humo_delay_timer.start()
	
	move_and_slide()
	_determinar_estado()
	_actualizar_animacion()

func _determinar_estado() -> void:
	if _estado_actual == _action.atacando_suelo or _estado_actual == _action.atacando_aire:
		return
	
	if _estado_actual == _action.inhalando or _estado_actual == _action.exhalando:
		return
	
	if not is_on_floor():
		_estado_actual = _action.saltando if velocity.y < 0 else _action.cayendo
		return
	
	if abs(velocity.x) > speed:
		_estado_actual = _action.corriendo
	elif velocity.x != 0.0:
		_estado_actual = _action.caminando
	else:
		_estado_actual = _action.idle

func _actualizar_animacion() -> void:
	match _estado_actual:
		_action.idle:
			_sprite.play("Idle")
		_action.caminando:
			_sprite.play("Moverse")
		_action.corriendo:
			_sprite.play("Correr")
		_action.saltando:
			pass
		_action.cayendo:
			pass
		_action.atacando_suelo:
			_sprite.play("Atacar")
		_action.atacando_aire:
			_sprite.play("Atacar")
		_action.inhalando:
			_sprite.play("Inhalar")
		_action.exhalando:
			_sprite.play("Exhalar")
			
	_sprite.flip_h = not _facing
			

func _play_humo_anim() -> void:
	humo_correr.visible = true
	humo_correr.position.x = -offset_humo if _facing else  offset_humo
	humo_correr.play()	

func _on_humo_finished() -> void:
	humo_correr.visible = false

func _do_golpe() -> void:
	
	golpe_animacion.position.x = offset_golpe if _facing else -offset_golpe
	golpe_animacion.flip_h = _facing
	
	area_golpe.monitoring = true
	timer_golpe.start()
	golpe_animacion.play()

func _on_timer_golpe_timeout() -> void:
	area_golpe.monitoring = false

func _on_area_golpe_body_entered(body: Node2D) -> void:
	if body.has_method("recibir_golpe"):
		body.recibir_golpe(dano_golpe)
		print("Golpeando a: ", body.name)

func _on_golpe_finished() -> void:
	golpe_animacion.visible = false
	if _estado_actual == _action.atacando_suelo or _estado_actual == _action.atacando_aire:
		_estado_actual = _action.idle
