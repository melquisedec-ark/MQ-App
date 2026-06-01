# Decisiones arquitectónicas de MQ-App (Fase 1)

> **Proyecto:** MQ-App (Biblia RV1909 + RV1569 + Himnario heredado de HimnarioID 2.0)
> **Fase:** 1 — Fundación
> **Período:** 29 de mayo — 1 de junio de 2026
> **Mantenedor:** @documentador, en sesión con @arqui

Este documento registra las **12 decisiones arquitectónicas** tomadas durante
la Fase 1. Cada entrada sigue el formato: **Contexto** → **Opciones
consideradas** → **Decisión** → **Rationale** → **Fecha** → **Decidido por**.

El propósito es que un futuro contributor (o el propio @user al volver
después de meses) pueda entender **por qué** las cosas son como son, no solo
**qué** son. Las decisiones con impacto técnico profundo incluyen un bloque
"Consecuencias" final.

---

## Índice de decisiones

| #  | Decisión                                                   | Decidido por |
|----|------------------------------------------------------------|--------------|
| 1  | Stack: Flutter + Riverpod 2.x + gRPC + mDNS + FFI SQLite   | @arqui       |
| 2  | Schema de Biblia: 6 tablas normalizadas (3FN)              | @back        |
| 3  | FTS5 con `content='versiculo'` + `remove_diacritics 2`     | @back        |
| 4  | SQLite 3.46+ bundleado vía FFI en TODAS las plataformas    | @arqui       |
| 5  | DBs separadas: `mqapp.db` + `biblia.db`                    | @arqui       |
| 6  | Paleta de color Opción B: Gold / Negro / Blanco            | @design, @arqui |
| 7  | Glassmorphism selectivo: sí en cards, no en nav/compact    | @design      |
| 8  | Emisor con dos vistas: COMPACT (números) + PREVIEW (texto) | @design, @arqui |
| 9  | Notas: 1 por versículo, color-coded (amar./ver./azul)      | @design, @back |
| 10 | Versículo aleatorio al abrir la app (no "verse del día")   | @design, @user |
| 11 | Bundle ID `com.mqapp` (no `com.example.*`)                 | @arqui       |
| 12 | Config en tabla SQLite (no `SharedPreferences`)            | @arqui, @back |

---

## 1. Stack: Flutter + Riverpod 2.x + gRPC + mDNS + SQLite FFI

**Contexto:** MQ-App requiere soporte multiplataforma (Windows, macOS, Linux,
Android, iOS), un canal de control remoto LAN (emisor/receptor), búsqueda
full-text sobre 62 000 versículos bíblicos, y persistencia local robusta. El
punto de partida es la base de HimnarioID 2.0 v2.1.7 (ya validada en
producción).

**Opciones consideradas:**

- **A) Mantener el stack de HimnarioID 2.0** (Flutter + Riverpod 2.x + gRPC
  + mDNS + sqflite clásico) — score 8.5/10 de @arqui.
- **B) Migrar a BLoC + REST + Bluetooth** — alternativa "limpia", pero
  requiere reescribir 8 000+ líneas probadas.
- **C) Migrar a Provider + Firebase + Cloud DB** — descartado: choca con
  el requisito de "funciona sin internet en LAN cerrada".

**Decisión:** Mantener el stack de HimnarioID 2.0 con un único cambio:
migrar `sqflite` clásico a `sqflite_common_ffi` (ver decisión 4).

**Rationale:** Reutilizar 95% de código ya validado minimiza riesgo. Riverpod
2.x tiene mejor testabilidad que BLoC. gRPC sobre LAN es 3-5x más rápido que
REST. mDNS elimina configuración manual de IPs. Bluetooth está descartado
por alcance y latencia.

**Fecha:** 30 de mayo de 2026 (Sesión 2, review de @arqui).
**Decidido por:** @arqui (chief architect).

---

## 2. Schema de Biblia: 6 tablas normalizadas (3FN)

**Contexto:** El módulo Biblia almacena dos versiones (RV1909 + RV1569) con
66 libros, ~1 189 capítulos y ~31 102 versículos por versión. Es necesario
almacenar también favoritos, notas e historial de lectura. La pregunta clave
es: ¿una mega-tabla plana o un modelo relacional normalizado?

**Opciones consideradas:**

