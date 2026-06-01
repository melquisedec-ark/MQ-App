# 🌐 Arquitectura Web: Himnario SaaS (Adaptación al Modo Dual)

La versión Web (compilada a través de Flutter Web) aprovecha la misma estructura definida en `interfaz.md`, pero con ajustes de infraestructura para el ecosistema de navegadores.

## 1. Adaptación del Sistema Emisor / Receptor
Dado que un navegador no puede escanear la red LAN:
* Al hacer clic en el **ícono de Conexión**, el sistema web se conecta al backend (SignalR en .NET).
* **Si elige Receptor:** La pantalla web genera un PIN de sala (ej. `4829`) y se queda esperando.
* **Si elige Emisor:** La pantalla solicita el PIN de 4 dígitos. Al ingresarlo, la app web toma el rol de control remoto y muestra el Panel Minimalista.

## 2. El Botón "Presentar" (Soporte Multi-Ventana en la Nube)
En la app local de PC, "Presentar" abre una ventana nativa de OS. En la versión Web:
* El botón invoca el método `window.open()` de Javascript para lanzar un popup o una nueva pestaña sin barras de navegación. 
* El flujo de Auto-Control se mantiene: la pestaña original se vuelve el "Control Remoto" y la nueva pestaña se vuelve el "Receptor Local", comunicándose internamente vía WebSockets locales o eventos del navegador.

## 3. Módulo Administrador en la Web
El **Ícono de Candado** funciona de la misma manera, pero con una ventaja significativa:
* Los catálogos (CRUD de categorías, países, himnos oficiales) modificados por el usuario `admin` en la versión Web impactan en la base de datos central (SQL Server) afectando a todos los usuarios que consuman el servicio web.
* En contraste, los cambios hechos en el candado de la app Local impactan únicamente en el archivo SQLite del dispositivo físico.
