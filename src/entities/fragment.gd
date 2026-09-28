class_name SoulFragment
extends Area2D
## Fragmento del yo — coleccionable narrativo (GDD §2 y §5).
## Cada zona guarda recuerdos distintos; al tocarlo, su frase poética
## aparece en pantalla. Brilla al ritmo de la música.

const BEAT_COLOR := Color(1.0, 0.62, 0.25, 0.92)

var fragment_text := ""

var _collected := false
var _visual: Polygon2D
var _material: ShaderMaterial
var _pulse := 0.0


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/resonant_pulse.gdshader")
	_material.set_shader_parameter("base_color", BEAT_COLOR)

	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([
		Vector2(0, -15), Vector2(13, 0), Vector2(0, 15), Vector2(-13, 0),
	])
	_visual.material = _material
	add_child(_visual)

	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	collision.shape = circle
	add_child(collision)

	body_entered.connect(_on_body_entered)
	AudioManager.beat_detected.connect(_on_beat)

	var tween := create_tween().set_loops()
	tween.tween_property(_visual, "scale", Vector2(1.18, 1.18), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_visual, "scale", Vector2.ONE, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	# El brillo decae con el tiempo; cada beat lo reaviva.
	if _pulse > 0.0:
		_pulse = maxf(0.0, _pulse - delta * 2.2)
		_material.set_shader_parameter("pulse", _pulse)


func _on_beat(intensity: float) -> void:
	if not _collected:
		_pulse = minf(2.0, _pulse + 0.7 + intensity)


func _on_body_entered(body: Node2D) -> void:
	if _collected or body is not CharacterBody2D:
		return
	_collected = true
	GameState.fragments_collected += 1
	GameState.fragment_collected.emit(fragment_text)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "scale", Vector2(3.2, 3.2), 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)
