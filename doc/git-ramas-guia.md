# 🚀 Guía Completa de Ramas en Git y GitHub
### Para flujo de trabajo en equipo pequeño (1 persona) con Flutter/Dart en Linux

> **Propósito:** Referencia rápida para el desarrollo de HimnarioID 2.0
> **Fecha:** 22 de mayo de 2026

---

## 1. Conceptos Básicos de Ramas

### ¿Qué es una rama en Git?

Una **rama (branch)** es una línea independiente de desarrollo. Piensa en ella como un "universo paralelo" de tu código:

```
main   ●────●────●────────────────────●
                      ↖               ↗
feature/login           ●──●──●──●
```

Puedes hacer cambios en una rama sin afectar `main` ni otras ramas. Cuando terminas, fusionas (`merge`) los cambios de vuelta.

### ¿Qué es `main`?

Es la rama **principal y por defecto** del repositorio. Aquí debe vivir siempre el código **estable y funcional**.

> ⚠️ **Regla de oro**: *Nunca trabajes directamente en `main`*. Siempre crea una rama separada para cada tarea.

### ¿Cómo se relacionan las ramas entre sí?

Las ramas nacen de otras ramas. Por lo general:

- Creas una rama **feature** desde `main`
- Trabajas en la rama feature
- Fusionas la rama feature de vuelta a `main`

---

## 2. Comandos Esenciales para el Día a Día

> 💡 Desde Git 2.23 se recomienda usar `git switch` para ramas y `git restore` para archivos.

| Acción | Comando moderno | Equivalente clásico |
|---|---|---|
| **Crear rama** | `git branch <nombre>` | `git branch <nombre>` |
| **Crear y cambiarse** | `git switch -c <nombre>` | `git checkout -b <nombre>` |
| **Cambiarse de rama** | `git switch <nombre>` | `git checkout <nombre>` |
| **Listar ramas** | `git branch` | `git branch` |
| **Eliminar rama local** | `git branch -d <nombre>` | `git branch -d <nombre>` |
| **Eliminar rama remota** | `git push origin --delete <nombre>` | `git push origin :<nombre>` |

### Ejemplos prácticos:

```bash
# Ver en qué rama estás y listar todas
git branch
# * main

# Crear una rama nueva (sin moverte)
git branch feature/ajustes

# Crear y moverte a la vez
git switch -c feature/login

# Moverte a otra rama existente
git switch main

# Forzar eliminación (si tiene cambios sin mergear)
git branch -D feature/experimento
```

---

## 3. Flujo de Trabajo Completo: Feature → Merge a Main

### Paso 1: Asegúrate de estar en `main` y actualizado

```bash
git switch main
git pull origin main
```

### Paso 2: Crea una rama para tu tarea

```bash
git switch -c feature/nueva-pantalla
```

### Paso 3: Trabaja normalmente (varios commits)

```bash
git add .
git commit -m "feat: descripción corta"
```

### Paso 4: Sube la rama a GitHub

La primera vez que subes una rama nueva:

```bash
git push -u origin feature/nueva-pantalla
```

> `-u` vincula tu rama local con la remota. Las siguientes veces basta con `git push`.

### Paso 5: Verifica que todo funciona (¡antes del merge!)

```bash
dart analyze
flutter test
```

> 🔴 **Nunca hagas merge si `dart analyze` o `flutter test` fallan**.

### Paso 6: Vuelve a `main` y actualízalo

```bash
git switch main
git pull origin main
```

### Paso 7: Fusión (merge) la rama feature

```bash
git merge feature/nueva-pantalla
```

### Paso 8: Sube `main` actualizado a GitHub

```bash
git push origin main
```

### Paso 9: Limpieza — elimina la rama feature

```bash
# Local
git branch -d feature/nueva-pantalla

# Remota (en GitHub)
git push origin --delete feature/nueva-pantalla
```

### Visualización del flujo completo:

```
git switch main ── git pull ── git switch -c feature/x
                                              │
                                              ├── dart analyze ✓
                                              ├── flutter test ✓
                                              ├── git add + commit
                                              ├── git push -u origin feature/x
                                              │
                         git switch main ── git pull
                                              │
                                         git merge feature/x
                                              │
                                         git push origin main
                                              │
                                         git branch -d feature/x
                                         git push origin --delete feature/x
```

---

## 4. Cómo Resolver Conflictos de Merge

### ¿Qué causa un conflicto?

Ocurre cuando **dos ramas modifican la misma línea del mismo archivo** y Git no sabe cuál versión conservar.

### ¿Cómo identificarlo?

Cuando ejecutas `git merge`, Git te dirá:

```
Auto-merging lib/main.dart
CONFLICT (content): Merge conflict in lib/main.dart
Automatic merge failed; fix conflicts and then commit the result.
```

Y `git status` te mostrará los archivos en conflicto.

### ¿Cómo resolverlo manualmente?

Abre el archivo en conflicto. Verás marcadores como estos:

```dart
<<<<<<< HEAD
  color: Colors.blue,        // ← lo que está en main
=======
  color: Colors.red,         // ← lo que viene de tu rama
>>>>>>> feature/nueva-pantalla
```

**Tienes tres opciones**:
1. Quedarte con lo de `HEAD`
2. Quedarte con lo de la rama feature
3. Hacer una mezcla personalizada

