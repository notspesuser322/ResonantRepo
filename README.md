# Resonante

<p align="center">
  <img src="Base%20Files/Resonante%20Portada.png" alt="Portada de Resonante" width="480">
</p>

Un **plataformas rítmico-emocional**: la música no es fondo, es la mecánica.
Cada zona del mundo es una emoción — Ira, Miedo, Vacío, Culpa, Memoria — y sus
plataformas existen (o desaparecen) según el beat, la melodía o el silencio.
Inspirado en *GRIS*, *Journey*, *Sound Shapes* y *Ori*.

> 📄 Diseño completo en [`docs/GDD.md`](docs/GDD.md) (transcripción del documento original en `Base Files/`).

## Estado: Prototipo Fase 1 ✅ (en progreso)

Lo que ya funciona en este repo:

| Sistema del GDD | Implementación |
|---|---|
| §3 Analizador de frecuencias | `src/audio/audio_manager.gd` — FFT en tiempo real (beat, silencio, intensidad emocional) |
| §4 Plataformas rítmicas | `src/entities/beat_platform.gd` — tipos BEAT, SILENCE, RESONANT, GROUND (MELODY/ECHO/HARMONY en Fase 2) |
| §5 Fragmentos del yo | `src/entities/fragment.gd` — coleccionables con texto poético y brillo al ritmo |
| Movimiento fluido | `src/entities/player.gd` — coyote time, jump buffer, salto variable, squash & stretch |
| Zona de Ira | `src/zones/test_zone_ira.gd` + nivel como datos en `assets/data/levels/ira_test.json` |
| §6 Accesibilidad | Indicador visual de beat (círculo) + controles remapeables (`src/core/game_state.gd`) |
| Shaders | `shaders/resonant_pulse.gdshader` — brillo resonante de los fragmentos |

## Cómo abrirlo

1. Instala [Godot 4.3 o superior](https://godotengine.org/download) (no la versión 3.x).
2. Abre Godot → **Import** → selecciona el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (Run Project).

### Controles

| Tecla | Acción |
|---|---|
| `A` / `D` o `←` / `→` | Moverse |
| `Espacio` / `W` / `↑` | Saltar (con coyote time y buffer) |
| `R` | Reiniciar la zona |
| `M` | Silenciar |

### Qué probar en la Zona de Ira

- Las **plataformas rojas** pulsan con cada golpe del beat (kick). Se mantienen
  sólidas mientras la música suena.
- A mitad del tema hay un **breakdown en silencio** (~7 s): las plataformas rojas
  se desvanecen y aparecen las **azules** — la ruta alta solo existe en el silencio.
- La plataforma **ámbar** suena como campana al pisarla (resonante).
- Recoge los **2 fragmentos del yo** para cerrar el prototipo.

## Estructura

```
ResonantRepo/
├── project.godot            # Configuración Godot 4
├── scenes/                  # Escenas (.tscn)
├── src/
│   ├── core/                # GameState (progreso, controles)
│   ├── audio/               # AudioManager (ritmo, beats, silencios)
│   ├── entities/            # Jugador, plataformas, fragmentos
│   └── zones/               # Lógica por zona emocional
├── assets/
│   ├── audio/zones/         # Música por zona (placeholder generado)
│   ├── audio/effects/       # SFX (chime de plataformas resonantes)
│   └── data/levels/         # Niveles como datos (JSON)
├── shaders/                 # Efectos visuales
├── tools/                   # Scripts de desarrollo (Python)
├── docs/GDD.md              # Documento de diseño
└── Base Files/              # Documento original (PDF) y portada
```

## Música placeholder

El tema de la Zona de Ira (`assets/audio/zones/ira_placeholder.wav`) es un
**placeholder generado** — 140 BPM, kick + bajo distorsionado, con un breakdown
de silencio. Regenerarlo (o jugar con sus parámetros):

```bash
python3 tools/generate_placeholder_music.py
```

Cuando tengas música real (Burial/Max Richter vibes 🎧), simplemente reemplaza
el WAV en `assets/audio/zones/`.

## Ajustar la detección de ritmo

En `src/audio/audio_manager.gd`:

| Variable | Qué hace | Súbela si... |
|---|---|---|
| `beat_sensitivity` (1.30) | Energía > N × media local → beat | no detecta todos los golpes |
| `beat_cooldown` (0.20) | Tiempo mínimo entre beats | detecta doble beats |
| `silence_ratio` (0.035) | Umbral de silencio vs. máximo reciente | no entra en "silencio" |
| `silence_delay` (0.30) | Segundos bajo el umbral para declarar silencio | el silencio "parpadea" |

## CI (opcional)

En `tools/smoke-test-ci.yml` hay un workflow de GitHub Actions que descarga
Godot 4.3 headless, importa el proyecto y corre la escena principal buscando
errores. Para activarlo:

1. En GitHub, crea el archivo `.github/workflows/smoke-test.yml` con el
   contenido de `tools/smoke-test-ci.yml` (o cópialo localmente y haz commit).
2. A partir de ahí, cada push corre el smoke test automáticamente.

## Hoja de ruta (del GDD §7)

- [x] **Fase 1 — Prototipo técnico:** análisis de audio, una zona, plataformas rítmicas, movimiento fluido.
- [ ] Fase 1.1: estado DESTRUCTIVE, plataformas MELODY, ajuste fino de detección con música real.
- [ ] **Fase 2 — Vertical slice:** 3 zonas (Miedo, Vacío), sistema de fragmentos completo, audio por capas.
- [ ] **Fase 3 — Producción:** 5 zonas, narrativa completa, pulido, testing.

## ¿Por qué Godot?

El GDD original apuntaba a LÖVE, pero su núcleo (`source:getSpectrum()`) no
existe en LÖVE estable. Godot 4 trae `AudioEffectSpectrumAnalyzer` integrado —
el análisis de frecuencias en tiempo real que Resonante necesita — además de
shaders, partículas, audio posicional 2D y export multiplataforma, gratis y sin
regalías. Los detalles en el [apéndice del GDD](docs/GDD.md#apéndice--decisión-de-motor).
