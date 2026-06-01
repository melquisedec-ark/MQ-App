# 🖥️ Diseño de Vistas y Flujo del Usuario (Himnario 2.0 Modo Dual)

Este documento detalla la experiencia de usuario (UX) diferenciando el comportamiento de la app según el dispositivo (Móvil vs. PC) y los roles asumidos por el usuario.

---

## 📱 1. Flujo y Vistas: App Local en Celular

### A. Pantalla Principal (Dashboard)
* **Buscador y Filtros:** Centro de la pantalla.
* **Top-Right:** Ícono de **Conexión** (Abre modal: ¿Emisor o Receptor?).
* **Top-Left:** Ícono de **Candado** (Acceso a Administrador).
* **Bottom-Left (Solo Dev):** Switch `PC/Celular` para simulación de vistas.

### B. Modo Personal (Usuario abre un himno directamente)
* **Vista:** Título fijo superior. Cuerpo escrolleable mostrando la estructura (Estrofa, Coro, Estrofa, Coro).
* **Menú Dinámico FAB (Floating Action Button):** Un botón '+' en la esquina inferior derecha que se despliega verticalmente revelando íconos:
  1. **Cerrar (X):** Contrae el menú.
  2. **Brocha:** Opciones visuales (fondo, fuente, tamaño).
  3. **Nota Musical:** Despliega bottom-sheet con la lista de pistas de audio del himno + controles de reproducción (Play, Pause, barra de progreso).
  4. **Solfa:** Opciones de músico. Activa/Desactiva visualización de acordes, transposición (subir/bajar tono) y botón para "Crear arreglo personalizado".
  5. **Lupa:** Abre una barra de búsqueda sobrepuesta. Al seleccionar un nuevo himno, reemplaza la vista actual (evita acumular historial de navegación).

### C. Modo Conexión: El Celular como "Emisor"
Si el usuario hace clic en Conexión -> "Emisor":
1. **Búsqueda de dispositivo:** Escanea la LAN y se vincula.
2. **Dashboard Alterado:** Regresa a la pantalla principal, pero el ícono de Conexión se reemplaza por un ícono de **Salir / Desconectar**.
3. **Panel de Control (Al seleccionar un himno):** Ya NO se abre el modo escrolleable. Se abre un panel minimalista con botones de acción rápida que impactan al Receptor:
   * **Flecha Izquierda / Derecha:** Navegación por la letra del himno.
   * **Brocha, Solfa, Nota Musical, Lupa:** Funciones idénticas al modo personal, pero los cambios visuales viajan por gRPC al Receptor.
   * **Botón Salir:** Regresa al buscador.

---

## 💻 2. Flujo y Vistas: App en PC (Escritorio / Linux / Windows)

La PC comparte la misma base gráfica del celular (Buscador, Candado, Conexión), pero introduce el manejo de pantallas extendidas.

### A. El Botón "Presentar"
Ubicado en la parte inferior derecha del Dashboard. 
* Si se **activa**, abre una **segunda ventana independiente** con fondo negro, lista para ser arrastrada al proyector/segunda pantalla.

### B. PC Modo Auto-Control (Emisor Local)
Con el botón "Presentar" activo:
* Al hacer clic en un himno, este se envía y se visualiza en la segunda ventana.
* La ventana principal (donde el usuario hizo clic) se transforma en el **Panel de Control minimalista** (flechas, brocha, etc.), permitiendo al operador controlar la presentación desde una sola PC sin usar su celular.

### C. PC Modo Personal
Con el botón "Presentar" apagado:
* Al abrir un himno, se muestra en la ventana principal, pero **estrictamente en Modo Presentación** (no escrolleable, solo avanzar/retroceder con flechas). No se permite editar apariencia aquí para mantener la rigurosidad de la proyección.

### D. PC como "Receptor"
Si el usuario hace clic en Conexión -> "Receptor":
* Muestra pantalla de espera.
* Al conectar con un Emisor, la pantalla pasa a fondo negro y entra en modo esclavo, proyectando únicamente lo que el celular o la otra PC le envíen por red.

---

## 🔐 3. Módulo de Administración (Backoffice)

Accesible desde el **ícono de Candado**.
* **Credenciales por defecto:** Usuario: `admin` | Clave: `admin123`.

### Panel Principal de Administrador
Cuenta con un menú hamburguesa (Top-Right) con dos apartados principales:

#### 1. Sección Himnos (Hoja con lápiz)
* Barra de búsqueda central y lista de resultados.
* Botón FAB `(+)` para agregar nueva alabanza.
* Cada ítem de la lista tiene: **Ícono de Lápiz** (Editar) e **Ícono de Basurero** (Eliminar).
* **Vista de Edición/Creación:** Formulario complejo. Campos para Título, Número, País, Categoría(s) vinculadas, Pistas asociadas. Herramienta de bloques para agregar dinámicamente "Estrofas" o "Coros" con formato ChordPro (manteniendo la esencia del Himnario 1.0 Web).

#### 2. Sección Herramientas / CRUDs (Ícono de Herramientas)
Gestión de catálogos secundarios mediante tabs o cards:
* **Países / Categorías / Pistas.**
* **Fondos:** Permite subir y almacenar archivos de imágenes (`.jpg`, `.png`) o videos cortos (`.mp4`) para usarlos como backgrounds dinámicos en las presentaciones.
* La interfaz para cada uno consiste en un pequeño formulario de agregado superior y una lista de elementos existentes en la parte inferior.
