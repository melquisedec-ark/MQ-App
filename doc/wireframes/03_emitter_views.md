# Wireframe 03 — Vistas del Emisor (Emitter)

> **Modo:** Emisor (controla remotamente un Receptor en PC/TV)
> **Aplica a:** Biblia + Himnario
> **Archivos destino (Flutter):**
> - `lib/presentation/dual_mode_wrapper/emitter/emitter_screen.dart`
> - `lib/presentation/dual_mode_wrapper/emitter/views/compact_view.dart`
> - `lib/presentation/dual_mode_wrapper/emitter/views/preview_view.dart`
> **Versión:** MQ App v1.0
> **Referencia:** `nuevaidea.md` §6.5, §6.6 + revisión v1.4
> **Idioma:** Español (es-419)

---

## Visión general

El **emisor** es la app que controla la presentación (típicamente un celular). El **receptor** es la pantalla grande (PC/TV/proyector) que muestra el contenido al público.

El emisor tiene **2 vistas alternativas** para cada módulo:

1. **COMPACT** (default) — Solo números/referencias. Rápido, ligero, ideal cuando el presentador ya sabe qué sigue.
2. **PREVIEW** — Muestra el texto completo del versículo/estrofa actual, anterior y siguiente. Útil cuando el presentador quiere ver qué viene antes de enviarlo.

> **Beneficio clave del modo Preview** (textual del spec §6.5): *"No más pasar verguenza buscando el versículo en la pantalla de proyección. El presentador ve desde su celular qué dice el siguiente versículo y solo presiona 'ENVIAR SIG.' cuando está listo."*

---

# Vista COMPACT — Biblia

## Layout

```
+--------------------------------+
|                                |
|  [icon-cast]  Presentando  [O] |  <- Header
|                                |
|  Genesis 1                     |  <- Referencia
|                                |
+--------------------------------+
|                                |
|         v. 5                   |  <- Versiculo actual
|                                |
|     " Y fue la luz..."         |  <- Preview mini (1 linea)
|                                |
+--------------------------------+
|                                |
|   [< Ant.]   [  SIGUIENTE  ]  |  <- Navegacion
|                                |
+--------------------------------+
|                                |
|  Capitulos:  [<]  1  [>]       |  <- Cap selector
|                                |
|  Vers: 1 2 3 4 [5] 6 7 8 9     |  <- Verse selector (chip del actual)
|                                |
+--------------------------------+
```

## Elementos

| Elemento | Comportamiento |
|----------|----------------|
| `[icon-cast]` | Icono que indica que se está controlando un receptor. Color = gold si conectado. |
| `Presentando` | Texto + nombre del receptor (e.g., "Presentando: Sala Principal"). Tap = ver info del receptor. |
| `[O]` | Botón settings (⚙) del emisor. **Cambia entre COMPACT y PREVIEW** + otras opciones del emisor. |
| `Genesis 1` | Referencia actual (libro + capítulo). 16sp, bold. |
| `v. 5` | Versículo actual. 48sp, ultra-bold, gold. |
| `" Y fue la luz..."` | **Preview mini** — 1 línea truncada del texto del versículo. Aparece debajo del número. Si el versículo es muy corto, solo se muestra el número. |
| `[< Ant.]` | Botón outlined. Tap = versículo anterior. |
| `[SIGUIENTE]` | Botón filled (gold, primary). Tap = versículo siguiente. **El "ENVIAR" se hace implícitamente al hacer tap** (el receptor se actualiza en tiempo real). |
| Selector de capítulo `[<] 1 [>]` | Cambia el capítulo actual. Tap en el número = input numérico. |
| Selector de versículos `1 2 3 4 [5] 6 7 8 9` | Chips horizontales scrollables. El actual = gold. Tap = salta a ese versículo. |

### Sincronización

- El emisor **siempre refleja el estado del receptor** (vía `WatchStatus` stream).
- Si el receptor cambia (e.g., el operador del PC salta a otro versículo), el emisor se actualiza.
- **No hay "ENVIAR" explícito** en compact — todo es directo.

