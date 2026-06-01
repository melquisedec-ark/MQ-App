# 🎵 MQ App (antes HimnarioID 2.0)

Aplicación Flutter multiplataforma para himnos religiosos con modo personal, proyección, administración y descarga de pistas de audio.

---

Este repositorio contiene el código fuente y la arquitectura para la nueva generación del Himnario Web, evolucionado hacia un sistema de proyección controlable remotamente y gestión musical avanzada.

El sistema está diseñado pensando en alta resiliencia offline (ideal para entornos con conectividad inestable, como suele ocurrir en algunas zonas de El Salvador) y permite que un dispositivo móvil controle la proyección en una PC o TV mediante la red local (LAN).

---

## 🎯 Requerimientos y Objetivos del Sistema

1. **Uso Dual (Personal y Proyección):**
   - **Modo Personal:** Visualización fluida (scroll) de las estrofas y coros, con herramientas flotantes para músicos (transposición, acordes, reproducción de pistas).
   - **Modo Proyección:** Paneles minimalistas de control remoto y visualización de estrofas estáticas para el público.
2. **Roles Dinámicos (Emisor / Receptor):** Cualquier dispositivo en la red puede actuar como el control remoto (Emisor) o como la pantalla de presentación (Receptor) mediante una conexión gRPC over LAN.
3. **Soporte Multi-Ventana (Desktop):** En PC, el sistema puede separar el panel de control (ventana principal) de la proyección visual (ventana secundaria o pantalla extendida). La ventana de proyección soporta **F11** para alternar fullscreen.
4. **Módulo Administrativo Integrado:** Un backoffice protegido por credenciales dentro de la misma app para gestionar el CRUD completo de himnos, categorías, pistas y fondos sin depender de software externo.
5. **Resiliencia Offline:** Base de datos embebida (SQLite) y red de área local (mDNS) para funcionar sin conexión a Internet.

---

## 🛠️ Stack Tecnológico

* **Frontend y Lógica de Cliente/Servidor:** Flutter (Dart).
* **Comunicación de Red (LAN):** gRPC con Protocol Buffers.
* **Descubrimiento de Red (Service Discovery):** mDNS (Multicast DNS) para encontrar automáticamente la PC desde el móvil.
* **Motor de Base de Datos:** SQLite (Serverless, local, embebida en la app).
* **Formato de Letra y Acordes:** ChordPro (ej. `[G]Dios es [C]amor`).

---

## 🏗️ Arquitectura de Software y Soluciones Técnicas

### 1. Comunicación (gRPC over LAN)
Se descarta el uso de infrarrojo, Bluetooth y APIs REST. El celular actúa como **Cliente gRPC** y la PC/TV como **Servidor gRPC**. Esto garantiza una latencia mínima usando mensajes binarios (Protobuf), permitiendo enviar comandos ("Siguiente Estrofa") y recibir el estado actual de la pantalla en milisegundos.

### 2. Transposición de Tonalidades
No se guardan acordes en campos separados. Se utiliza el estándar **ChordPro**. 
* **Lógica:** Flutter extrae mediante Regex todo lo que está entre corchetes `[]` en el texto de la base de datos, lo busca en un arreglo circular de notas `['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']` y lo desplaza los semitonos requeridos en tiempo real antes de renderizar la pantalla.

### 3. Personalización de Arreglos (El patrón "Fork")
Para evitar que un músico modifique el himno oficial de la congregación, se implementa un sistema de derivación (Fork). Los datos oficiales son inmutables. Cuando un usuario quiere alterar acordes, el sistema copia las estrofas a la tabla `Estrofa_Arreglo`, vinculándolas a su ID de `Usuario`. La app cargará esta versión personalizada únicamente para ese usuario.

---

## 🏗️ Novedades de Arquitectura UI (Dev Mode)
Para facilitar el desarrollo en entornos Linux sin necesidad de compilar constantemente a un dispositivo móvil físico, la rama de desarrollo incluye un **Switch `(PC/Celular)`** en la esquina inferior izquierda del Dashboard. 
Este switch inyecta la lógica de la plataforma correspondiente, forzando a la app a redibujarse simulando el comportamiento de escritorio (doble ventana, presentación) o de móvil (scroll, FAB dinámico). *Esta opción será reemplazada en producción por la detección nativa de `Platform.isAndroid` o `Platform.isWindows`.*

