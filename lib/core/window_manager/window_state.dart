/// Tipos de eventos que puede emitir la ventana de proyección.
enum WindowEventType {
  opened,
  closed,
  focused,
  message,
}

/// Evento de ventana de proyección.
///
/// Contiene el tipo de evento y datos opcionales asociados.
class WindowEvent {
  /// Tipo de evento ocurrido.
  final WindowEventType type;

  /// Datos adicionales del evento (opcional).
  final Map<String, dynamic>? data;

  const WindowEvent({
    required this.type,
    this.data,
  });
}