- **A) Tabla plana única `versiculo(version, libro, cap, num, texto)`** con
  índices. Simple, pero duplica el texto del libro en cada versión.
- **B) 4 tablas núcleo (`version` → `libro` → `capitulo` → `versiculo`) +
  4 tablas de usuario (`favorito_versiculo`, `nota`, `historial_versiculo`,
  `config`)** — modelo normalizado en tercera forma normal.
- **C) Versión desnormalizada con JSON embebido** — útil para NoSQL, no
  para SQL relacional.

**Decisión:** Opción B. Las 6 tablas núcleo + 2 de bookkeeping (`config`,
`schema_version`) están definidas en
`assets/db/schema/001_biblia_schema.sql`.

**Rationale:** La normalización 3FN permite cambiar el texto de un versículo
en una versión sin tocar las otras, evita duplicación (~10 MB ahorrados), y
escala bien para añadir una tercera versión (RVR1960, NVI, etc.) en el
futuro. El JOIN costo es despreciable en <100 ms para 62 K filas en SQLite
local.

**Consecuencia:** Las queries requieren JOINs de 2-4 tablas. Se mitiga con
índices apropiados (ver `DATABASE_SCHEMA.md` § Índices).

**Fecha:** 30 de mayo de 2026 (Sesión 2-3, diseño de @back).
**Decidido por:** @back, con aprobación de @arqui.

---

## 3. FTS5 con `content='versiculo'` + `remove_diacritics 2`

**Contexto:** La búsqueda debe ser instantánea, acento-insensible
("José" == "jose") y no inflar el tamaño de la DB. SQLite ofrece FTS5 (motor
full-text nativo desde 3.9).

**Opciones consideradas:**

- **A) `LIKE '%texto%'` con `COLLATE NOCASE`** — simple, pero sin índice:
  O(n) en cada búsqueda, inaceptable para 62 K filas.
- **B) FTS5 standalone** (índice duplica el texto) — fácil de configurar
  pero duplica ~15 MB de texto bíblico.
- **C) FTS5 con `content='versiculo'` (external content) +
  `tokenize='unicode61 remove_diacritics 2'`** — el índice apunta a
  `versiculo.id` por rowid, sin duplicar texto.
- **D) Librería externa (ej. `sqlite_fts_ngram`)** — descarta
  portabilidad.

**Decisión:** Opción C.

**Rationale:** `content='versiculo'` ahorra ~10 MB al no duplicar el texto.
`remove_diacritics 2` (requiere SQLite 3.39+) es **crítico** en móvil: el
teclado en pantalla omite tildes en la mayoría de los casos. Los triggers
de sincronización (3: `versiculo_ai`, `_ad`, `_au`) son obligatorios
— documentados explícitamente en el header del SQL.

**Consecuencia:** Cualquier acceso directo a la DB desde fuera del cliente
debe respetar el orden INSERT → trigger → FTS sync. La DB **no es**
modificable manualmente con `sqlite3` CLI sin recrear los triggers.

**Fecha:** 30 de mayo de 2026.
**Decidido por:** @back, con validación de @arqui.

---

## 4. SQLite 3.46+ bundleado vía FFI en TODAS las plataformas

**Contexto:** La opción `remove_diacritics 2` de FTS5 requiere SQLite
3.39.0+ (junio 2022). Pero:

- iOS 12-15 usa la libsqlite3 del sistema (3.32-3.39).
- Android < 14 también usa libsqlite3 del sistema (< 3.39).
- Esto significa que el ~30% de dispositivos activos en 2026 no tendrían
  búsqueda acento-insensible.

**Opciones consideradas:**

- **A) Confiar en libsqlite3 del sistema** + verificar versión al inicio
  + degradar a búsqueda sin acentos en sistemas viejos. Riesgoso y
  requiere dos code paths.
- **B) Bundlear libsqlite3 solo en Android** (donde el problema es más
  agudo). Doble code path, bugs garantizados.
- **C) Bundlear libsqlite3 en TODAS las plataformas** vía
  `sqflite_common_ffi` + `sqlite3_flutter_libs: ^0.5.0` — la lib se
  incluye en el binario, no se usa la del sistema.

**Decisión:** Opción C.

**Rationale:** +2 MB al APK vale la pena por consistencia absoluta. Un solo
code path, una sola versión de SQLite (3.46) garantizada. @arqui evaluó
el trade-off y lo aprobó explícitamente.