---

# 🗄️ Esquema de Base de Datos Definitivo (Himnario 2.0)

Este documento detalla la estructura relacional de la base de datos, optimizada tanto para SQLite (entorno local embebido) como para SQL Server (entorno web en la nube).

## 📖 Tablas Maestras

### `Pais`
Catálogo de países normalizado para evitar duplicados ("El Salvador", "el salvador", "SV").
* `id` (PK, Integer)
* `nombre` (Text, UNIQUE): Ej. "El Salvador", "México", "Guatemala".
* `codigo` (Text, Nullable): Código ISO de 2 letras (Ej. "SV", "MX").

### `Himno`
El registro principal de cada alabanza.
* `id` (PK, Integer)
* `titulo_principal` (Text)
* `numero_oficial` (Integer, Nullable): Número en el himnario oficial (no es UNIQUE para permitir himnos con mismo número en distintos países).
* `tipo` (Integer): 1 = Oficial, 2 = Inspirada, 3 = Convención.
* `activo` (Integer, Default 1): Soft-delete.
* `fecha_creacion` (Text, Default datetime('now')).

### `Version_Pais`
Permite manejar variaciones de letra y tonalidad base según la región.
* `id` (PK, Integer)
* `himno_id` (FK -> Himno.id)
* `pais_id` (FK -> Pais.id): Referencia al país normalizado.
* `tonalidad_original` (Text, Default 'C'): Ej. "G", "Am".
* `activo` (Integer, Default 1).

### `Estrofa` (Oficial)
Contiene la letra original e inmutable.
* `id` (PK, Integer)
* `version_pais_id` (FK -> Version_Pais.id)
* `tipo` (Text): Coro, Estrofa, Puente.
* `orden` (Integer): Secuencia de aparición (1, 2, 3...).
* `contenido` (Text): Letra con formato ChordPro (Ej. `[G]Dios es amor`).

---

## 🏷️ Tablas de Categorización (N:M)

### `Categoria`
* `id` (PK, Integer)
* `nombre` (Text): Ej. "Adoración", "Avivamiento", "Santa Cena".

### `Himno_Categoria`
Tabla puente para la relación muchos a muchos.
* `himno_id` (FK -> Himno.id)
* `categoria_id` (FK -> Categoria.id)

---

## 🔐 Sistema de Arreglos Personalizados (Forks) y Administración

### `Usuario`
Gestión de acceso al backoffice y control de autoría de arreglos y pistas.
* `id` (PK, Integer)
* `username` (Text, UNIQUE): Credencial para el login (ej: 'admin').
* `password_hash` (Text): Clave encriptada (Hash).
* `nombre` (Text): Nombre a mostrar del usuario.
* `rol` (Text): 'Admin', 'Musico', 'Visualizador'.

### `Arreglo_Musical`
Cabecera del "Fork" o versión alterada creada por un músico específico.
* `id` (PK, Integer)
* `version_pais_id` (FK -> Version_Pais.id): Apunta a la versión oficial base.
* `usuario_id` (FK -> Usuario.id): Dueño del arreglo.
* `nombre_arreglo` (Text): Ej. "Versión Acústica", "Tono bajado".
* `tonalidad_base` (Text)

### `Estrofa_Arreglo` (Personalizada)
Las estrofas modificadas por el usuario, que se cargarán en lugar de las oficiales al activar el arreglo.
* `id` (PK, Integer)
* `arreglo_musical_id` (FK -> Arreglo_Musical.id)
* `tipo` (Text)
* `orden` (Integer)
* `contenido` (Text): Formato ChordPro con las ediciones exclusivas del músico.

---

## 🎵 Multimedia y Apariencia

### `Pista_Audio`
* `id` (PK, Integer)
* `himno_id` (FK -> Himno.id)
* `ruta_archivo` (Text): Ruta local o URL de almacenamiento.
* `descripcion` (Text): Ej. "Pista Acústica 120bpm".
* `usuario_donante_id` (FK -> Usuario.id)

