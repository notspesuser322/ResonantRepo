extends Node
## AudioManager — motor de audio y ritmo de Resonante (GDD §3).
##
## Analiza en tiempo real el espectro de la música que suena en el bus "Music"
## usando el AudioEffectSpectrumAnalyzer de Godot, y emite señales que el resto
## del mundo usa para reaccionar:
##
##   beat_detected(intensity)  → un golpe fuerte pasó (kick / transient).
##   silence_started/ended     → la música entró en (o salió de) un silencio.
##   emotional_intensity_changed(v) → energía emocional normalizada 0..1.
##
## Nota histórica: el GDD original se pensó para LÖVE con un hipotético
## source:getSpectrum(). Esa API no existe en LÖVE estable; el equivalente real
## y sin dependencias es AudioServer + AudioEffectSpectrumAnalyzer en Godot 4.

signal beat_detected(intensity: float)
signal silence_started
signal silence_ended
signal emotional_intensity_changed(value: float)

const MUSIC_BUS_NAME := "Music"

# Bandas de frecuencia (Hz) que vigilamos.
const BASS_FROM := 20.0     # kick / bajo
const BASS_TO := 250.0
const FULL_FROM := 20.0     # energía total de la mezcla
const FULL_TO := 16000.0

# ---- Calibración (ajustable; ver README "Ajustar la detección") ----
var beat_sensitivity := 1.30    # energía > sensitivity × media local → beat
var beat_cooldown := 0.20       # segundos mínimos entre beats
var beat_floor_ratio := 0.05    # ignora picos < 5% del máximo reciente
var avg_window := 1.2           # ventana de media local (s)
var loud_window := 12.0         # ventana de máximo reciente (s) — memoria de la música
var silence_ratio := 0.035      # energía < 3.5% del máximo reciente → silencio
var silence_delay := 0.30       # s continuos bajo el umbral para declarar silencio

var in_silence := false
var emotional_intensity := 0.0

var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _avg_history: Array = []    # [tiempo, energía_bajo]
var _loud_history: Array = []   # [tiempo, energía_total]
var _since_beat := 1.0e9
var _silence_timer := 0.0
var _time := 0.0
var _music_player: AudioStreamPlayer
var _muted := false


func _ready() -> void:
	_setup_music_bus()
	var bus_idx := AudioServer.get_bus_index(MUSIC_BUS_NAME)
	_spectrum = AudioServer.get_bus_effect_instance(bus_idx, 0)


func _setup_music_bus() -> void:
	## Crea el bus "Music" con el analizador de espectro (idempotente).
	if AudioServer.get_bus_index(MUSIC_BUS_NAME) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, MUSIC_BUS_NAME)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.add_bus_effect(idx, AudioEffectSpectrumAnalyzer.new())


func _process(delta: float) -> void:
	if _spectrum == null:
		return
	_time += delta
	_since_beat += delta

	var bass := _spectrum.get_magnitude_for_frequency_range(BASS_FROM, BASS_TO)
	var full := _spectrum.get_magnitude_for_frequency_range(FULL_FROM, FULL_TO)
	var bass_energy := (bass.x + bass.y) * 0.5
	var full_energy := (full.x + full.y) * 0.5

	_avg_history.append([_time, bass_energy])
	_loud_history.append([_time, full_energy])
	_drop_old(_avg_history, avg_window)
	_drop_old(_loud_history, loud_window)

	var local_avg := _average(_avg_history)
	var recent_max := _max_value(_loud_history)

	# ---- Detección de beat (energía del bajo vs. media local) ----
	var floor_value := maxf(1.0e-7, recent_max * beat_floor_ratio)
	if _since_beat > beat_cooldown \
			and bass_energy > local_avg * beat_sensitivity \
			and bass_energy > floor_value:
		_since_beat = 0.0
		var intensity := clampf(bass_energy / maxf(recent_max, 1.0e-7), 0.0, 1.0)
		beat_detected.emit(intensity)

	# ---- Detección de silencio (GDD: "plataformas que desaparecen en el silencio") ----
	var silence_threshold := maxf(1.0e-7, recent_max * silence_ratio)
	if full_energy < silence_threshold:
		_silence_timer += delta
		if _silence_timer >= silence_delay and not in_silence:
			in_silence = true
			silence_started.emit()
	else:
		_silence_timer = 0.0
		if in_silence:
			in_silence = false
			silence_ended.emit()

	# ---- Intensidad emocional (suavizada, 0..1) ----
	var target := clampf(full_energy / maxf(recent_max, 1.0e-7), 0.0, 1.0)
	emotional_intensity = lerpf(emotional_intensity, target, clampf(delta * 4.0, 0.0, 1.0))
	emotional_intensity_changed.emit(emotional_intensity)


# ------------------------------------------------------------------ música --

func register_music_player(player: AudioStreamPlayer) -> void:
	## Registra el reproductor de música de la zona y lo loopea.
	_music_player = player
	player.finished.connect(_on_music_finished)


func _on_music_finished() -> void:
	## El audio es placeholder sin loop nativo: al terminar, reinicia.
	if _music_player != null and not _music_player.playing:
		_music_player.play()


func toggle_mute() -> void:
	_muted = not _muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS_NAME), _muted)
	AudioServer.set_bus_mute(0, _muted)


# --------------------------------------------------------------- utilidades --

func _drop_old(arr: Array, seconds: float) -> void:
	while arr.size() > 0 and _time - float(arr[0][0]) > seconds:
		arr.pop_front()


func _average(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var sum := 0.0
	for entry in arr:
		sum += float(entry[1])
	return sum / arr.size()


func _max_value(arr: Array) -> float:
	var maximum := 0.0
	for entry in arr:
		maximum = maxf(maximum, float(entry[1]))
	return maximum