**Consecuencia:** El APK final pesa 164 MB (debug, sin optimización). En
release con `flutter build apk --release --split-per-abi` baja a ~25-30 MB
por ABI. El binario nativo se carga con `open.overrideFor(...)` en
`lib/core/database/database_helper.dart`.

**Fecha:** 31 de mayo de 2026.
**Decidido por:** @arqui. Implementado por @dev (commit `52a6275`).

---

## 5. DBs separadas: `mqapp.db` + `biblia.db`

**Contexto:** HimnarioID 2.0 ya tiene una DB operativa (`mqapp.db` con
~15 000 himnos y metadatos). El módulo Biblia necesitará ~5-7 MB adicionales
de versículos. ¿Una sola DB o dos?

**Opciones consideradas:**

- **A) Una sola DB "mega"** con tablas de himnario y de biblia mezcladas.
  Problema: backups monolíticos, cualquier cambio de schema afecta a los
  dos módulos.
- **B) Dos DBs separadas** + queries cross-DB con `ATTACH DATABASE`.
  Complejo y no soportado nativamente en `sqflite_common_ffi`.
- **C) Dos DBs independientes** (`mqapp.db` para himnario, `biblia.db`
  para Biblia). Cada `DatabaseHelper` abre la suya, sin cross-DB JOINs.

**Decisión:** Opción C.

**Rationale:** Separación de concerns: el equipo de himnario no necesita
saber del schema de Biblia, y viceversa. Backups granulares (un usuario
podría restaurar solo sus notas de Biblia sin tocar himnario). Cada DB
puede tener su propio ciclo de migraciones.

**Consecuencia:** Las queries que necesitan datos de ambos módulos
(extremadamente raras, ej. "himno inspirado en Juan 3:16") requieren
abrir dos conexiones en paralelo. No se implementó ningún caso así en
Fase 1; se documentó como "evitar".

**Fecha:** 30 de mayo de 2026.
**Decidido por:** @arqui.

---

## 6. Paleta de color Opción B: Gold / Negro / Blanco

**Contexto:** El spec del usuario menciona "estética religiosa tradicional".
HimnarioID 2.0 ofrece dos paletas:

- **Opción A:** Azul (#1E3A8A) + Dorado (#D4AF37) — más vibrante, moderna.
- **Opción B:** Gold (#D4AF37) + Negro (#0A0A0A) + Blanco (#FFFFFF) — más
  solemne, editorial, "imprenta clásica".

**Opciones consideradas:**

- **A) Azul + Dorado** — más llamativo, pero puede parecer "app secular
  con tinte dorado".
- **B) Gold / Negro / Blanco** — paleta de biblia impresa, atemporal.
- **C) Burgundy / Crema** — más "litúrgica", pero pierde contraste en
  modo oscuro.

**Decisión:** Opción B. @arqui resolvió el conflicto explícitamente en
Sesión 2 (@user había propuesto la A; @arqui y @design convinieron la B
por coherencia con la solemnidad del texto bíblico).

**Rationale:** La paleta de Biblia Reina Valera impresa es blanco y negro
con detalles dorados. Refleja mejor el "feel" buscado. Además, el Gold ya
está en tokens de HimnarioID 2.0, así que se reutilizan.

**Fecha:** 30 de mayo de 2026.
**Decidido por:** @design + @arqui (con acuerdo de @user).

---

## 7. Glassmorphism selectivo: sí en cards, no en nav/compact/splash

**Contexto:** Glassmorphism (fondos blur con translucidez) es popular pero
**consume CPU** y puede arruinar la legibilidad en pantallas pequeñas. La
pregunta es: ¿dónde sí y dónde no?

**Opciones consideradas:**

- **A) Glassmorphism en todas partes** — bonito en desktop, injugable en
  móvil.
- **B) Cero glassmorphism** — accesible, pero pierde el "look premium".
- **C) Glassmorphism selectivo** — solo en cards de contenido, nunca en
  bottom nav, vista compact del emisor, ni splash.

**Decisión:** Opción C.

**Rationale:** Las cards de versículos/notas se benefician del blur
(estética "tarjeta de papel"). La bottom nav debe ser sólida (legibilidad
de íconos). La vista compact del emisor está diseñada para projectors con
baja calidad — el blur se ve mal. El splash debe cargar instantáneo sin
compositing.