---

# Vista PREVIEW — Biblia

## Layout

```
+--------------------------------+
|                                |
|  [icon-cast]  Presentando  [O] |  <- Header
|                                |
|  Genesis 1                     |
|                                |
+--------------------------------+
|  ACTUAL: v. 5                  |
|                                |
|  "Y fue la luz; y fue la       |
|   luz."                        |
|                                |
+--------------------------------+
|  SIGUIENTE: v. 6               |
|                                |
|  "Y vio Dios que la luz era    |
|   buena; y separo la luz de    |
|   las tinieblas."              |
|                                |
|   [< Ant.]    [  ENVIAR SIG. ]|  <- "Enviar" explicito
|                                |
+--------------------------------+
|  ANTERIOR: v. 4                |
|                                |
|  "Y vio Dios que la luz era    |
|   buena..."                    |
|                                |
+--------------------------------+
```

## Diferencias clave vs COMPACT

| Aspecto | COMPACT | PREVIEW |
|---------|---------|---------|
| **Botón de acción** | "SIGUIENTE" (envío implícito) | "ENVIAR SIG." (envío explícito, da tiempo a verificar) |
| **Texto mostrado** | Solo número + 1 línea preview | Texto completo del anterior, actual y siguiente |
| **Chips de versículos** | Sí (selector rápido) | NO (no hacen falta — el preview ya muestra el contexto) |
| **Tamaño del número** | 48sp | 20sp (porque hay más contenido) |
| **Casos de uso** | Cuando el presentador ya sabe qué sigue | Cuando el presentador quiere ver el versículo antes de enviarlo |

## Datos necesarios

El receptor envía al emisor (vía `WatchStatus` stream):

```dart
StatusUpdate {
  module_info: BIBLE,
  current_ref: "Genesis 1:5",
  current_text: "Y fue la luz; y fue la luz.",
  next_verse_number: 6,
  next_verse_text: "Y vio Dios que la luz era buena...",
  prev_verse_number: 4,
  prev_verse_text: "Y vio Dios que la luz era buena...",
}
```

> **Optimización de red:** Solo se envía `next_text` y `prev_text` cuando el emisor está en modo PREVIEW. En modo COMPACT, no se transmiten (ahorra ancho de banda en LAN).

---

# Vista COMPACT — Himnario

## Layout

```
+--------------------------------+
|                                |
|  [icon-cast]  Presentando  [O] |
|                                |
|  Himno 45                      |
|  "Castillo Fuerte"             |
|                                |
+--------------------------------+
|                                |
|       Estrofa 2                |  <- Estrofa actual
|       de 4                     |
|                                |
+--------------------------------+
|                                |
|   [< Ant.]   [  SIGUIENTE  ]  |
|                                |
+--------------------------------+
```

### Elementos

| Elemento | Comportamiento |
|----------|----------------|
| `Himno 45` | Número del himno. 32sp, bold. |
| `"Castillo Fuerte"` | Título. 14sp, color secundario. |
| `Estrofa 2 de 4` | Posición. 48sp, ultra-bold, gold. |
| `[< Ant.]` | Estrofa anterior. |
| `[SIGUIENTE]` | Siguiente estrofa. |

---

# Vista PREVIEW — Himnario

## Layout

```
+--------------------------------+
|                                |
|  [icon-cast]  Presentando  [O] |
|                                |
|  Himno 45                      |
|  "Castillo Fuerte"             |
|                                |
+--------------------------------+
|  ACTUAL - Estrofa 2:           |
|                                |
|  "Castillo fuerte es nuestro   |
|   Dios, defensa y refugio     |
|   nuestro; con su diestra      |
|   poderosa vence al enemigo."  |
|                                |
+--------------------------------+
|  SIGUIENTE - Estrofa 3:        |
|                                |
|  "Contra el mundo con sus     |
|   fuerzas, contra el mal..."   |
|                                |
|   [< Ant.]    [  ENVIAR SIG. ]|
|                                |
+--------------------------------+
```

