extends Node
## GameState — estado global de Resonante (GDD §1, src/core).
##
## Espejo del GameState del GDD: recibe beats e intensidad emocional del
## AudioManager, lleva el progreso (fragmentos del yo) y define los controles
## de forma remapeable (GDD §6 Accesibilidad).

signal fragment_collected(text: String)

# Controles (remapeables: GDD §6). Se registran al arrancar.
const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE, KEY_W, KEY_UP],
	"respawn": [KEY_R],
	"mute": [KEY_M],
}

var emotional_intensity := 0.0
var fragments_collected := 0
var beats_total := 0


func _ready() -> void:
	_setup_input()
	AudioManager.beat_detected.connect(_on_beat_detected)
	AudioManager.emotional_intensity_changed.connect(_on_emotional_intensity)


func _setup_input() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("respawn"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("mute"):
		AudioManager.toggle_mute()


func _on_beat_detected(_intensity: float) -> void:
	beats_total += 1
	update_rhythmic_elements(true, emotional_intensity)


func _on_emotional_intensity(value: float) -> void:
	emotional_intensity = value
	update_rhythmic_elements(false, value)


func update_rhythmic_elements(_beat_detected: bool, _intensity: float) -> void:
	## Hook central del GDD: el mundo reacciona al ritmo. Las zonas y
	## plataformas se conectan directamente a las señales del AudioManager;
	## aquí vive la lógica global (futuro: capas de música procedural, etc.).
	pass
