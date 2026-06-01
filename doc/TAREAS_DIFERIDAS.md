# Tareas Diferidas — Próximos Sprints

> **Actualización (20 mayo 2026):** Proyecto estable con 274 tests. Pendiente: split APK, tests, gRPC, fondos de video (pospuesto).
> 
> Este documento registra las tareas identificadas por @documentador que fueron diferidas por exceder ~1h de trabajo o requerir infraestructura nueva. Se planificarán en sprints posteriores.

---

## Sprint 2 (✅ COMPLETADO)

### ✅ I1 — Servidor gRPC (Display) — COMPLETADO
**Implementado en**: `lib/data/datasources/remote/grpc_display_server.dart` (335 líneas)
**Integrado en**: `lib/bootstrap/app_initializer.dart`
**Funcionalidad**: Servidor gRPC completo con 7 tipos de comando + handshake + watchStatus streaming + keepalive + fallback de puertos. Se inicia automáticamente en desktop.

### ✅ I2 — Control remoto funcional — COMPLETADO
**Implementado en**: `lib/data/datasources/remote/grpc_control_datasource.dart` + `lib/presentation/views_projection/providers/connection_providers.dart`
**Funcionalidad**: Cliente gRPC con keepalive, heartbeat cada 15s con backoff exponencial, auto-reconexión, manejo de expiración de streams. Providers conectados al datasource real (no mock).

### M1 — Tests unitarios (cobertura ≥80%)
**Estimado**: ~6h (transversal)
**Dependencias**: —
**Archivos a crear/modificar**:
- `test/unit/core/**` — Tests para `ChordTransposer`, `MusicalConstants`
- `test/unit/data/**` — Tests para datasources y repositorios
- `test/widget/**` — Tests de widgets

**Descripción**: Implementar tests unitarios usando `mocktail` y `flutter_test`. Priorizar:
1. `chord_transposer.dart` (lógica crítica de transposición)
2. `hymn_repository_impl.dart` (orquestación)
3. `hymn_local_datasource.dart` (queries SQLite)
4. Widgets principales (HomeScreen, HymnDetailScreen)

---

## Sprint 3 (✅ COMPLETADO)

### ✅ I5 — Conexión automática mDNS — COMPLETADO
**Implementado en**: `lib/core/network/bonsoir_service.dart`, `lib/core/network/bonsoir_broadcast_service.dart`
**Funcionalidad**: Broadcast mDNS desde desktop (Bonsoir), discovery desde mobile. Publicación de servicio `_himnario._tcp` con puerto. Integrado en `AppInitializer` con detección de plataforma.

### ✅ A1 — Reproductor de audio — COMPLETADO
**Estimado**: ~4h
**Dependencias**: `audioplayers` ya en pubspec
**Archivos a crear/modificar**:
- `lib/data/datasources/local/audio_local_datasource.dart`
- `lib/domain/repositories/audio_repository.dart`
- `lib/presentation/app_controller/screens/hymn_detail_screen.dart` — Botón de play funcional
- `lib/presentation/state_management/providers/audio_providers.dart`

**Descripción**: Implementar reproducción de pistas de audio MP3/OGG desde assets. Manejar play/pause/stop, integración con himnos.

---

## Sprint 4

### A2 — Transposición con preview
**Estimado**: ~2h
**Dependencias**: A1 (opcional pero recomendado)
**Archivos a modificar**:
- `lib/presentation/app_controller/screens/hymn_detail_screen.dart`

**Descripción**: Mostrar preview en tiempo real de la transposición. Actualmente la transposición aplica al contenido ChordPro; agregar un pequeño teclado visual para probar diferentes tonalidades antes de aplicar.

### M4 — Tema consistente (Material Design 3)
**Estimado**: ~2h
**Archivos a modificar**:
- `lib/core/theme/app_theme.dart` — Revisar y completar el tema
- Todos los screens/widgets que usen colores hardcodeados

**Descripción**: Auditoría completa de uso de colorScheme/textTheme en todos los widgets. Reemplazar `Colors.white`, `Colors.black` con valores del tema. Asegurar que el tema claro también se vea bien. Esta tarea puede comenzar después de M2+M3 para reducir conflictos de merge.

### M5 — Documentación de API interna
**Estimado**: ~2h
**Dependencias**: I1+I2+I3+I4+I5 estable
**Archivos**:
- `doc/api/` — Generar documentación de referencia de la API

---

## Tareas no planificadas (icebox)

| Tarea | Descripción | Razón |
|-------|-------------|-------|
| M8 — Exportar arreglos como PDF | Generar PDF con letra+acordes desde un arreglo guardado | Baja prioridad, no crítica para MVP |
| M9 — Importar/Exportar arreglos JSON | Sincronización entre dispositivos | Requiere backend/sincronización |
| M10 — Multilenguaje (i18n) | Soporte para inglés/portugués | MVP es solo español |
| A3 — Grabación de audio desde la app | Los músicos graban sus versiones | Complejidad alta, depende de permisos nativos |

---

*Plan generado por @arqui. Revisar al inicio de cada sprint para repriorizar.*
