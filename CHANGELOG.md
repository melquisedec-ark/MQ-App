# Changelog

Todas las versiones notables de MQ-App. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [1.0.1] — 2026-06-02

### Fixed
- **B1**: Note editor now respects default color from `notaColorDefaultProvider` (note_editor_modal.dart)
- **B2**: Bible reader respects `autoHistorialProvider` toggle — history only records when enabled
- **B3**: Consolidated duplicate `themeModeProvider` (was in both biblia_config_provider and shared_widgets/providers) — single source in `biblia_config_provider.dart`, consumed correctly in `main.dart`
- **B4**: Added `hymn-detail` GoRoute to app_router.dart — hymn detail navigation now works correctly
- **B5**: Centralized `showAppSnackBar` helper in `lib/core/ui/app_snackbar.dart` — 3s auto-dismiss, anti-stacking, 4 types (info/success/warning/error)
- **D13**: Theme mode persistence verified — no more duplicate providers causing state conflicts

### Added
- **D1**: Removed RV1569 placeholder from biblia.db (saved 7.74MB, -51% DB size)
- **D2**: Consolidated theme mode provider architecture
- **D3**: FAB theme toggle (sun/moon) on home screens using existing `ThemeModeToggleButton`
- **D5**: Centralized `AppSnackBar` helper — eliminates duplicated snackbar code across 14+ files
- **D6**: Bible Reader chapter view with `scrollable_positioned_list` — verse↔chapter toggle
- **D7**: About screen with PackageInfo, repo URL, social placeholders (WhatsApp, official page)
- **D8**: AdminHimnario screen with Himnos + Catálogos TabBar
- **D10**: Bible reader history tracking respects auto-historial toggle
- **D11**: Hymn detail route properly configured in GoRouter
- **D12**: Deleted dead `MqDualApp` code (122 lines, never used from main.dart)
- **D14**: Removed all glassmorphism from the app (was causing performance issues)
- CONTROL folder for project tracking (PENDIENTE.md, CORRECCIONES.md, DECISIONES.md, BITACORA.md, RESUMEN.md)
- Wireframe 06 (About Screen) and Wireframe 07 (Admin Himnario)

### Changed
- DB version bumped from 1 to 2 (safety backup, DELETE CASCADE, VACUUM, FTS5 optimize)
- Bundle size: AAB 60MB → 55.5MB, APK 72MB → 71.6MB
- 514 tests passing (was 476)

### Removed
- RV1569 placeholder from biblia.db (no structured source available)
- Glassmorphism from entire UI
- Dead `MqDualApp` class
- Duplicate `themeModeProvider` in shared_widgets/providers

---

## [1.0.0] — 2026-06-02 (Initial Release)

### Added
- Bible module with RV1909 (31,102 verses)
- Full-text search (FTS5) with debounce
- Book selector with 5 tabs: AT / NT / Favoritos / Notas / Historial
- Chapter grid screen with random chapter button
- Bible reader screen with verse interaction
- Note editor modal with color system (yellow/green/blue/none)
- Settings screen with config table integration
- Emitter view mode toggle (compact/preview)
- Home screen with random verse display
- GoRouter routing with 8 routes
- gRPC Bible command handlers and client providers
- Dark/Light theme mode with persistence
- SQLite 3.46+ bundled via FFI
- 476 unit/widget tests
- Signed AAB + APK builds
- GitHub Release v1.0.0

### Architecture
- Clean Architecture (data/domain/presentation)
- Riverpod 2.x for state management
- go_router for navigation
- gRPC for LAN communication
- SQLite + FTS5 for local database
- mDNS for service discovery

---

## [Unreleased]

### Planned for v1.1
- Bottom navigation bar (Home/Bible/Hymnal/Settings)
- Hymnal favorites and notes (parity with Bible)
- Bible sharing (copy verse text)
- Presentation mode for Bible (PC)
- Windows .exe build (GitHub Actions or Windows machine)
- RV1569 replacement (when structured source available)
- More Bible versions (architecture supports multi-version)