**Fecha:** 31 de mayo de 2026 (diseño de @design).
**Decidido por:** @design, con visto bueno de @arqui.

---

## 8. Emisor con dos vistas: COMPACT + PREVIEW

**Contexto:** El modo emisor (presentador) controla el versículo/himno
visible en una pantalla receptora remota. En iglesias, el presentador
puede estar lejos de la pantalla y necesita ver **rápidamente** qué viene
después. ¿Una sola vista del emisor o dos?

**Opciones consideradas:**

- **A) Una sola vista que muestra el versículo actual con texto pequeño**
  — el presentador no puede leer a 2 m de distancia.
- **B) Dos vistas conmutables**:
  - **COMPACT:** solo número de himno/versículo + libro+cap (ej. "H342",
    "Juan 3:16") — lectura a 5 m.
  - **PREVIEW:** texto completo del versículo siguiente al actual — útil
    para preparar la transición.
- **C) Vista dual permanente** — ocupa mucho espacio en pantallas chicas.

**Decisión:** Opción B, conmutable con un toggle en la app bar del emisor.
El estado de la vista persiste por sesión de presentación.

**Rationale:** El presentador suele mirar la vista COMPACT (números grandes)
y solo cambia a PREVIEW justo antes de hacer "Next". El conmutador
inline-in-app-bar minimiza la fricción.

**Fecha:** 31 de mayo de 2026.
**Decidido por:** @design + @arqui.

---

## 9. Notas: 1 por versículo, color-coded (amarillo / verde / azul)

**Contexto:** El usuario puede querer tomar notas sobre versículos. ¿Una
nota larga por versículo? ¿Múltiples notas? ¿Etiquetas?

**Opciones consideradas:**

- **A) Múltiples notas por versículo** (modelo "hilos" estilo
  comentarios). Flexible pero complejo.
- **B) Una nota por versículo, con color semaforizado** — simple, claro,
  "GTD"-style.
- **C) Markdown largo + tags** — over-engineering para Fase 2.

**Decisión:** Opción B.

**Rationale:** La mayoría de usuarios de Bible apps usan 1 nota corta
("para meditar", "compartir en grupo", "predicar"). El color sirve como
categoría lightweight. Constraint en SQL: `CHECK(color IN ('amarillo',
'verde', 'azul', 'ninguno'))` + `UNIQUE(version_id, libro_id, capitulo,
numero)`.

**Consecuencia:** Si en el futuro se quieren múltiples notas, se necesitará
una migración a `nota_revisiones` (FK a `nota.id`). Documentado en
`assets/db/schema/README.md` § "Por qué UNIQUE".

**Fecha:** 31 de mayo de 2026.
**Decidido por:** @design + @back.

---

## 10. Versículo aleatorio al abrir la app (no "verse del día")

**Contexto:** La pantalla home podría mostrar un versículo fijo por día
("verse del día", estilo YouVersion) o un versículo aleatorio en cada
apertura.

**Opciones consideradas:**

- **A) "Verse del día"** — predecible, shareable, pero requiere lógica de
  "medianoche" + cache.
- **B) Versículo aleatorio en cada cold start** — sorpresa, simple, no
  requiere estado.
- **C) Versículo aleatorio por sesión** — cambia cada vez que se sale y
  vuelve a la home.

**Decisión:** Opción B.

**Rationale:** Implementación trivial (`SELECT * FROM versiculo ORDER BY
RANDOM() LIMIT 1` con seed opcional). Sorpresa en cada apertura incentiva
la re-lectura. No requiere cache de "día actual". El usuario puede
desactivarlo en settings si lo desea (Fase 2+).

**Fecha:** 30 de mayo de 2026.
**Decidido por:** @design, con confirmación de @user.

---

## 11. Bundle ID `com.mqapp` (no `com.example.*`)

**Contexto:** Flutter por defecto usa `com.example.<projectname>`, lo que
produce `com.example.mqapp`. Esto **bloquea la publicación en Google Play
Store** (rechaza bundle IDs `com.example.*`).

**Opciones consideradas:**

- **A) Dejar `com.example.mqapp`** — bloquea release, hay que rehacer al
  final.
- **B) Cambiar a `com.mqapp`** — dominio "reservado" (no real), 5
  plataformas, simple.