### `Fondo_Pantalla`
Gestión de fondos dinámicos utilizables durante el Modo Proyección.
* `id` (PK, Integer)
* `nombre` (Text): Ej. "Cielo Estrellado".
* `tipo` (Text): 'imagen', 'video', 'color_solido'.
* `ruta_archivo` (Text): Ruta local del asset multimedia.
* `color_hex` (Text, Nullable): Color en formato #RRGGBB (para tipo color_solido).
* `es_predeterminado` (Integer, Default 0): Indica si es el fondo a cargar por defecto (1 = Sí, 0 = No).
* `activo` (Integer, Default 1).

---

## ⚙️ Configuración e Historial

### `Configuracion`
Tabla clave-valor para persistir preferencias de usuario (fuente, colores, tamaño de letra, etc.).
* `clave` (PK, Text)
* `valor` (Text, NOT NULL)

### `Historial_Reproduccion`
Registro de himnos reproducidos para mantener un historial reciente.
* `id` (PK, Integer)
* `himno_id` (FK -> Himno.id)
* `version_pais_id` (Integer, Nullable)
* `timestamp` (Text, Default datetime('now'))

---

## 📂 Estructura de Carpetas Recomendada (Clean Architecture)

Para que el equipo de trabajo o cualquier agente de IA entienda el código, se recomienda la siguiente estructura basada en *Clean Architecture* orientada a Flutter:
[file-tag: README.md]

```text
lib/
│
├── core/                   # Archivos compartidos, utilidades y configuración
│   ├── constants/          # Constantes (colores, arrays musicales de transposición)
│   ├── network/            # Configuración de mDNS, WebSockets (SignalR)
│   ├── database/           # Configuración de SQLite y migraciones
│   └── window_manager/     # [NUEVO] Lógica para abrir la 2da ventana en PC (Desktop)
│
├── protos/                 # Definiciones de gRPC (.proto) 
│   ├── hymn_control.proto  # Contratos de los mensajes LAN
│   └── generated/          # Código Dart autogenerado por protoc
│
├── data/                   # Capa de datos
│   ├── models/             # Modelos de SQLite/JSON (HimnoModel, UsuarioModel...)
│   ├── datasources/        # Consultas crudas a SQLite, llamadas gRPC y API Web
│   └── repositories/       # Implementación de los repositorios
│
├── domain/                 # Lógica de negocio pura (independiente del framework)
│   ├── entities/           # Entidades (Himno, ArregloMusical, FondoPantalla)
│   ├── usecases/           # Casos de uso (ej. TransposeChordsUseCase, LoginAdminUseCase)
│   └── repositories/       # Interfaces de repositorios
│
└── presentation/           # Capa visual (Flutter UI) - [ACTUALIZADA PARA MODO DUAL]
    │
    ├── dual_mode_wrapper/  # [NUEVO] Wrapper principal y Switch (PC/Celular) para Dev
    │
    ├── views_personal/     # [EVOLUCIÓN] Antiguo app_controller
    │   ├── dashboard/      # Buscador principal y filtros
    │   └── hymn_scroll/    # Letra escrolleable, FAB dinámico y menús de músico
    │
    ├── views_projection/   # [EVOLUCIÓN] Antiguo app_display y control remoto
    │   ├── controller/     # Panel minimalista del Emisor (Flechas, controles)
    │   └── display/        # Fondo negro y recepción de estrofas (Receptor / 2da Ventana)
    │
    ├── views_admin/        # [NUEVO] El Backoffice (El Candado)
    │   ├── login/          # Pantalla de validación admin
    │   ├── crud_hymns/     # Creador/Editor de himnos con bloques ChordPro
    │   └── crud_catalogs/  # ABM de Categorías, Países, Pistas y Fondos
    │
    ├── shared_widgets/     # Widgets comunes (renderizador de ChordPro, botones)
    └── state_management/   # Gestores de estado (Riverpod/Provider)

---

## 🔧 Configuración del Proyecto

### Dependencias principales
| Paquete | Uso |
|---|---|
| `flutter_riverpod` | Manejo de estado |
| `sqflite` / `sqflite_common_ffi` | Base de datos SQLite multiplataforma |
| `audioplayers` | Reproducción de audio |
| `file_picker` | Selector de archivos |
| `path_provider` | Rutas del sistema de archivos |
| `country_flags` | Banderas de países (no implementado aún) |

### Build Android

```bash
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=/home/melquisedec/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Generar APKs por arquitectura (recomendado, ~24MB c/u)
flutter build apk --release --split-per-abi
```

APK moderno: `build/app/outputs/flutter-apk/mq-app-arm64-v8a-{version}.apk` (~24MB)
APK antiguo: `build/app/outputs/flutter-apk/mq-app-armeabi-v7a-{version}.apk` (~22MB)

> Script automatizado: `./scripts/build_apk.sh [version]`

### Build Windows

El ejecutable se genera via CI (GitHub Actions):
```yaml
# .github/workflows/build_windows.yml
# Se activa manualmente o al pushear tags v*
```
El .exe se llama **`MQ_App.exe`** (configurado en `windows/CMakeLists.txt`).

## 🗄️ Database Auto-Update

El sistema soporta actualización automática de la base de datos precargada sin perder datos de usuario.

### Cómo funciona

1. **`assets/db/db_version.json`** contiene la versión actual del seed data (ej. `{"version": 3}`).
2. Al iniciar, `DbVersionManager` compara la versión del asset contra `db_version_applied.txt` en el directorio de documentos.
3. Si `assetVersion > localVersion`, se activa el flujo de actualización:
   - Backup de datos de usuario (tablas: `Usuario`, `Arreglo_Musical`, `Estrofa_Arreglo`, `Configuracion`, `Fondo_Pantalla`, `Historial_Reproduccion`, `Pista_Audio`).
   - Reemplazo del archivo `.db` completo desde assets.
   - Restauración de datos de usuario en la nueva BD.
   - Escritura del marker de versión local.
4. Luego se abre la BD con `onCreate`/`onUpgrade` para manejar migraciones de esquema SQLite.

### Versiones independientes

| Concepto | Dónde se define | Cuándo se incrementa |
|----------|----------------|----------------------|
| **Asset version** | `assets/db/db_version.json` | Cambia seed data (himnos, estrofas) |
| **SCHEMA_VERSION** | `DatabaseHelper` (constante 6) | Cambia estructura de tablas/columnas |

### Para desarrollar/actualizar

```bash
# 1. Reemplazar la BD precargada
cp nueva_base.db assets/db/himnario_id.db

