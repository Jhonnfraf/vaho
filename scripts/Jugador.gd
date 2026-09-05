extends CharacterBody2D
class_name Jugador

var _facing : bool = true
var _run_boost: float = 1.0

enum _action{
	corriendo,
	saltando,
	atacando,
	inhalar,
	exhalar
}

@export var speed: float = 220.0
@export var run_multiplier: float = 2.2
@export var run_ramp_rate : float = 2.2
@export var jump_velocity: float = -800.0
@export var jump_cut_multiplier: float = 0.5

@onready var humo_delay_timer: Timer = $Timers/TimerHumo
@export var offset_humo : float = 25.0

@export var max_runas: int = 3
@export var throw_speed: float = 520.0

#@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var gravity: float = 2666.6

@export var offset_golpe: float = 20.0
@onready var area_golpe: Area2D = $AreaGolpe
@onready var timer_golpe: Timer = $AreaGolpe/TimerGolpe

@export var duracion_golpe: float = 0.15

@onready var golpe_animacion : AnimatedSprite2D = $VFX/golpe_animacion
@onready var humo_correr : AnimatedSprite2D = $VFX/humo_correr

func _ready() -> void:
	var _sprite : AnimatedSprite2D = $SpritePj
	_sprite.play("Idle")
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

func _physics_process(delta: float) -> void:
	#Controlar velocidad de cada salto
	if not is_on_floor():
		velocity.y += delta * gravity
		
	#Movimiento horizontal del personaje
	var direction := Input.get_axis("mover_izquierda", "mover_derecha")
	
	if direction > 0:
		_facing = true
	elif direction < 0:
		_facing = false
	
	#Manejo del salto del personaje
	if is_on_floor() and Input.is_action_just_pressed("saltar"):
		velocity.y = jump_velocity;
		
	#Controlador de salto de altura variable
	if Input.is_action_just_released("saltar") and velocity.y < 0  :
		velocity.y *= jump_cut_multiplier
		
	#Controlador de golpe de personaje
	if Input.is_action_just_pressed("golpe"):
		golpe_animacion.visible = true
		_do_golpe()
	
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

func _play_humo_anim() -> void:
	humo_correr.visible = true
	humo_correr.position.x = -offset_humo if _facing else  offset_humo
	print(humo_correr.animation, " loop=", humo_correr.sprite_frames.get_animation_loop(humo_correr.animation))
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
	if body.is_in_group("enemigos"):
		print("Golpeando a: ", body.name)

func _on_golpe_finished() -> void:
	golpe_animacion.visible = false
