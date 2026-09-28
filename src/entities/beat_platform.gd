class_name BeatPlatform
extends StaticBody2D
## Plataformas rítmicas (GDD §4).
##
## Tipos implementados en Fase 1:
##   GROUND   — siempre sólidas (terreno base).
##   BEAT     — "se activan en el golpe fuerte": sólidas mientras el beat fluye,
##              pulsan con cada golpe, se desvanecen en el silencio.
##   SILENCE  — "solo existen en pausas musicales": sólidas en el silencio.
##   RESONANT — "amplifica el sonido al pisarla": suena un chime al pisarla.
##
## Pendientes para Fase 2 (GDD): MELODY, ECHO, HARMONY y estado DESTRUCTIVE.

enum PlatformType { BEAT, MELODY, SILENCE, ECHO, HARMONY, GROUND, RESONANT }

const TYPE_COLORS := {
	PlatformType.BEAT: Color(0.85, 0.30, 0.16),
	PlatformType.SILENCE: Color(0.22, 0.25, 0.38),
	PlatformType.RESONANT: Color(0.96, 0.55, 0.20),
	PlatformType.MELODY: Color(0.80, 0.65, 0.20),
	PlatformType.ECHO: Color(0.45, 0.55, 0.60),
	PlatformType.HARMONY: Color(0.60, 0.45, 0.75),
	PlatformType.GROUND: Color(0.16, 0.07, 0.09),
}

var platform_type: PlatformType = PlatformType.BEAT
var size := Vector2(120.0, 16.0)

var _collision: CollisionShape2D
var _visual: Polygon2D
var _chime: AudioStreamPlayer


func _ready() -> void:
	_build()
	if platform_type != PlatformType.GROUND:
		AudioManager.beat_detected.connect(_on_beat)
		AudioManager.silence_started.connect(_on_silence_started)
		AudioManager.silence_ended.connect(_on_silence_ended)
	_refresh()


func _build() -> void:
	## Se construye sola desde los datos del nivel (assets/data/levels).
	_collision = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_collision.shape = rect
	add_child(_collision)

	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5),
	])
	_visual.color = _base_color()
	add_child(_visual)

	if platform_type == PlatformType.RESONANT:
		_chime = AudioStreamPlayer.new()
		_chime.stream = load("res://assets/audio/effects/chime.wav")
		_chime.volume_db = -8.0
		add_child(_chime)

	# Sensor de pisado (para el chime de las resonantes).
	if platform_type != PlatformType.GROUND:
		var sensor := Area2D.new()
		var sensor_collision := CollisionShape2D.new()
		var sensor_rect := RectangleShape2D.new()
		sensor_rect.size = Vector2(size.x, 8.0)
		sensor_collision.shape = sensor_rect
		sensor_collision.position = Vector2(0, -size.y * 0.5 - 3.0)
		sensor.add_child(sensor_collision)
		sensor.body_entered.connect(_on_sensor_body_entered)
		add_child(sensor)


func _refresh() -> void:
	match platform_type:
		PlatformType.GROUND:
			_set_solid(true, _base_color())
		PlatformType.BEAT, PlatformType.RESONANT:
			_set_solid(not AudioManager.in_silence, _base_color())
		PlatformType.SILENCE:
			_set_solid(AudioManager.in_silence, _base_color())
		_:
			_set_solid(true, _base_color())


# ------------------------------------------------------------------ señales --

func _on_beat(intensity: float) -> void:
	if platform_type == PlatformType.BEAT or platform_type == PlatformType.RESONANT:
		_pulse(intensity)


func _on_silence_started() -> void:
	match platform_type:
		PlatformType.SILENCE:
			_set_solid(true, Color(0.62, 0.70, 0.95))    # aparece en el silencio
		PlatformType.BEAT, PlatformType.RESONANT:
			_set_solid(false, Color(0.30, 0.11, 0.09))   # el beat la sostenía


func _on_silence_ended() -> void:
	match platform_type:
		PlatformType.SILENCE:
			_set_solid(false, Color(0.18, 0.20, 0.30))
		PlatformType.BEAT, PlatformType.RESONANT:
			_set_solid(true, _base_color())


func _on_sensor_body_entered(body: Node2D) -> void:
	if body is not CharacterBody2D:
		return
	if platform_type == PlatformType.RESONANT and not _collision.disabled:
		if _chime != null:
			_chime.play()
		_pulse(1.0)


# -------------------------------------------------------------------- estado --

func _set_solid(solid: bool, color: Color) -> void:
	## Estados del GDD §4: Sólida ↔ Fantasma (con transición visual).
	_collision.set_deferred("disabled", not solid)
	var tween := create_tween()
	tween.tween_property(_visual, "color", color, 0.12)


func _pulse(strength: float) -> void:
	var amount := 0.8 + clampf(strength, 0.0, 1.5) * 0.8
	_visual.modulate = Color(1.0 + amount * 0.7, 1.0 + amount * 0.3, 1.0 + amount * 0.15, 1.0)
	_visual.scale = Vector2(1.0 + 0.05 * amount, 1.0 + 0.16 * amount)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "scale", Vector2.ONE, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _base_color() -> Color:
	return TYPE_COLORS.get(platform_type, Color(0.16, 0.07, 0.09))
