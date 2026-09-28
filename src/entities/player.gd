class_name ResonaPlayer
extends CharacterBody2D
## Jugador — una silueta (GDD §2: "siluetas minimalistas").
## Movimiento fluido inspirado en Ori (GDD §8): coyote time, jump buffer,
## salto variable y caída rápida para que se sienta ligero y emocional.

const RUN_SPEED := 320.0
const GROUND_ACCEL := 2600.0
const AIR_ACCEL := 1800.0
const GROUND_FRICTION := 2400.0
const AIR_FRICTION := 500.0
const JUMP_VELOCITY := -580.0
const JUMP_CUT := 0.45          # soltar el botón corta el salto (salto variable)
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.12
const FALL_GRAVITY_MULT := 1.4  # cae más rápido de lo que sube: mejor game feel
const MAX_FALL_SPEED := 900.0
const GRAVITY := 980.0
const RESPAWN_Y := 900.0

var _coyote := 0.0
var _buffer := 0.0
var _start_pos := Vector2.ZERO
var _visual: Polygon2D


func _ready() -> void:
	_start_pos = position
	if not has_node("Visual"):
		_build_body()
	_visual = get_node("Visual") as Polygon2D


func _build_body() -> void:
	## Se construye sola: no necesita escena .tscn.
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 34)
	collision.shape = rect
	add_child(collision)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.polygon = PackedVector2Array([
		Vector2(-9, 17), Vector2(-9, -4), Vector2(-6, -13),
		Vector2(0, -17), Vector2(6, -13), Vector2(9, -4), Vector2(9, 17),
	])
	visual.color = Color(0.10, 0.05, 0.07)
	add_child(visual)

	var camera := Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.make_current()
	add_child(camera)


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	# Coyote time: margen para saltar justo después de dejar el suelo.
	_coyote = COYOTE_TIME if on_floor else maxf(0.0, _coyote - delta)

	# Jump buffer: si apretas salto justo antes de aterrizar, salta al tocar.
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	else:
		_buffer = maxf(0.0, _buffer - delta)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		_squash(Vector2(0.72, 1.30))

	# Salto variable: corta el impulso al soltar.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Movimiento horizontal.
	var direction := Input.get_axis("move_left", "move_right")
	if absf(direction) > 0.001:
		var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
		velocity.x = move_toward(velocity.x, direction * RUN_SPEED, accel * delta)
	else:
		var friction := GROUND_FRICTION if on_floor else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Gravedad (asimétrica).
	var gravity := GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + gravity * delta, MAX_FALL_SPEED)

	var was_airborne := not on_floor
	move_and_slide()

	if was_airborne and is_on_floor():
		_squash(Vector2(1.30, 0.70))

	# Caíste al vacío: vuelve al inicio (GDD §2, Zona de Vacío nos perdona).
	if global_position.y > RESPAWN_Y:
		position = _start_pos
		velocity = Vector2.ZERO


func _squash(target_scale: Vector2) -> void:
	## Squash & stretch: el lenguaje corporal de la silueta.
	var tween := create_tween()
	tween.tween_property(_visual, "scale", target_scale, 0.06)
	tween.tween_property(_visual, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
