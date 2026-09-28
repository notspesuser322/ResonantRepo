# Resonante — Documento de Diseño Técnico (GDD)

> Transcripción limpia del documento original (`Base Files/Resonante - Estructura del Juego.pdf`).
> El diseño original apuntaba a LÖVE; ver el [apéndice](#apéndice--decisión-de-motor) sobre la migración a Godot 4.

## 1. Estructura del Proyecto

Carpetas principales:

```
resonante/
├── assets/
│   ├── audio/
│   │   ├── zones/          # Música por zona emocional
│   │   ├── effects/        # SFX y stingers
│   │   └── ambient/        # Capas ambientales
│   ├── graphics/
│   │   ├── sprites/        # Siluetas y entidades
│   │   ├── particles/      # Sistemas de partículas
│   │   └── backgrounds/    # Fondos minimalistas
│   └── data/
│       ├── levels/         # Configuración de niveles
│       └── dialogue/       # Textos y símbolos narrativos
├── src/
│   ├── core/               # Sistema base del juego
│   ├── audio/              # Motor de audio y ritmo
│   ├── entities/           # Jugador, NPCs, plataformas
│   ├── zones/              # Lógica específica por zona emocional
│   └── ui/                 # Interfaz minimalista
└── shaders/                # Efectos visuales
```

## 2. Zonas Emocionales — Diseño Detallado

### 🔥 Zona de Ira (Rojo/Naranja)
- **Música:** Dubstep agresivo, bajos distorsionados.
- **Mecánicas:**
  - Plataformas que se activan con golpes fuertes del beat.
  - Puzzles que requieren timing explosivo.
- **Fragmentos del yo:** recuerdos de confrontación, frustración.
- **Desafío técnico:** sincronizar plataformas con transients de audio.

### 😨 Zona de Miedo (Azul oscuro/Violeta)
- **Música:** Ambient drone, silencios inquietantes.
- **Mecánicas:**
  - Plataformas que desaparecen en el silencio.
  - Enemigos que se mueven en contrarrítmo.
- **Fragmentos del yo:** traumas, inseguridades.
- **Desafío técnico:** detección de silencios y espacios negativos.

### 🕳 Zona de Vacío (Grises/Negro)
- **Música:** Minimalismo extremo, reverbs infinitos.
- **Mecánicas:**
  - Plataformas fantasma que solo existen en ecos.
  - Puzzles basados en delay y repetición.
- **Fragmentos del yo:** pérdida, ausencia, depresión.
- **Desafío técnico:** crear sensación de vacío sin aburrimiento.

### 😔 Zona de Culpa (Verde apagado/Sepia)
- **Música:** Melodías quebradas, instrumentos desafinados.
- **Mecánicas:**
  - Plataformas que se rompen al pisarlas repetidamente.
  - Puzzles de "deshacer" acciones pasadas.
- **Fragmentos del yo:** arrepentimiento, decisiones erróneas.

### 💭 Zona de Memoria (Colores desaturados, sepia)
- **Música:** Melodías familiares distorsionadas.
- **Mecánicas:**
  - Plataformas que cambian según "recuerdos" previos del nivel.
  - Puzzles que requieren recordar patrones musicales.
- **Fragmentos del yo:** nostalgia, identidad perdida.

## 3. Sistema de Audio Dinámico

Componentes clave:
1. **Analizador de frecuencias** — detectar beats, silencios, cambios de tono.
2. **Layering system** — múltiples pistas que se mezclan según el estado emocional.
3. **Procedural generation** — variaciones de los temas base según progreso.
4. **Spatial audio** — sonido posicional para crear inmersión.

Pseudo-código original del GDD (Lua/LÖVE):

```lua
function AudioManager:update(dt)
    local spectrum = self.source:getSpectrum()
    local beat_detected = self:detectBeat(spectrum)
    local emotional_intensity = self:analyzeEmotionalContent(spectrum)

    GameState:updateRhythmicElements(beat_detected, emotional_intensity)
end
```

## 4. Sistema de Plataformas Rítmicas

Tipos de plataformas:
- **Beat platforms:** se activan en el golpe fuerte.
- **Melody platforms:** siguen la línea melódica.
- **Silence platforms:** solo existen en pausas musicales.
- **Echo platforms:** aparecen como eco de acciones previas.
- **Harmony platforms:** requieren múltiples elementos sonoros.

Estados:
- **Sólida** (puede pisarse)
- **Fantasma** (atravesable)
- **Resonante** (amplifica el sonido al pisarla)
- **Destructiva** (se rompe tras uso)

## 5. Narrativa Ambiental

Métodos de storytelling:
- **Símbolos visuales:** iconografía simple que sugiere emociones.
- **Arquitectura emocional:** el level design cuenta la historia.
- **Fragmentos de texto:** frases cortas, poéticas, aparecen ocasionalmente.
- **Comportamiento de NPCs:** sus movimientos y reacciones narran sin palabras.

Progresión narrativa:
1. **Despertar:** confusión, movimientos torpes.
2. **Reconocimiento:** encuentro con el primer fragmento.
3. **Exploración:** descubrimiento de las zonas emocionales.
4. **Confrontación:** enfrentar los fragmentos más dolorosos.
5. **Resonancia:** armonizar con todos los aspectos del ser.
6. **Aceptación:** final ambiguo, catártico.

## 6. Consideraciones Técnicas

**Performance:**
- Sistema de LOD para partículas distantes.
- Streaming de audio para transiciones suaves.
- Pooling de objetos para plataformas dinámicas.

**Accesibilidad:**
- Opciones visuales para elementos rítmicos (jugadores con problemas auditivos).
- Controles remapeables.
- Velocidad de juego ajustable.

**Plataformas objetivo:**
- PC (Windows/Mac/Linux) — Prioridad 1.
- Consolas indie (Nintendo Switch) — futuro.
- Mobile — considerar adaptaciones de control.

## 7. Hitos de Desarrollo

**Fase 1 — Prototipo técnico (2-3 meses)**
- Sistema básico de audio analysis.
- Una zona emocional completa.
- Mecánicas de plataformas rítmicas básicas.
- Personaje con movimiento fluido.

**Fase 2 — Vertical slice (4-6 meses)**
- Tres zonas emocionales completas.
- Sistema de fragmentos básico.
- Audio dinámico inicial.
- Arte conceptual definido.

**Fase 3 — Producción (8-12 meses)**
- Todas las zonas emocionales.
- Sistema narrativo completo.
- Pulido de audio y visual.
- Testing y balance.

## 8. Recursos y Referencias

**Inspiración musical:**
- Burial — *Untrue* (ambient/dubstep emocional)
- Max Richter — soundtracks minimalistas
- Boards of Canada — nostalgia electrónica

**Referencias de juego:**
- Journey — narrativa sin palabras
- GRIS — emociones como mecánica
- Sound Shapes — plataformas rítmicas
- Ori series — movimiento fluido emocional

**Herramientas recomendadas:**
- Audio: Wwise o FMOD para audio avanzado
- Arte: Aseprite para pixel art, After Effects para partículas
- Level design: Ogmo Editor o Tiled Map Editor

---

## Apéndice — Decisión de motor

El GDD original se escribió pensando en **LÖVE**, con un pseudo-código que asume
`source:getSpectrum()`. Esa API **no existe en LÖVE estable (11.5)**: el análisis
de espectro en tiempo real habría que construirlo desde cero (FFT en Lua/FFI con
mapas de beat precalculados).

**Resonante se desarrolla en Godot 4**, que trae de fábrica lo que el diseño
necesita en su núcleo:

- `AudioServer` + `AudioEffectSpectrumAnalyzer` → FFT en tiempo real por rango
  de frecuencia (beats, silencios, energía emocional) sin dependencias externas.
- Buses de audio con efectos y envíos → layering dinámico.
- Shaders, partículas con LOD, audio 2D posicional (`AudioStreamPlayer2D`),
  UI y exportación a PC/web/móvil integrados.
- GDScript mantiene la filosofía del pseudo-código original (objetos ligeros,
  señales entre `AudioManager` y `GameState`).

El equivalente Godot del pseudo-código del GDD vive en `src/audio/audio_manager.gd`.
