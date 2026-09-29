extends Node2D
## Zona de Ira — slice vertical del prototipo (Fase 1 del GDD).
##
## 🔥 "Plataformas que se activan con golpes fuertes del beat" → plataformas BEAT.
## "Plataformas que desaparecen en el silencio" (Zona de Miedo) → aquí se
##    ensayan como ruta alterna SILENCE durante el breakdown del tema.
## El nivel se define como datos: assets/data/levels/ira_test.json.

const LEVEL_PATH := "res://assets/data/levels/ira_test.json"

var _music: AudioStreamPlayer
var _energy_fill: ColorRect
var _beat_dot: Polygon2D
var _silence_label: Label
var _fragment_count_label: Label
var _poetic_label: Label
var _label_tween: Tween
var _fragments_total := 0


func _ready() -> void:
	var level := _load_level(LEVEL_PATH)
	_build_background()
	_build_level(level)
	_build_music(level)
	_build_hud(level)
	_connect_signals()


func _process(_delta: float) -> void:
	_energy_fill.size.x = 4.0 + 196.0 * AudioManager.emotional_intensity


# ---------------------------------------------------------------- construcción --

func _load_level(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "No se pudo abrir el nivel: " + path)
	var data = JSON.parse_string(file.get_as_text())
	assert(data is Dictionary, "JSON inválido en " + path)
	return data


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -100
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color(0.06, 0.025, 0.035)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)


func _build_level(level: Dictionary) -> void:
	for platform_data in level.get("platforms", []):
		var platform := BeatPlatform.new()
		var type_name := String(platform_data.get("type", "beat")).to_upper()
		platform.platform_type = BeatPlatform.PlatformType.get(
			type_name, BeatPlatform.PlatformType.BEAT)
		var size_data: Array = platform_data.get("size", [120, 16])
		platform.size = Vector2(size_data[0], size_data[1])
		var position_data: Array = platform_data.get("pos", [0, 0])
		platform.position = Vector2(position_data[0], position_data[1])
		add_child(platform)

	var start: Array = level.get("player_start", [70, 500])
	var player := ResonaPlayer.new()
	player.position = Vector2(start[0], start[1])
	add_child(player)

	for fragment_data in level.get("fragments", []):
		var fragment := SoulFragment.new()
		fragment.fragment_text = String(fragment_data.get("text", ""))
		var fragment_position: Array = fragment_data.get("pos", [0, 0])
		fragment.position = Vector2(fragment_position[0], fragment_position[1])
		add_child(fragment)
		_fragments_total += 1


func _build_music(level: Dictionary) -> void:
	_music = AudioStreamPlayer.new()
	_music.stream = load(String(level.get("music", "")))
	_music.bus = "Music"
	_music.volume_db = -4.0
	add_child(_music)
	AudioManager.register_music_player(_music)
	_music.play()


func _build_hud(level: Dictionary) -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var title := Label.new()
	var level_title := String(level.get("title", "RESONANTE"))
	var level_subtitle := String(level.get("subtitle", ""))
	title.text = "%s\n%s" % [level_title, level_subtitle]
	title.position = Vector2(16, 10)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.45, 0.3))
	hud.add_child(title)

	var controls := Label.new()
	controls.text = "A/D o ←/→ moverse · ESPACIO saltar · R reiniciar · M silenciar"
	controls.position = Vector2(16, 692)
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.6, 0.5, 0.48))
	hud.add_child(controls)

	# Indicador visual de beat (accesibilidad rítmica, GDD §6).
	_beat_dot = Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(10):
		var angle := TAU * i / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * 13.0)
	_beat_dot.polygon = points
	_beat_dot.position = Vector2(640, 64)
	_beat_dot.color = Color(0.75, 0.28, 0.16)
	hud.add_child(_beat_dot)

	# Barra de intensidad emocional.
	var bar_background := ColorRect.new()
	bar_background.position = Vector2(540, 676)
	bar_background.size = Vector2(200, 8)
	bar_background.color = Color(0.18, 0.10, 0.10)
	hud.add_child(bar_background)
	_energy_fill = ColorRect.new()
	_energy_fill.position = Vector2(540, 676)
	_energy_fill.size = Vector2(4, 8)
	_energy_fill.color = Color(0.95, 0.35, 0.18)
	hud.add_child(_energy_fill)

	_fragment_count_label = Label.new()
	_fragment_count_label.text = "Fragmentos del yo: 0/%d" % _fragments_total
	_fragment_count_label.position = Vector2(1000, 10)
	_fragment_count_label.add_theme_font_size_override("font_size", 15)
	_fragment_count_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))
	hud.add_child(_fragment_count_label)

	_silence_label = Label.new()
	_silence_label.text = "· silencio ·"
	_silence_label.position = Vector2(560, 88)
	_silence_label.size = Vector2(160, 24)
	_silence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_silence_label.add_theme_font_size_override("font_size", 15)
	_silence_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.95))
	_silence_label.modulate.a = 0.0
	hud.add_child(_silence_label)

	_poetic_label = Label.new()
	_poetic_label.position = Vector2(140, 300)
	_poetic_label.size = Vector2(1000, 90)
	_poetic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_poetic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_poetic_label.add_theme_font_size_override("font_size", 24)
	_poetic_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
	_poetic_label.modulate.a = 0.0
	hud.add_child(_poetic_label)

	# Título de intro.
	var intro := Label.new()
	intro.text = "R E S O N A N T E"
	intro.position = Vector2(140, 200)
	intro.size = Vector2(1000, 120)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", 52)
	intro.add_theme_color_override("font_color", Color(1.0, 0.5, 0.35))
	hud.add_child(intro)
	var intro_tween := create_tween()
	intro_tween.tween_interval(2.5)
	intro_tween.tween_property(intro, "modulate:a", 0.0, 1.2)
	intro_tween.tween_callback(intro.queue_free)


func _connect_signals() -> void:
	AudioManager.beat_detected.connect(_on_beat)
	AudioManager.silence_started.connect(_on_silence.bind(true))
	AudioManager.silence_ended.connect(_on_silence.bind(false))
	GameState.fragment_collected.connect(_on_fragment_collected)


# --------------------------------------------------------------------- eventos --

func _on_beat(intensity: float) -> void:
	_beat_dot.scale = Vector2.ONE * (1.25 + intensity * 0.6)
	_beat_dot.modulate = Color(1.8, 1.0, 0.75)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_beat_dot, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_beat_dot, "modulate", Color(0.75, 0.28, 0.16), 0.20)


func _on_silence(silent: bool) -> void:
	var target := 1.0 if silent else 0.0
	var tween := create_tween()
	tween.tween_property(_silence_label, "modulate:a", target, 0.2)


func _on_fragment_collected(text: String) -> void:
	_fragment_count_label.text = "Fragmentos del yo: %d/%d" % [
		GameState.fragments_collected, _fragments_total]

	if _label_tween != null and _label_tween.is_valid():
		_label_tween.kill()
	_poetic_label.text = text
	_label_tween = create_tween()
	_label_tween.tween_property(_poetic_label, "modulate:a", 1.0, 0.4)
	_label_tween.tween_interval(3.2)
	_label_tween.tween_property(_poetic_label, "modulate:a", 0.0, 1.2)

	if GameState.fragments_collected >= _fragments_total:
		_label_tween.tween_interval(1.0)
		_label_tween.tween_callback(_show_end_message)


func _show_end_message() -> void:
	_poetic_label.text = "La Ira empieza a escucharte.\nFin del prototipo — Fase 1"
	_label_tween = create_tween()
	_label_tween.tween_property(_poetic_label, "modulate:a", 1.0, 0.8)
