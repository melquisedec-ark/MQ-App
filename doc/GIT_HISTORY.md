# Historial de Git — MQ-App (Fase 1)

> **Branch activo:** `mq-app-init` (orphan, sin remote)
> **Total de commits:** 11
> **Rango de fechas:** 31 de mayo de 2026
> **Remote:** (ninguno — pendiente para Fase 4 deployment)

---

## Estrategia de branch

### Branch: `mq-app-init` (orphan branch)

La Fase 1 trabajó sobre una **branch huérfana** (orphan branch), creada con:

```bash
git checkout --orphan mq-app-init
git rm -rf .       # limpia los archivos del commit padre
git commit -m "feat: iniciar MQ App ..."
```

**¿Por qué una branch huérfana y no `main`?**

- **Limpieza de historia:** la historia de commits queda 100% asociada al
  proyecto MQ-App. No se ven los ~150 commits previos de HimnarioID 2.0
  (con sus issues, reverts, y mensajes de debugging).
- **Independencia legal/técnica:** HimnarioID 2.0 es código del propio
  usuario, pero el contenido (himnos) está bajo verificación de copyright.
  Empezar limpio evita mezclas accidentales.
- **Reset limpio permitido:** como no hay ancestro común con HimnarioID
  2.0, se puede hacer `git reset --hard` o `git rebase -i` sin riesgo de
  "reconstruir" la historia del proyecto anterior.
- **Fácil de exportar:** la branch es un snapshot autocontenido.

**Trade-off conocido:** los archivos de HimnarioID 2.0 que MQ-App reutiliza
se mantienen **idénticos** en el primer commit (no hay commits intermedios
mostrando la copia). Esto es intencional.

### Branch: `main` (del upstream, conservada)

`main` se conserva por compatibilidad con el workflow de HimnarioID 2.0
(release pipeline, GitHub Actions, etc.). **No es la branch de desarrollo**
de MQ-App.

### Cuándo mergear a `main`

**Difierido al release v1.0.** Razones:

- Mientras MQ-App esté en desarrollo activo, mantener la historia en
  `mq-app-init` permite trabajar sin afectar workflows de release existentes.
- En v1.0, se hará un merge fast-forward de `mq-app-init` → `main`,
  actualizando los assets, versionado, y CHANGELOG.
- Los merges intermedios a `main` solo traerían el riesgo de activar
  pipelines antes de tiempo.

### Plan de remote setup (Fase 4, deployment)

El proyecto **no tiene remote aún**. El setup es:

```bash
# Cuando se decida publicar (post-v1.0)
git remote add origin https://github.com/moy385/MQ-App.git
git push -u origin mq-app-init
git push -u origin main    # después del merge final
```

**Token de GitHub:** almacenado en engram memory (observation #579, scope
**personal**, NO en el repo). El token tiene scope `repo` completo pero
**no debe aparecer en logs ni en commits**. Se usará vía `gh CLI` o
credential helper, no en URLs del remote.

> ⚠️ Nunca commitear el token. Nunca ponerlo en `git remote add` URLs. Usar
> `gh auth login` o `git credential-store`.

---

## Log de commits (11 total)

Commits en orden cronológico (del más antiguo al más nuevo), branch
`mq-app-init`. Generado con `git log --oneline mq-app-init`.

| #  | Hash       | Fecha (GMT-6) | Mensaje                                                                       |
|----|------------|---------------|-------------------------------------------------------------------------------|
| 1  | `c302973`  | 31 may 16:39  | `feat: iniciar MQ App (Biblia + Himnario) basado en HimnarioID 2.0 v2.1.7`   |
| 2  | `3fa7cfb`  | 31 may 17:09  | `feat(db): add Bible database schema and folder structure`                    |
| 3  | `4326257`  | 31 may 17:13  | `docs(design): add Phase 1 wireframes for home, Bible, emitter`               |
| 4  | `df951c7`  | 31 may 17:22  | `chore(db): ignorar archivos de DB generados en runtime`                      |
| 5  | `de0caa3`  | 31 may 17:22  | `chore: eliminar archivos legacy de sesiones anteriores`                      |
| 6  | `3408fa2`  | 31 may 17:43  | `chore: rename com.example.mqapp bundle ID to com.mqapp (H1)`                 |
| 7  | `7b847e9`  | 31 may 17:43  | `docs(design): mark @arqui decisions in style guide (palette, glass, 20 UX)`  |
| 8  | `79d7e03`  | 31 may 17:46  | `fix(db): add triggers to validate version-libro consistency in favoritos y notas` |
| 9  | `52a6275`  | 31 may 17:48  | `feat(db): bundle SQLite 3.46+ via FFI on all platforms (B2)`                |
| 10 | `110c979`  | 31 may 19:21  | `feat(ios): regenerate iOS project with flutter create (B1)`                  |
| 11 | `6d761cf`  | 31 may 19:22  | `docs: update README.md for MQ-App branding and Bible module (M1)`            |

