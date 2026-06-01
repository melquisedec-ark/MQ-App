# Conexión LAN — Control Remoto (Android ⇄ Windows)

> **Última actualización:** 21 de mayo de 2026
> **Rama:** `main` (mergeada como `feature/flujo-emisor-receptor`)
> **Estado:** ✅ Implementado y funcional — infraestructura gRPC + mDNS completa, flujo Emisor/Receptor operativo

---

## Índice

1. [Visión General](#1-visión-general)
2. [Arquitectura de Conexión](#2-arquitectura-de-conexión)
3. [Estado Actual del Código](#3-estado-actual-del-código)
4. [Plan de Implementación por Fases](#4-plan-de-implementación-por-fases)
5. [Detalle Técnico](#5-detalle-técnico)
6. [Riesgos y Mitigaciones](#6-riesgos-y-mitigaciones)
7. [Checklist de Avance](#7-checklist-de-avance)
8. [Referencias](#8-referencias)

---

## 1. Visión General

### Objetivo

Que un **móvil Android** conectado a la misma **red WiFi** que una **PC con Windows** funcione como **control remoto** para la proyección de himnos. El móvil puede:

- Elegir y navegar himnos (siguiente/anterior estrofa, ir al coro)
- Controlar el fondo de pantalla y tamaño de fuente
- Ajustar la transposición tonal
- Recibir el estado actual de la proyección en tiempo real

### Roles

| Rol | Dispositivo | App |
|-----|------------|-----|
| **Emisor** (Controlador) | Android | App móvil — panel de control |
| **Receptor** (Display) | Windows PC | App de escritorio — pantalla de proyección |

### Tecnologías

| Tecnología | Propósito |
|------------|-----------|
| **gRPC** (Protocol Buffers) | Comunicación binaria de baja latencia entre dispositivos |
| **mDNS** (Multicast DNS) vía Bonsoir | Descubrimiento automático del PC desde el móvil |
| **Proto: `hymn_control.proto`** | Contrato de mensajes y servicios |

---

## 2. Arquitectura de Conexión

```
┌────────────────────────────────────┐       ┌────────────────────────────────────┐
│         ANDROID (Controlador)      │       │         WINDOWS PC (Display)       │
│                                    │       │                                    │
│  ┌──────────────────────────────┐  │       │  ┌──────────────────────────────┐  │
│  │   GrpcControlDataSource      │  │  gRPC  │  │   GrpcDisplayServer         │  │
│  │   (Cliente)                  │◄┼────────┼►│   (Servidor)                 │  │
│  │   - connect(host, port)      │  │       │  │   - sendCommand()            │  │
│  │   - sendCommand(cmd)         │  │       │  │   - getStatus()              │  │
│  │   - getStatus()              │  │       │  │   - watchStatus() (stream)   │  │
│  │   - watchStatus() (stream)   │  │       │  │   - handshake()              │  │
│  │   - handshake()              │  │       │  │                              │  │
│  └──────────────────────────────┘  │       │  └──────────────────────────────┘  │
│                                    │       │                                    │
│  ┌──────────────────────────────┐  │       │  ┌──────────────────────────────┐  │
│  │   BonsoirService             │  │  mDNS  │  │   BonsoirBroadcastService   │  │
│  │   (Discovery)                │◄┼────────┼►│   (Broadcast)                │  │
│  │   - busca `_himnario._tcp`   │  │       │  │   - anuncia `_himnario._tcp` │  │
│  │   - resuelve IP:puerto       │  │       │  │   - nombre + displayName     │  │
│  └──────────────────────────────┘  │       │  └──────────────────────────────┘  │
│                                    │       │                                    │
│  ┌──────────────────────────────┐  │       │  ┌──────────────────────────────┐  │
│  │   ConnectionNotifier         │  │       │  │   HymnAppearanceState        │  │
│  │   (Estado de conexión)       │  │       │  │   + LiveControlState         │  │
│  │   - heartbeat cada 15s       │  │       │  │                              │  │
│  │   - auto-reconexión          │  │       │  └──────────────────────────────┘  │
│  └──────────────────────────────┘  │       │                                    │
└────────────────────────────────────┘       └────────────────────────────────────┘
```

### Flujo de conexión

```
1. [PC]    Inicia GrpcDisplayServer en puerto 50051
2. [PC]    Inicia BonsoirBroadcast anunciando _himnario._tcp
3. [Android] Inicia BonsoirService (discovery en la red)
4. [Android] Descubre PC → obtiene IP + puerto
5. [Android] Conecta vía gRPC (ClientChannel)
6. [Android] Envía Handshake → recibe HandshakeResponse
7. [Android] Estado: Connected
8. [Android] Inicia heartbeat (PING cada 15s)
9. [Android] Inicia watchStatus() (streaming de estado)
10. [Android] Usuario envía comandos → PC ejecuta
```

### Puerto por defecto

- Puerto principal: **50051**
- Fallback automático: **50052, 50053, ... 50059** (si 50051 está ocupado o bloqueado)

---

## 3. Estado Actual del Código

> **Nota:** Todo el flujo Emisor/Receptor (Fase 1-4) fue implementado y mergeado a `main` en la rama `feature/flujo-emisor-receptor`. Esta sección documenta el estado de cada componente.

### ✅ Lo que está listo (no requiere cambios)

| Componente | Archivo | Observaciones |
|------------|---------|---------------|
| Proto `HymnControl` | `proto/hymn_control.proto` | Servicio completo con 4 RPCs. No tocar |
| Stubs gRPC | `lib/proto/generated/hymn_control.pbgrpc.dart` | Generados con `protoc --dart_out=grpc`. No tocar |
| Cliente gRPC | `lib/data/datasources/remote/grpc_control_datasource.dart` | Estructura correcta: conecta, hace handshake, envía comandos, lee estado |
| Servidor gRPC | `lib/data/datasources/remote/grpc_display_server.dart` | Implementa todos los RPCs. Extiende `HymnControlServiceBase` |
| Providers conexión | `lib/presentation/views_projection/providers/connection_providers.dart` | `ConnectionNotifier`, `controlDataSourceProvider`, `displayScannerProvider` |
| Receptor binding | `lib/presentation/views_projection/display/receptor_binding.dart` | `grpcDisplayServerProvider`, `receptorDisplaysProvider` |
| App initializer | `lib/bootstrap/app_initializer.dart` | Inicializa `GrpcDisplayServer` en Windows |
| Provider de estado de proyección | `live_control_providers.dart` | `LiveControlState`, `liveControlProvider` |
| Discovery sheet UI | `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart` | UI de lista de displays descubiertos |

### 🔧 Lo que necesita cambios

| Ítem | Archivo | Cambio necesario |
|------|---------|------------------|
| Keepalive cliente | `grpc_control_datasource.dart` | Agregar `ClientKeepAliveOptions` |
| Keepalive servidor | `grpc_display_server.dart` | Agregar `ServerKeepAliveOptions` |
| Fallback puertos | `grpc_display_server.dart` | Loop de reintento con puertos alternativos |
| Heartbeat + reconexión | `connection_providers.dart` | Timer periódico + backoff exponencial + auto-reconnect |
| Stream expiration | `grpc_control_datasource.dart` | Detectar cierre silencioso de streams (issue #752) |
| Migrar mDNS | `pubspec.yaml` + `mdns_discovery.dart` | `multicast_dns` → `bonsoir ^6.1.0` |
| Broadcast | Nuevo `bonsoir_broadcast.dart` | Anunciar `_himnario._tcp` desde Windows |
| Discovery service | `bonsoir_service.dart` (renombrado) | Reescribir `MdnsDiscovery` con Bonsoir |
| App initializer | `app_initializer.dart` | Iniciar broadcast en desktop, discovery en mobile |
| Permisos Android | `AndroidManifest.xml` | Internet (ya debería estar) |
| Permisos iOS | `Info.plist` | `NSLocalNetworkUsageDescription`, `NSBonjourServices` |
| Documentación | Nuevo `doc/CONEXION_LAN.md` | Este archivo |

### 📝 Proto existente (`proto/hymn_control.proto`)

```protobuf
service HymnControl {
  rpc SendCommand (CommandRequest) returns (CommandResponse);
  rpc GetStatus (Empty) returns (DisplayStatus);
  rpc WatchStatus (Empty) returns (stream DisplayStatus);
  rpc Handshake (HandshakeRequest) returns (HandshakeResponse);
}

enum CommandType {
  NEXT_STANZA = 0;
  PREV_STANZA = 1;
  GO_TO_CHORUS = 2;
  GO_TO_STANZA = 3;
  BLACKOUT = 4;
  CLEAR_BLACKOUT = 5;
  SET_TRANSPOSITION = 6;
  JUMP_TO_HYMN = 7;
  SET_BACKGROUND = 8;
  SET_FONT_SIZE = 9;
  PING = 10;
}
```

---

## 4. Plan de Implementación por Fases

### Fase 1 — Ajustes gRPC (estimado: ~1 día)

#### 1.1 ClientKeepAliveOptions

**Archivo:** `lib/data/datasources/remote/grpc_control_datasource.dart`

Agregar en el método `connect()`:

```dart
_channel = ClientChannel(
  host,
  port: port,
  options: ChannelOptions(
    credentials: ChannelCredentials.insecure(),
    keepAlive: ClientKeepAliveOptions(
      pingInterval: Duration(seconds: 30),
      timeout: Duration(seconds: 10),
      permitWithoutCalls: true,
    ),
    connectionTimeout: Duration(minutes: 45),
  ),
);
```

#### 1.2 ServerKeepAliveOptions

**Archivo:** `lib/data/datasources/remote/grpc_display_server.dart`

```dart
_server = Server.create(
  services: [this],
  keepAliveOptions: ServerKeepAliveOptions(
    minIntervalBetweenPingsWithoutData: Duration(seconds: 10),
    maxBadPings: 3,
  ),
);
```

#### 1.3 Fallback de puertos

**Archivo:** `lib/data/datasources/remote/grpc_display_server.dart`

```dart
int tryPort = defaultPort; // 50051
for (int i = 0; i < 10; i++) {
  try {
    _server = Server.create(services: [this], keepAliveOptions: ...);
    await _server!.serve(address: InternetAddress.anyIPv4, port: tryPort);
    _port = tryPort;
    break;
  } catch (e) {
    tryPort = defaultPort + i + 1;
  }
}
```

#### 1.4 Heartbeat + Reconexión automática

**Archivo:** `lib/presentation/views_projection/providers/connection_providers.dart`

Agregar en `ConnectionNotifier`:

- `Timer.periodic` cada **15 segundos** enviando `CommandType.PING`
- Contador de fallos: 3 fallos consecutivos → estado `ConnectionError`
- Método `_autoReconnect()` con **backoff exponencial**: 1s, 2s, 4s, 8s, 16s, máx 30s
- Máximo 5 reintentos, luego estado `ConnectionError` permanente
- Guardar último `DeviceInfo` conectado para reconexión automática

#### 1.5 Manejo de expiración de streams (issue #752)

**Archivo:** `lib/data/datasources/remote/grpc_control_datasource.dart`

Envolver `watchStatus()` con un `StreamTransformer` que detecte cierres inesperados y notifique a `ConnectionNotifier` para reconexión.

### Fase 2 — Migración mDNS (estimado: ~1-2 días)

#### 2.1 Actualizar dependencia

**Archivo:** `pubspec.yaml`

```yaml
# ANTES
  multicast_dns: ^0.3.3

# DESPUÉS
  bonsoir: ^6.1.0
```

Ejecutar: `flutter pub get`

#### 2.2 BonsoirService (Discovery)

**Archivo nuevo:** `lib/core/network/bonsoir_service.dart`

```dart
class BonsoirService {
  static const String _serviceType = '_himnario._tcp';
  BonsoirDiscovery? _discovery;
  final StreamController<DeviceInfo> _deviceController =
      StreamController<DeviceInfo>.broadcast();

  Stream<DeviceInfo> get onDeviceDiscovered => _deviceController.stream;

  Future<void> startDiscovery() async { /* ... */ }
  Future<void> stopDiscovery() async { /* ... */ }
  void dispose() { _deviceController.close(); }
}
```

#### 2.3 BonsoirBroadcastService (Broadcast desde PC)

**Archivo nuevo:** `lib/core/network/bonsoir_broadcast.dart`

```dart
class BonsoirBroadcastService {
  BonsoirBroadcast? _broadcast;

  Future<void> start({
    required String name,
    required int port,
    String type = '_himnario._tcp',
  }) async { /* ... */ }

  Future<void> stop() async { /* ... */ }
}
```

#### 2.4 Actualizar AppInitializer

**Archivo:** `lib/bootstrap/app_initializer.dart`

- En desktop (Receptor): iniciar `GrpcDisplayServer` + `BonsoirBroadcastService`
- En mobile (Controlador): iniciar `BonsoirService` (discovery)

#### 2.5 Refrescar UI de discovery

**Archivo:** `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart`

- Timer de refresh periódico cada 30s
- Remover displays que desaparecieron de la red

### Fase 3 — Integración y pruebas (estimado: ~1-2 días)

#### 3.1 Configuración de plataformas

| Archivo | Cambio |
|---------|--------|
| `android/app/src/main/AndroidManifest.xml` | Verificar permiso `INTERNET` y `ACCESS_WIFI_STATE` |
| `windows/runner/` | Win 10 19H1+ required para DNS-SD nativo |
| *(Opcional)* `ios/Runner/Info.plist` | `NSLocalNetworkUsageDescription`, `NSBonjourServices` |

#### 3.2 Pruebas de conexión real

- [ ] Broadcast: PC anuncia servicio `_himnario._tcp:50051`
- [ ] Discovery: Android descubre la PC
- [ ] Handshake: Android envía `HandshakeRequest`, PC responde
- [ ] Comando: Android envía `NEXT_STANZA`, PC avanza slide
- [ ] Estado: Android llama `getStatus()` y recibe estado real
- [ ] Streaming: Android inicia `watchStatus()` y recibe actualizaciones

#### 3.3 Pruebas de reconexión

- [ ] Cerrar app PC → Android detecta desconexión en < 30s
- [ ] Reabrir app PC → Android reconecta (auto o manual)
- [ ] Desconectar WiFi → heartbeat falla → estado error
- [ ] Reconectar WiFi → reconexión automática

#### 3.4 Pruebas de firewall

```powershell
# Verificar si el puerto 50051 está en rango excluido
netsh interface ipv4 show excludedportrange protocol=tcp

# Agregar regla al firewall (o documentar)
netsh advfirewall firewall add rule name="HimnarioID gRPC" dir=in action=allow protocol=TCP localport=50051
```

### Fase 4 — Mejoras (estimado: ~2-3 días)

#### 4.1 Streaming en tiempo real

**Archivo:** `connection_providers.dart`

Nuevo provider:
```dart
final liveDisplayStatusProvider = StreamProvider<domain.DisplayStatus>((ref) {
  final dataSource = ref.watch(controlDataSourceProvider);
  if (!dataSource.isConnected) return const Stream.empty();
  return dataSource.watchStatus();
});
```

#### 4.2 Sincronización fondo y fuente

Ya existe en el proto (`SET_BACKGROUND`, `SET_FONT_SIZE`) y en el cliente. Falta:
- UI en el controlador para seleccionar fondo y tamaño de fuente
- Enviar comando gRPC al cambiar

#### 4.3 Control de transposición desde móvil

Ya existe en el proto (`SET_TRANSPOSITION`) y cliente (`sendTransposition()`).
Falta:
- UI: slider o botones +/- en el panel de control remoto

#### 4.4 Presentación automática

Temporizador **local en el controlador** (no requiere cambios en proto):
- Timer que avance `NEXT_STANZA` cada N segundos
- Botón "Iniciar presentación automática"
- No requiere cambios en servidor

---

## 5. Detalle Técnico

### Configuración de keepalive

| Parámetro | Cliente | Servidor |
|-----------|---------|----------|
| `pingInterval` | 30s | — |
| `timeout` | 10s | — |
| `permitWithoutCalls` | true | — |
| `minIntervalBetweenPingsWithoutData` | — | 10s |
| `maxBadPings` | — | 3 |

### Backoff exponencial para reconexión

```
Intento 1: esperar 1s
Intento 2: esperar 2s
Intento 3: esperar 4s
Intento 4: esperar 8s
Intento 5: esperar 16s
Máximo:   30s (cap)
Total: ~1 minuto antes de error permanente
```

### Formato del servicio mDNS

| Campo | Valor |
|-------|-------|
| Service type | `_himnario._tcp` |
| Puerto | 50051 (o fallback) |
| TXT records | `name=Display Principal`, `version=2.0.0` |

### Mensajes del proto (referencia)

**HandshakeRequest**: `clientName`, `clientVersion`, `protocolVersion`
**HandshakeResponse**: `accepted`, `serverName`, `serverVersion`, `displayName`, `protocolVersion`, `sessionId`

**CommandRequest**: `type` (CommandType), `stanzaIndex`, `semitones`, `hymnId`, `backgroundId`, `fontSize`
**CommandResponse**: `success`, `errorMessage`

**DisplayStatus**: `currentHymnId`, `currentHymnTitle`, `currentStanzaIndex`, `totalStanzas`, `transpositionSemitones`, `isBlackout`, `currentBackgroundId`, `fontSize`, `displayName`

---

## 6. Riesgos y Mitigaciones

| # | Riesgo | Impacto | Probabilidad | Mitigación |
|---|--------|---------|-------------|------------|
| 1 | Puerto 50051 bloqueado en Windows | No se inicia servidor | Media | Fallback a 50052-50059; documentar `netsh` |
| 2 | Bonsoir no funciona en Win < 19H1 | Broadcast/discovery falla | Baja (Win 10 < 19H1 es antiguo) | Mostrar error informativo |
| 3 | Keepalive config incorrecta cierra conexión | Streams se caen cada 30s | Media | Probar con valores conservadores (ping 30s, timeout 10s, synchronized con servidor) |
| 4 | Firewall de Windows bloquea gRPC | No hay conexión | Alta | Documentar regla; intentar agregar automáticamente al iniciar server |
| 5 | Múltiples displays en misma red | Confusión en discovery | Media | Mostrar nombre+IP+puerto; permitir conectar a uno específico |
| 6 | gRPC stream issue #752 | Stream muere a los 50 min | Alta | Auto-reconexión en `ConnectionNotifier` mitiga el síntoma |
| 7 | WiFi congestionada en iglesia | Latencia alta, timeouts | Media | Heartbeat corto (15s), timeout generoso (10s) |
| 8 | Dispositivo se duerme (Android Doze) | Heartbeat no se envía | Media | Usar `android:allowWhileIdle` o wake lock parcial |

---

## 7. Checklist de Avance

### Fase 1 — Ajustes gRPC ✅ COMPLETADO
- [x] `ClientKeepAliveOptions` agregado en `grpc_control_datasource.dart`
- [x] `ServerKeepAliveOptions` agregado en `grpc_display_server.dart`
- [x] Fallback de puertos implementado en servidor
- [x] Heartbeat (PING cada 15s) en `ConnectionNotifier`
- [x] Backoff exponencial para reconexión
- [x] Stream `watchStatus()` resistente a cierres silenciosos

### Fase 2 — Migración mDNS ✅ COMPLETADO
- [x] `bonsoir ^6.1.0` agregado en `pubspec.yaml` (reemplazar `multicast_dns`)
- [x] `BonsoirService` (discovery) implementado
- [x] `BonsoirBroadcastService` implementado
- [x] `AppInitializer` actualizado (broadcast en PC, discovery en mobile)
- [x] UI de discovery actualizada (refresh periódico, limpieza)
- [x] Permisos Android e iOS configurados

### Fase 3 — Pruebas 🔶 Parcial
- [x] Conexión real Android ⇄ Windows probada en desarrollo
- [x] Comandos de navegación funcionan (< 500ms)
- [ ] Reconexión automática probada en entorno real
- [x] Firewall de Windows documentado
- [x] `doc/CONEXION_LAN.md` actualizado

### Fase 4 — Mejoras 🔶 Parcial
- [x] `watchStatus()` streaming en UI del controlador
- [x] Fondo y fuente sincronizables desde móvil
- [x] Transposición controlable desde móvil
- [x] Envío automático de himno al conectar
- [x] Presentación automática con timer local (LiveControlNotifier)

---

## 8. Referencias

### Documentación interna

| Archivo | Contenido |
|---------|-----------|
| `proto/hymn_control.proto` | Definición del servicio gRPC |
| `doc/CONTEXTO_PROYECTO.md` | Contexto general del proyecto |
| `doc/BUILD_WINDOWS.md` | Cómo generar el .exe de Windows |
| `README.md` | Stack tecnológico y objetivos |

### Paquetes

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `grpc` | ^5.1.0 | Comunicación gRPC para Dart |
| `protobuf` | ^6.0.0 | Soporte de Protocol Buffers |
| `bonsoir` | ^6.1.0 | mDNS discovery y broadcast multiplataforma |

### Archivos de código clave

| Archivo | Rol |
|---------|-----|
| `lib/data/datasources/remote/grpc_control_datasource.dart` | Cliente gRPC |
| `lib/data/datasources/remote/grpc_display_server.dart` | Servidor gRPC |
| `lib/presentation/views_projection/providers/connection_providers.dart` | Estado de conexión |
| `lib/presentation/views_projection/display/receptor_binding.dart` | Binding del servidor |
| `lib/bootstrap/app_initializer.dart` | Inicialización de servicios |

### Enlaces externos

- [gRPC Dart](https://github.com/grpc/grpc-dart)
- [Bonsoir (pub.dev)](https://pub.dev/packages/bonsoir)
- [Protocol Buffers](https://protobuf.dev/)
- [gRPC issue #752 — stream expiration](https://github.com/grpc/grpc-dart/issues/752)

---

> **Ver también:** `doc/tareas_pendientes.md` — lista completa de pendientes del proyecto
