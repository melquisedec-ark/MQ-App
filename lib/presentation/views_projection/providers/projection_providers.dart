import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/fondo_repository_impl.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../domain/repositories/control_repository.dart';
import '../../../domain/repositories/fondo_repository.dart';
import 'connection_providers.dart';

// ─── Providers de infraestructura ───────────────────────────

/// Provider del datasource local de catálogo.
final catalogDataSourceProvider = Provider<CatalogLocalDataSource>((ref) {
  return CatalogLocalDataSource();
});

/// Provider del repositorio de fondos de pantalla.
final fondoRepositoryProvider = Provider<FondoRepository>((ref) {
  final dataSource = ref.read(catalogDataSourceProvider);
  return FondoRepositoryImpl(dataSource);
});

// ─── Enumeraciones ───

/// Opciones de fondo para la proyección.
enum ProjectionBackground {
  black,
  color,
  image,
}

/// Opciones de tamaño de fuente para la proyección.
enum ProjectionFontSize {
  small,
  medium,
  large,
  extraLarge,
}

// ─── Modelo de configuración ───

/// Clase centinela para [ProjectionConfig.copyWith].
///
/// Permite distinguir entre "no se proporcionó el argumento" y
/// "se proporcionó explícitamente `null`" en parámetros de tipo
/// `FondoPantalla?`.
class _FondoSentinel {
  const _FondoSentinel();
}

/// Configuración completa de la proyección en vivo.
class ProjectionConfig {
  final ProjectionBackground background;

  /// @deprecated Usar [HymnAppearanceState.bgColor] de hymnAppearanceProvider.
  @Deprecated('Usar bgColor de hymnAppearanceProvider')
  final Color backgroundColor;

  /// @deprecated Usar [HymnAppearanceState.fontScale] de hymnAppearanceProvider.
  @Deprecated('Usar fontScale de hymnAppearanceProvider')
  final ProjectionFontSize fontSize;

  final double transitionSpeed;
  final FondoPantalla? fondoSeleccionado;

  const ProjectionConfig({
    this.background = ProjectionBackground.black,
    this.backgroundColor = Colors.black,
    this.fontSize = ProjectionFontSize.medium,
    this.transitionSpeed = 0.5,
    this.fondoSeleccionado,
  });

  /// Valor centinela para evitar ambigüedad con `null` en [copyWith].
  static const _fondoSentinel = _FondoSentinel();

  ProjectionConfig copyWith({
    ProjectionBackground? background,
    Color? backgroundColor,
    ProjectionFontSize? fontSize,
    double? transitionSpeed,
    Object? fondoSeleccionado = _fondoSentinel,
  }) {
    return ProjectionConfig(
      background: background ?? this.background,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontSize: fontSize ?? this.fontSize,
      transitionSpeed: transitionSpeed ?? this.transitionSpeed,
      fondoSeleccionado: fondoSeleccionado == _fondoSentinel
          ? this.fondoSeleccionado
          : fondoSeleccionado as FondoPantalla?,
    );
  }

  /// Retorna el valor numérico del tamaño de fuente en pts.
  double get fontSizeValue {
    switch (fontSize) {
      case ProjectionFontSize.small:
        return 28;
      case ProjectionFontSize.medium:
        return 36;
      case ProjectionFontSize.large:
        return 48;
      case ProjectionFontSize.extraLarge:
        return 64;
    }
  }

  /// Retorna la duración de la transición en milisegundos.
  int get transitionDurationMs {
    // Mapear 0.0 -> 1200ms (lento), 1.0 -> 200ms (rápido)
    return 1200 - (transitionSpeed * 1000).round();
  }
}

// ─── StateNotifier ───

/// Notifier para la configuración de proyección.
class ProjectionConfigNotifier extends StateNotifier<ProjectionConfig> {
  static final _log = Logger('ProjectionConfigNotifier');

  final ControlRepository _controlRepository;

  ProjectionConfigNotifier(this._controlRepository)
      : super(const ProjectionConfig());

  void setBackground(ProjectionBackground bg) {
    state = state.copyWith(background: bg);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  void setFontSize(ProjectionFontSize size) {
    state = state.copyWith(fontSize: size);
  }

  void setTransitionSpeed(double speed) {
    state = state.copyWith(
      transitionSpeed: speed.clamp(0.0, 1.0),
    );
  }

  /// Establece el fondo de pantalla seleccionado y envía el comando
  /// [SET_BACKGROUND] por gRPC al display remoto si hay conexión activa.
  Future<void> setFondoSeleccionado(FondoPantalla? fondo) async {
    state = state.copyWith(fondoSeleccionado: fondo);

    if (fondo != null) {
      try {
        final success = await _controlRepository.sendSetConfig(
          fondo: fondo.id.toString(),
        );
        if (!success) {
          _log.warning(
            'El display rechazó el cambio de fondo #${fondo.id}',
          );
        }
      } catch (e) {
        _log.warning('Error al enviar SET_BACKGROUND por gRPC: $e');
      }
    }
  }

  void reset() {
    state = const ProjectionConfig();
  }
}

// ─── Providers ───

/// Provider principal de configuración de proyección.
final projectionConfigProvider =
    StateNotifierProvider<ProjectionConfigNotifier, ProjectionConfig>((ref) {
  final controlRepo = ref.read(controlRepositoryProvider);
  return ProjectionConfigNotifier(controlRepo);
});