**HEAD actual:** `6d761cf8ec5b434c6e8f4020f45f486a9f2a798a` (rama `mq-app-init`).

> Nota: existe un commit `326761e` en el object store (Bible schema inicial
> previo al reset) pero **no es alcanzable** desde `mq-app-init`; fue
> descartado por `git reset HEAD~1` el mismo día. El commit `3fa7cfb`
> reproduce su contenido.

### Conteo por tipo de commit

| Tipo        | Conteo | Commits                                            |
|-------------|--------|----------------------------------------------------|
| `feat:`     | 4      | 1, 2, 9, 10                                        |
| `fix:`      | 1      | 8                                                  |
| `docs:`     | 3      | 3, 7, 11                                           |
| `chore:`    | 3      | 4, 5, 6                                            |
| **Total**   | **11** |                                                    |

---

## Convención de mensajes (Conventional Commits)

MQ-App sigue [Conventional Commits 1.0](https://www.conventionalcommits.org/)
simplificado:

```
<tipo>(<scope>): <descripción corta en inglés>

[cuerpo opcional: por qué, no qué]
[footer opcional: refs a issues, breaking changes]
```

**Tipos permitidos:**

| Tipo       | Uso                                                  |
|------------|------------------------------------------------------|
| `feat:`    | Nueva funcionalidad visible para el usuario          |
| `fix:`     | Bug fix                                              |
| `docs:`    | Solo documentación (no cambio de código)             |
| `style:`   | Formato, espacios, comas (no cambio lógico)          |
| `refactor:`| Cambio de código que no agrega feature ni arregla bug |
| `chore:`   | Build, dependencias, assets, tareas de mantenimiento  |
| `test:`    | Solo tests                                           |

**Scopes usados en Fase 1:**

- `db` — esquema de base de datos, migraciones, seeds
- `ios` — cambios específicos de iOS
- `design` — wireframes, decisiones de UX/UI
- (sin scope) — cambios generales o multi-área

**Sufijos especiales observados:**

- `(B1)`, `(B2)` — issues CRITICAL resueltos (ver `PHASE_1_REPORT.md`)
- `(H1)` — issue HIGH resuelto
- `(M1)` — issue MEDIUM resuelto

**Reglas de idioma:** descripción corta en **inglés**, cuerpo en español
(equipo hispanohablante). Esto facilita búsqueda en GitHub y tooling de
release notes.

---

## Cómo verificar que la historia está limpia

```bash
# 1. Verificar branch y commit actual
cd /home/melquisedec/Escritorio/Projects/Personales/MQ-App
git rev-parse --abbrev-ref HEAD     # → mq-app-init
git rev-parse HEAD                  # → 6d761cf8ec5b434c6e8f4020f45f486a9f2a798a

# 2. Contar commits (debe dar 11)
git log --oneline mq-app-init | wc -l

# 3. Verificar que NO hay remote configurado
git remote -v                       # → (vacío)

# 4. Verificar que el padre del commit inicial es null (orphan)
git rev-list --parents -n 1 $(git log --oneline mq-app-init | tail -1 | awk '{print $1}')
# Solo debe mostrar el hash, sin padres adicionales.

# 5. Verificar que no hay commits sin firmar accidentalmente
git log --pretty=format:"%H %an <%ae>" mq-app-init
# Comprobar que todos los autores son: @user, @dev, o @arqui
```

**Señales de "historia sucia"** (no deben estar presentes):

- ❌ Commits de HimnarioID 2.0 visibles en el log
- ❌ Commits con mensajes tipo "WIP", "asdf", "fix fix"
- ❌ Commits con secrets en el diff (tokens, passwords)
- ❌ Commits que modifican archivos generados (`.g.dart`, `build/`, etc.)

**Estado actual:** 🟢 limpio. Las 11 entradas verificadas el 1 jun 2026
(@arqui, review final).

---

## Referencias

- **Reporte ejecutivo:** [`PHASE_1_REPORT.md`](PHASE_1_REPORT.md)
- **Decisiones:** [`ARCHITECTURE_DECISIONS.md`](ARCHITECTURE_DECISIONS.md)
- **Spec original:** `nuevaidea.md` (12 secciones)
- **Conventional Commits spec:** https://www.conventionalcommits.org/
- **Token de GitHub:** engram observation #579 (scope personal, **no** en repo)

---

*Documento creado por @documentador el 1 de junio de 2026*
*Para preguntas, contactar a @arqui o @user*