- **C) Usar un dominio real del usuario** — futuro, si el usuario registra
  `mqapp.com` o similar.

**Decisión:** Opción B.

**Rationale:** El usuario no tiene dominio público aún. `com.mqapp` es
sintético pero válido para Google Play / Apple Developer. El "reskin" a
dominio real es trivial cuando se decida.

**Commit:** `3408fa2` — bulk rename de `com.example.mqapp` a `com.mqapp` en
`android/app/build.gradle`, `ios/Runner.xcodeproj/project.pbxproj`,
`macos/Runner/Configs/AppInfo.xcconfig`, `linux/CMakeLists.txt`.

**Fecha:** 1 de junio de 2026.
**Decidido por:** @arqui (issue H1 del review final).

---

## 12. Config en tabla SQLite (no `SharedPreferences`)

**Contexto:** La app necesita persistir preferencias: modo emisor, versión
bíblica por defecto, tamaño de fuente, etc. ¿SQLite o `SharedPreferences`?

**Opciones consideradas:**

- **A) `shared_preferences`** (plugin oficial Flutter) — funciona en
  Android/iOS, pero en desktop requiere `shared_preferences_web` +
  fallback a archivos.
- **B) Tabla `config` (clave-valor) en SQLite** — un solo motor, mismo
  backup, transaccional con datos de Biblia.
- **C) Archivo JSON custom** — portable pero manual.

**Decisión:** Opción B.

**Rationale:** Consistencia multiplataforma. La tabla `config` está
definida en `001_biblia_schema.sql` con PK en `clave` (TEXT). El
`DatabaseHelper` expone `getConfig(clave)` y `setConfig(clave, valor)`.
Migración trivial: añadir un nuevo `clave` es solo `INSERT`.

**Consecuencia:** Toda preferencia requiere abrir la DB SQLite. Para
preferencias ultra-críticas de "primer frame" (ej. tema oscuro por
defecto), se hardcodea en el `ThemeData` y se sobreescribe después con
`config`. No es el caso en MQ-App.

**Fecha:** 30 de mayo de 2026.
**Decidido por:** @arqui + @back.

---

## Resumen de impacto de las 12 decisiones

```
                                                  Riesgo   Beneficio
 1. Stack (mantener HimnarioID 2.0 + FFI)         Bajo     Alto
 2. 6 tablas normalizadas                         Bajo     Alto
 3. FTS5 external content + remove_diacritics 2   Medio    Alto
 4. SQLite 3.46+ bundleado en TODAS               Medio    Alto
 5. Dos DBs separadas                             Bajo     Medio
 6. Paleta Gold/Negro/Blanco                      Bajo     Medio
 7. Glassmorphism selectivo                       Bajo     Medio
 8. Emisor dual (COMPACT + PREVIEW)               Bajo     Alto
 9. Notas 1-por-versículo con color               Bajo     Medio
10. Versículo aleatorio por cold start            Bajo     Bajo
11. Bundle ID com.mqapp                           Alto→0   Crítico (Play Store)
12. Config en SQLite                              Bajo     Medio
```

**Decisiones con mayor peso técnico futuro:**

- **#4** (SQLite bundleado) — define el peso del APK y el code path de DB.
- **#3** (FTS5) — define el rendimiento de búsqueda y el tamaño de la DB.
- **#8** (Emisor dual) — define el flujo de UI del emisor.
- **#11** (Bundle ID) — define la viabilidad del release a Play Store.

**Decisiones con menor peso (fáciles de revertir):**

- **#6, #7** (paleta, glassmorphism) — son tokens de UI, reversibles sin
  migración de datos.
- **#9** (notas) — `UNIQUE` requiere migración si se quiere multi-nota, pero
  es un solo `ALTER TABLE`.
- **#10** (versículo aleatorio) — un flag en `config` lo desactiva.

---

## Historial de revisiones

| Fecha       | Versión | Cambios |
|-------------|---------|---------|
| 1 jun 2026  | 1.0     | Creación inicial con las 12 decisiones de Fase 1 |

---

*Documento creado por @documentador el 1 de junio de 2026*
*Basado en sesiones de trabajo con @arqui, @back, @design, @dev*
*Las decisiones con tipo "arquitectura" o "política" requieren confirmación
de @arqui para ser revertidas en el futuro*
