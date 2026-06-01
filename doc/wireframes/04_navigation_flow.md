# Wireframe 04 — Flujo de Navegación Completo

> **Alcance:** Toda la app MQ App v1.0 (Biblia + Himnario + Emisor)
> **Versión:** v1.0
> **Referencia:** `nuevaidea.md` §7 (User flows implícitos) + secciones 3, 4, 5, 6
> **Convención:** `[...]` = Pantalla | `(...)` = Acción/Momento

---

## Diagrama principal (High-level)

```
                            +-------------------+
                            |    [App Open]     |
                            |    (cold start)   |
                            +---------+---------+
                                      |
                                      v
                            +-------------------+
                            |  [Home Screen]    |
                            |  - Versiculo dia  |
                            |  - 2 cards        |
                            +---------+---------+
                                      |
          +-----------+---------------+---------------+-----------+
          |           |               |               |           |
          v           v               v               v           v
   [Settings]   [Connect]      [Bible Card]    [Hymn Card]   [Verse *]
                                                      
                                      |
                                      v
                            +-------------------+
                            |  [Bible Module]   |
                            +---------+---------+
                                      |
            +-------------+-----------+-----------+-------------+
            |             |                       |             |
            v             v                       v             v
     [Book Selector]  [Favoritos tab]       [Notas tab]    [Buscar]
            |                                                      
            v                                                      
     [Chapter Grid]                                                
            |                                                      
            v                                                      
     [Reader Screen]                                               
            |                                                      
            +-- [Note Editor]                                      
            +-- [Fullscreen Reader]                                 
            +-- [Presentation Mode]                                
            +-- [Menu Overflow: Compartir, Tamano, Ir a]
```

## Diagrama completo (todos los flujos)

```
[App Open]
   |
   v
[Home Screen]  ─── (tap logo) ──>  [About Modal] (futuro, no v1.0)
   |
   ├── (tap [O] config top-left) ─────────────────────────> [Settings Screen]
   |                                                                  |
   |                                                                  ├── [Tema: Claro / Oscuro / Personalizado]
   |                                                                  ├── [Version Biblia default: RV1909 / RV1569]
   |                                                                  ├── [Tamano de fuente: slider]
   |                                                                  ├── [Modo emisor default: Compact / Preview]
   |                                                                  ├── [Glassmorphism: on/off + sigma]
   |                                                                  ├── [Vibracion: on/off]
   |                                                                  ├── [Acerca de: version, licencias]
   |                                                                  └── [Limpiar cache / Reiniciar DB]
   |
   ├── (tap [R] connect top-right) ───────────────────────> [Connect Sheet]
   |                                                                  |
   |                                                                  ├── [Selector Emisor / Receptor]  (de HimnarioID 2.0)
   |                                                                  |       |
   |                                                                  |       v
   |                                                                  |   [Escaneo mDNS]  ── descubre ──> [Lista de dispositivos]
   |                                                                  |                                              |
   |                                                                  |                                              v
   |                                                                  |                                       [Emparejado] ──> [Emitter Screen]
   |                                                                  |                                                                      |
   |                                                                  |                                                                      v
   |                                                                  |                                                          [Modulo segun receptor]
   |                                                                  |
   |                                                                  └── [Modo receptor: TV/Proyector]
   |
   ├── (tap [B] Biblia card) ────────────────────────────> [Book Selector]
   |                                                                  |
   |                                                                  ├── tab AT ──>  [Lista 39 libros AT]
   |                                                                  ├── tab NT ──>  [Lista 27 libros NT]
   |                                                                  ├── tab Favoritos ──> [Lista versiculos favoritos]
   |                                                                  ├── tab Notas ──> [Lista notas (filtro color)]
   |                                                                  └── [buscar] ──> [Bible Search] ──> [Resultado] ──> [Reader]
   |
   |   [Book Selector]  ──tap libro──>  [Chapter Grid]
   |                                          |
   |                                          ├── tap capitulo ──> [Reader Screen]
   |                                          └── [Capitulo aleatorio] ──> [Reader Screen]
   |
   |   [Reader Screen]  ─────────────────────────────────────────────────────────┐
   |       |                                                                       |
   |       ├── swipe / botones ──>  (cambia versiculo)                             |
   |       ├── tap [RV1909 v] ──>  [Bottom Sheet: cambiar version]                 |
   |       ├── tap [buscar] ──>  [Bible Search]                                     |
   |       ├── tap [...] menu ──>  [Overflow Menu]                                  |
   |       |       ├── Compartir versiculo ──> [Share Sheet del SO]                |
   |       |       ├── Tamano de fuente ──> [Slider]                                |
   |       |       ├── Ir a ──> [Input Libro Cap:Vers]                              |
   |       |       └── Modo presentacion ──> [Bible Presentation Screen]           |
   |       ├── tap [*] favorito ──>  (toggle, sin navegar)                         |
   |       ├── tap [nota] ──>  [Note Editor Modal] ──> (guarda) ──> [Reader]      |
   |       ├── tap [aleat] ──>  (salta a versiculo aleatorio del libro)           |
   |       ├── tap [fullscreen] ──>  [Reader Fullscreen]                           |
   |       └── long press versiculo ──>  [Context Menu: Copiar / Compartir / Nota / Ir al capitulo]
   |
   |
   ├── (tap [M] Himnario card) ──────────────────────────> [Hymn List Screen] (de HimnarioID 2.0)
   |                                                                  |
   |                                                                  ├── buscar ──> [Resultados]
   |                                                                  ├── filtros ──> [Alabanza / Adoracion / Convencion]
   |                                                                  ├── scroll A-Z
   |                                                                  └── tap himno ──> [Hymn Detail Screen] (existente)
   |                                                                                  |
   |                                                                                  ├── Toggle Solfa (acordes)
   |                                                                                  ├── Transposicion
   |                                                                                  └── [Modo presentacion] (existente)
   |
   ├── (tap [Leer este versiculo]) ──────────────────────> [Reader Screen] (con versiculo del dia)
   |
   ├── (tap [star] en versiculo del dia) ───────────────>  (guarda en favorito_versiculo, toast confirma)
   |
   ├── (tap [refresh] en versiculo del dia) ─────────────>  (nuevo versiculo aleatorio, sin navegar)
   |
   └── (modo emisor activo, banner arriba) ─────────────> [Banner: dispositivo conectado] ── [X] Desconectar
```