### Elementos

- Estructura análoga a PREVIEW Biblia.
- Muestra estrofa anterior (parcial, últimas 2 líneas) + actual (completa) + siguiente (parcial, 2 primeras líneas) para himnos largos.

---

# Cambio de modo (Compact ↔ Preview)

## Trigger

Tap en el botón `[O]` (esquina superior del emisor) → abre un **bottom sheet**:

```
+----------------------------------------------------------------------------+
|                                                                            |
|   +------------------------------------------------------------------------+|
|   |                                                                          ||
|   |   Vista del emisor                                                       ||
|   |                                                                          ||
|   |   [check]  Compacto                                                      ||
|   |             Solo numeros, rapido y ligero                                ||
|   |                                                                          ||
|   |   [   ]   Preview                                                        ||
|   |             Muestra el texto del versiculo/estrofa                      ||
|   |                                                                          ||
|   |   --- Configuracion ---                                                  ||
|   |                                                                          ||
|   |   [toggle] Vibracion al cambiar de versiculo                             ||
|   |   [toggle] Sonido al enviar                                              ||
|   |                                                                          ||
|   |   [X]  Cerrar                                                            ||
|   |                                                                          ||
|   +------------------------------------------------------------------------+|
|                                                                            |
+----------------------------------------------------------------------------+
```

## Persistencia

- La elección (COMPACT/PREVIEW) se guarda en `Configuracion.emitter_view_mode`.
- **Se aplica por usuario, no por dispositivo.** Si el usuario tiene 2 celulares, ambos usan el mismo modo.
- **Default: COMPACT** (más rápido, menor uso de datos).

---

# Cambio dinámico de módulo (Biblia ↔ Himnario)

Cuando el receptor cambia de Biblia a Himnario (o viceversa), el emisor **recibe un evento** (`ModuleInfo.module`) y su UI se reconfigura automáticamente:

```
+--------------------------------+
|                                |
|  [icon-cast]  Presentando  [O] |
|                                |
|  BIBLIA -> HIMNARIO            |  <- Banner temporal (3s)
|                                |
+--------------------------------+
|                                |
|  Himno 45                      |  <- Ahora muestra himno
|  "Castillo Fuerte"             |
|                                |
+--------------------------------+
```

- El banner es **discrete** (no modal) — el usuario lo ve, sabe qué pasó, y desaparece.
- Los controles de la parte inferior se reconfiguran (versículos → estrofas, etc.).

---

# Acciones rápidas (FAB o long press)

En COMPACT, el emisor puede tener un **FAB** (Floating Action Button) con acciones rápidas:

```
                                +---+
                                | ? |  <- FAB
                                +---+
                                  |
                                  v
                            [ Aleatorio ]
                            [ Blackout  ]
                            [ Desconectar ]
```

- **Aleatorio:** Salta a un versículo/estrofa aleatorio dentro del módulo actual.
- **Blackout:** Oscurece la pantalla del receptor (útil entre lecturas).
- **Desconectar:** Cierra la sesión emisor.

---

# Estados especiales

## Sin conexión (perdió conexión con el receptor)

```
+--------------------------------+
|                                |
|  [!]  SIN CONEXION             |
|                                |
|  No se puede contactar al      |
|  receptor. Verifica la red.    |
|                                |
|       [ Reintentar ]            |
|                                |
+--------------------------------+
```

- El emisor **NO crashea** — sigue siendo navegable localmente (puedes leer en tu celular).
- Al recuperar conexión, sincroniza automáticamente.

## Receptor en pantalla principal (no está presentando)

```
+--------------------------------+
|                                |
|  Receptor en Home              |
|                                |
|  El receptor esta en la        |
|  pantalla principal.           |
|                                |
|  [ Enviar a Biblia ]           |
|  [ Enviar a Himnario ]         |
|                                |
+--------------------------------+
```

