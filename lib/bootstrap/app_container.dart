import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contenedor global del [ProviderContainer] de Riverpod.
///
/// Permite acceder al contenedor de providers desde fuera del árbol de widgets,
/// por ejemplo en [GrpcDisplayServer] o en servicios que necesiten leer/escribir
/// providers sin tener un [BuildContext] o [WidgetRef].
class AppContainer {
  static final AppContainer _instance = AppContainer._();
  factory AppContainer() => _instance;
  AppContainer._();

  ProviderContainer? _container;

  /// El [ProviderContainer] global de la aplicación.
  /// Lanza un [AssertionError] si no ha sido inicializado.
  ProviderContainer get container {
    assert(_container != null, 'AppContainer no inicializado');
    return _container!;
  }

  /// Inicializa el contenedor con el [ProviderContainer] creado en main().
  void init(ProviderContainer container) {
    _container = container;
  }
}
