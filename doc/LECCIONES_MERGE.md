# Lecciones Aprendidas — El Merge de BD y por qué lo matamos

> **Contexto**: Entre v2.1.0 y v2.1.2 existió un sistema de merge incremental
> que copiaba himnos nuevos del asset a la BD local. Se eliminó en v2.1.3
> por bugs crónicos de corrupción de datos.

## Por qué existía el merge

El objetivo era **preservar los datos del usuario** (arreglos musicales, configuraciones) al actualizar la BD, sin tener que hacer backup/restore. La idea era:

1. Leer la BD del asset en un archivo temporal
2. Por cada himno en el asset, buscar si ya existe en la BD local
3. Si no existe → INSERT (himno nuevo)
4. Si existe → UPDATE (correcciones de título, acordes, etc.)
5. Hacer lo mismo con Version_Pais y Estrofa
6. Nunca tocar las tablas de usuario

Parecía sólido en teoría, pero en la práctica...

## Bug 1: Match por `numero_oficial` sin `tipo` (v2.1.0)

### Síntoma
Los himnos de convención (tipo=3, himnos 1-25) sobrescribían a los oficiales (tipo=1) porque compartían el mismo `numero_oficial`.

### Fix
Se agregó `tipo` a la cláusula WHERE: `WHERE numero_oficial = ? AND tipo = ?`.

## Bug 2: Himno 290 — Dos himnos oficiales, mismo número (v2.1.0 – v2.1.2)

### Síntoma
Solo aparecía la versión de El Salvador con el título de Guatemala (o viceversa). Himno 290 tiene DOS himnos OFICIALES (tipo=1) con el mismo `numero_oficial=290`:

| id | País | Título |
|----|------|--------|
| 296 | El Salvador | DÍA DE GRAN LIBERTAD |
| 432 | Guatemala | Escogido Fuí de Dios |

### Causa raíz
El merge consultaba `WHERE numero_oficial=290 AND tipo=1`, que devolvía **dos filas** (id=296 e id=432). El código tomaba `localHymns.first` (siempre id=296) y lo sobrescribía con los datos del segundo himno en la siguiente iteración.

### Primer fix (v2.1.2)
Cambiar el matching de `(numero_oficial, tipo)` a `id` (PRIMARY KEY), con fallback por `(numero_oficial, tipo)` para compatibilidad. Además, escribir `localVersion` temprano para saltar el merge en primera instalación.

### Problema del fix
El merge solo INSERTaba o UPDATEaba, nunca DELETEaba. Los registros huérfanos de Version_Pais que el merge buggy había insertado con `himno_id=296` (cuando debían ser `himno_id=432`) **se quedaban para siempre**. La BD quedaba en un estado inconsistente imposible de sanear con merges sucesivos.

## Bug 3: Merge en primera instalación (v2.1.0 – v2.1.2)

### Síntoma
El merge se ejecutaba sobre una BD recién copiada del asset, que ya contenía todos los datos. Era redundante pero inofensivo... hasta que el merge tenía bugs.

### Fix
Escribir `localVersion` inmediatamente después de copiar la BD del asset, antes de abrirla. Así `needsUpdate()` retorna `false` y el merge se salta.

## Decisión final: Matar el merge (v2.1.3)

Después de 3 bugs distintos en el merge, se decidió reemplazarlo por el enfoque original:

**Backup de datos de usuario → Reemplazar BD completa → Restaurar datos**

### Por qué es mejor

| Aspecto | Merge | Backup + Replace + Restore |
|---------|-------|---------------------------|
| Complejidad | ~260 líneas, lógica condicional en 3 niveles de anidación | ~130 líneas, lineal |
| Consistencia de datos | Garantizada solo si el merge es perfecto | Garantizada siempre (BD = copia exacta del asset) |
| Mantenibilidad | Cada nuevo campo en Himno requiere update del merge | No requiere cambios |
| Riesgo de bugs | Alto (múltiples condiciones de borde) | Bajo (operaciones atómicas: backup, write, restore) |

### Lección aprendida

> **No intentes ser inteligente con los datos.** Copiar la BD completa del asset y restaurar solo los datos de usuario es más simple, más seguro y más mantenible que cualquier merge incremental. La "pérdida" de tener que hacer backup/restore es mínima comparada con el costo de debuggear corrupción de datos.