- Solo 2 acciones disponibles: enviar a Biblia o a Himnario.
- Ver spec §6.2 (tabla de comandos por estado del receptor).

---

# Responsive

## Portrait (celular, default)

- Layouts mostrados arriba. Optimizado para una mano.

## Landscape (celular, opcional)

- En landscape, el modo PREVIEW muestra actual + siguiente en **2 columnas** lado a lado:

```
+----------------------------------+
|                                  |
|  ACTUAL: v. 5      |  SIGUIENTE: v. 6
|                   |
|  "Y fue la luz;   |  "Y vio Dios que la luz
|   y fue la luz."  |   era buena; y separo la
|                   |   luz de las tinieblas."
|                   |
|        [< Ant.]    [  ENVIAR SIG. ]
+----------------------------------+
```

## Tablet (≥ 600dp)

- El emisor se muestra **al lado** de un mini-preview del receptor (sincronizado).
- Útil en tablets usadas en el púlpito (algunos pastores usan iPad en vez de celular).

## Desktop (≥ 1024dp)

- Similar a tablet, pero con más espacio para stats:
  - Tiempo en el versículo actual
  - Historial de últimos 5 versículos enviados
  - Botón "Enviar a Biblia/Himnario" siempre visible

---

# Accesibilidad

- **Botones grandes** (mínimo 56x56dp) — el emisor se usa bajo presión.
- **Alto contraste** — el receptor proyecta, el emisor tiene la luz baja del culto.
- **Vibración háptica** al cambiar versículo (configurable).
- **Atajos de voz** (futuro, v2.0): "Siguiente", "Anterior", "Favorito" — no en v1.0.
- **Lectura por screen reader** de los versículos preview (importante para presentadores con discapacidad visual — poco común pero posible).

---

# Datos de red (importante para @arqui)

## Stream `WatchStatus` debe enviar:

| Campo | COMPACT | PREVIEW | Notas |
|-------|---------|---------|-------|
| `module_info` | ✅ | ✅ | HOME, BIBLE, HYMNAL, PRESENTATION_* |
| `current_ref` | ✅ | ✅ | "Genesis 1:5" o "Himno 45 - Estrofa 2" |
| `current_verse_number` | ✅ | ✅ | int32 |
| `current_text` | ❌ | ✅ | Solo en PREVIEW |
| `next_verse_number` | ✅ (chip) | ✅ | int32 |
| `next_text` | ❌ | ✅ | Solo en PREVIEW |
| `prev_verse_number` | ❌ | ✅ | int32 |
| `prev_text` | ❌ | ✅ | Solo en PREVIEW |
| `is_blackout` | ✅ | ✅ | bool |
| `is_favorite` | ✅ | ✅ | bool (solo Biblia) |

**Tasa de actualización:** 1 update por cambio de versículo/estrofa. NO streaming continuo. Esto evita saturar la LAN en WiFi saturados (cultos con 50+ devices).

---

# Preguntas abiertas para el usuario

1. **¿El modo PREVIEW debe ser el default en celular y COMPACT en tablet?** Sugerencia: ambos usan el default del usuario (no por dispositivo).
2. **¿La transición entre COMPACT y PREVIEW debe ser animada** o instantánea? (Sugerencia: 300ms fade).
3. **¿El "ENVIAR SIG." debe pedir confirmación** en modo PREVIEW, o el preview ya es la confirmación? (Sugerencia: NO pide confirmación — el preview es la confirmación visual).
4. **¿El FAB debe ser siempre visible** u oculto detrás de un long press? (Sugerencia: siempre visible — el emisor debe ser rápido).
5. **¿El modo PREVIEW debe estar disponible también para Biblia en Capítulos completos**, o solo versículo por versículo? (Sugerencia: solo versículo por versículo — el emisor controla 1 versículo a la vez).

---

*Wireframe creado por @design — pendiente revisión de @arqui y del usuario antes de implementar.*