---

## Flujos secundarios

### Flujo: Crear una nota

```
[Reader Screen]
   |
   v (tap [nota])
[Note Editor Modal]
   |
   ├── (no hay nota previa)
   |       |
   |       v
   |   [Editor vacio + selector color (default: ninguno)]
   |       |
   |       ├── escribir texto
   |       ├── elegir color
   |       v
   |   [Guardar] ──> INSERT INTO nota ──> [Reader Screen] (con indicador de color en la card)
   |
   └── (ya hay nota)
           |
           v
       [Editor con texto previo + color actual]
           |
           ├── editar texto
           ├── cambiar color
           v
           ├── [Guardar] ──> UPDATE nota ──> [Reader Screen]
           └── [Eliminar] ──> DELETE nota ──> [Reader Screen] (sin indicador)
```

### Flujo: Marcar favorito desde el versículo del día

```
[Home Screen] (versiculo del dia: Jeremias 29:11)
   |
   v (tap [*])
(favorito_versiculo: insert {version_id, libro_id, cap, vers, timestamp})
   |
   v
[Snackbar] "Agregado a favoritos" + boton "Deshacer" (5s)
   |
   v
[Home Screen] (icono [*] ahora relleno gold, NO navega)
```

### Flujo: Cambiar de Biblia a Himnario remotamente (emisor)

```
[Emisor: Biblia, Genesis 1:5]
   |
   v (usuario en receptor cambia a Himnario)
[WatchStatus stream] recibe ModuleInfo.module = HYMNAL
   |
   v
[Emisor] muestra banner "BIBLIA -> HIMNARIO" (3s)
   |
   v
[Emisor: Himnario, Himno 45 - Estrofa 2] (vista reconfigurada)
   |
   v (opcional: tap [O] settings emisor)
[Bottom Sheet: Vista del emisor + config]
```

### Flujo: Búsqueda full-text (FTS5)