### ¿Cómo marcar como resuelto?

```bash
git add lib/main.dart        # Marca el archivo como resuelto
git commit                   # Git crea el merge commit
```

### ¿Qué hacer si te equivocas?

```bash
git merge --abort            # Vuelve todo al estado anterior
```

---

## 5. Buenas Prácticas

### Nombres de ramas

| Prefijo | Para qué | Ejemplo |
|---|---|---|
| `feature/` | Nueva funcionalidad | `feature/pc-modo-personal` |
| `fix/` | Corrección de bug | `fix/error-login-vacio` |
| `chore/` | Mantenimiento | `chore/actualizar-dependencias` |
| `refactor/` | Reestructurar código | `refactor/separar-widgets` |
| `docs/` | Documentación | `docs/guia-ramas` |
| `test/` | Tests | `test/cobertura-auth` |

### ¿Cuándo hacer merge?

Solo después de pasar estas verificaciones:

```bash
# 1. Análisis estático
dart analyze

# 2. Tests
flutter test

# 3. (Opcional) Build de prueba
flutter build apk --debug

# 4. (Recomendado) Verificar conteo de tests
flutter test --reporter expanded | grep -E "All tests passed|Some tests failed"
```
> Estado actual del proyecto: **274 tests** (263 unit/widget + 11 integración), `dart analyze lib/` → **0 errors, 0 warnings** (27 info de estilo). Rama activa: `feature/db-auto-update`. Rama estable `main` en commit `f9077af`.

### Mantener la rama feature actualizada con `main`

```bash
git switch feature/mi-rama
git rebase main
```

Esto "recoloca" tus commits encima de todo lo nuevo de `main`.

---

## 6. Comandos Útiles Adicionales

### Ver el árbol de commits

```bash
git log --oneline --graph --all
```

### Ver diferencias entre ramas

```bash
git diff main...feature/login          # Qué tiene feature que no tenga main
git diff main...feature/login -- lib/main.dart  # Solo un archivo
```

### Guardar cambios temporales (stash)

```bash
git stash                               # Guarda cambios sin commitear
git switch main                         # Cámbiate sin problemas
git switch feature/mi-rama              # Vuelve a tu rama
git stash pop                           # Recupera los cambios
```

### Merge con commit explícito

```bash
git merge --no-ff feature/login
```

`--no-ff` fuerza un commit de merge visible en el historial.

---

## Historial de Ramas (mayo 2026)

| Rama | Descripción | Estado |
|------|-------------|--------|
| `feature/pc-modo-personal` | Adaptación UI para escritorio | ✅ Mergeada a main |
| `feature/fase4-subprocess-window` | Ventana secundaria con IPC JSON | ✅ Mergeada a main |
| `feature/brocha-conectada` | Sincronización IPC de apariencia | ✅ Mergeada a main |
| `feature/escalado-proyeccion` | Font scale independiente en proyección | ✅ Mergeada a main |
| `feature/flujo-presentacion-slides` | Slides Title→Lyrics→Amen | ✅ Mergeada a main |
| `feature/busqueda-android-tabla-plana` | Tabla pre-normalizada para búsqueda | ✅ Mergeada a main |
| `feature/proyeccion-estrofa-visibilidad` | Stack overlay + labels en proyección | ✅ Mergeada a main |
| `feature/acordes-sobre-texto` | ChordParser + ChordPainter + ChordOverlayText con LRU cache | ✅ Mergeada a main |
| `feature/acordes-toggle-global` | Toggle showChords persistente, botón Solfa funcional | ✅ Mergeada a main |
| `feature/proyeccion-auto-fit` | Scroll condicional, medición de contenido | ✅ Mergeada a main |
| `feature/proyeccion-line-breaking` | Reflow de acordes con StanzaLayoutEngine | ✅ Mergeada a main |
| `feature/settings-panel-sin-login` | Admin directo (icono ajustes sin login forzoso) | ✅ Mergeada a main |
| `feature/agregar-himnos-convenciones` | 25 himnos + brocha mejorada + fondos + fix delete | ✅ Mergeada a main |
| `feature/flujo-emisor-receptor` | Conexión gRPC Emisor/Receptor + mDNS + F11 fullscreen + slider proyección en móvil emisor | ✅ Mergeada a main |
| `feature/orden-filtros-admin-crud` | Orden himnos Oficiales primero, filtro Convención, CRUD Usuarios backend | ✅ Mergeada a main |
| `feature/peticiones-mayo-2026` | Cambios solicitados mayo 2026 (revertidos parcialmente) | ✅ Mergeada (y revertida) |
| `feature/db-auto-update` | Mecanismo desacoplado de auto-actualización de BD | 🔶 Abierta (en desarrollo) |

---

## Resumen Rápido — Flujo Diario

```bash
# 1. EMPEZAR UNA TAREA NUEVA
git switch main && git pull
git switch -c feature/mi-tarea

# 2. DURANTE EL TRABAJO
git add archivo.dart
git commit -m "feat: descripción corta"
git rebase main          # si main avanzó mientras tanto

# 3. ANTES DEL MERGE
dart analyze && flutter test

# 4. FUSIONAR A MAIN
git switch main && git pull
git merge --no-ff feature/mi-tarea
git push origin main

# 5. LIMPIAR
git branch -d feature/mi-tarea
git push origin --delete feature/mi-tarea
```