# 2. Actualizar versión del asset
echo '{"version": 3}' > assets/db/db_version.json

# 3. Si hay migraciones de esquema, actualizar SCHEMA_VERSION
#    y agregar migración en _onUpgrade()

# 4. Verificar que el asset esté listado en pubspec.yaml
#    (ya incluido: assets/db/db_version.json, assets/db/himnario_id.db)
```

### Pistas de Audio
- Alojadas en GitHub Releases: `v1.0-audio`
- URL base: `https://github.com/moy385/HimnarioID_2.0/releases/download/v1.0-audio/`
- La app descarga bajo demanda y almacena localmente

### Documentación adicional (en `doc/`)
- `doc/CONTEXTO_PROYECTO.md` — Contexto completo del proyecto
- `doc/tareas_pendientes.md` — Estado actual y prioridades
- `doc/implementacion.md` — Reporte de implementación DB auto-update
- `doc/ANDROID_BUILD.md` — Guía de build para Android
- `doc/BUILD_WINDOWS.md` — Build de Windows .exe (CI y local)
- `doc/CONEXION_LAN.md` — Conexión gRPC Emisor/Receptor vía LAN
- `doc/git-ramas-guia.md` — Guía de ramas y flujo Git
- `doc/PLAN_DE_DELEGACION.md` — Plan histórico de trabajo con agentes
- `doc/TAREAS_DIFERIDAS.md` — Tareas diferidas para próximos sprints
- `doc/Interfaz.md` — Diseño de vistas y flujo de usuario
- `doc/TASKS_DESIGN.md` — Tareas de diseño pendientes
- `doc/TASKS_DEV.md` — Tareas de desarrollo pendientes