```
[Reader Screen] ── tap [buscar] ──> [Bible Search]
   |
   ├── input "amor"
   |       |
   |       v
   |   SELECT * FROM versiculo_fts WHERE texto MATCH 'amor'  (FTS5)
   |       |
   |       v
   |   [Lista de resultados con highlighting]
   |       |
   |       v (tap un resultado)
   |   [Reader Screen] (con scroll automatico al versiculo)
   |
   ├── input "jehova es mi pastor"  (multi-word, AND logico)
   |       |
   |       v
   |   [Resultados donde las 3 palabras aparecen]
   |
   └── input "xyz123"  (sin resultados)
           |
           v
       [Empty state: "No se encontraron versiculos"]
```

### Flujo: Cold start → primer versículo

```
[App open] (cold start, no hay versiculo persistido en sesion)
   |
   v
[Bootstrap] (carga BD, preferencias, etc.)
   |
   v
[Home Screen]
   |
   v (bloc init)
SELECT * FROM versiculo WHERE id = Random.nextInt(31102)  -- 31102 = total versiculos
   |
   v
[Home Screen] (con versiculo renderizado)
```

> **Nota:** El versículo aleatorio **NO persiste** entre sesiones. Solo se guarda si el usuario marca favorito.

---

## Mapa de pantallas (resumen)

| # | Pantalla | Archivo destino | Padre |
|---|----------|-----------------|-------|
| 1 | Home Screen | `home/home_screen.dart` | — |
| 2 | Settings | `settings/settings_screen.dart` | Home |
| 3 | Connect Sheet | `connection/discover_display_sheet.dart` | Home |
| 4 | Emitter Screen | `dual_mode_wrapper/emitter/emitter_screen.dart` | Connect |
| 5 | Book Selector | `bible/book_selector_screen.dart` | Home (card Biblia) |
| 6 | Chapter Selector | `bible/chapter_selector_screen.dart` | Book Selector |
| 7 | Reader | `bible/reader/reader_screen.dart` | Chapter, Search, Favoritos, Home (verse del dia) |
| 8 | Bible Search | `bible/search/bible_search_screen.dart` | Reader, Book Selector |
| 9 | Note Editor Modal | `bible/notes/note_editor_modal.dart` | Reader |
| 10 | Hymn List | `hymn/hymn_list_screen.dart` | Home (card Himnario) |
| 11 | Hymn Detail | `hymn/hymn_detail_screen.dart` | Hymn List |
| 12 | Bible Presentation | `bible/presentation/bible_presentation_screen.dart` | Reader (menu) |
| 13 | Hymn Presentation | `hymn/presentation/hymn_projection_screen.dart` | Hymn Detail |

> Las pantallas #4, #5, #6, #7, #8, #9, #12 son **nuevas** para MQ App. El resto (#2, #3, #10, #11, #13) vienen de HimnarioID 2.0 con adaptaciones.

---

## Profundidad de navegación (max depth)

- **Max depth actual:** 3 niveles (Home → Book → Chapter → Reader) o (Home → Reader con versículo del día)
- **NO debe exceder 4.** Si se requiere, evaluar agregar atajos en AppBar.

## Atajos de navegación

| Atajo | Acción |
|-------|--------|
| Tap en el logo MQ App (en cualquier pantalla) | Vuelve al Home (si no estás ya ahí). |
| Back del sistema | Pop estándar (con confirmación si hay nota sin guardar). |
| Back en Home | Cierra la app (con confirmación si hay cambios sin guardar). |

---

## Casos edge (a validar con @arqui)

1. **¿Qué pasa si el usuario presiona back desde el Reader y tiene una nota a medio escribir?**
   - Sugerencia: mostrar dialog "¿Descartar cambios? [Descartar] [Guardar]".
2. **¿Qué pasa si el emisor pierde conexión durante una presentación?**
   - El emisor muestra estado "SIN CONEXION" pero sigue navegable. Al reconectar, sincroniza.
3. **¿Qué pasa si el usuario abre el módulo Biblia sin haber descargado RV1569?**
   - Solo aparece RV1909 en el selector de versión. Si intenta cambiarla, no se muestra en el dropdown.
4. **¿Qué pasa si la BD se corrompe?**
   - El bootstrap detecta el error y muestra pantalla de error full-screen. NO se carga el Home.
5. **¿Qué pasa si dos emisores se conectan al mismo receptor?**
   - Solo el primero tiene control. El segundo recibe un mensaje "Receptor ocupado" y se desconecta.

---

*Wireframe creado por @design — pendiente revisión de @arqui y del usuario antes de implementar.*
