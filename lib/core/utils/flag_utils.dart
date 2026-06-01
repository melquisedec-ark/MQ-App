/// Utilidad para convertir códigos ISO 3166-1 alpha-2 a emoji de bandera.
///
/// Ejemplo: "SV" → 🇸🇻, "MX" → 🇲🇽, "GT" → 🇬🇹
///
/// Los Regional Indicator Symbols (U+1F1E6..U+1F1FF) son el estándar
/// Unicode para representar banderas de países mediante pares de letras.
/// Ver: https://en.wikipedia.org/wiki/Regional_indicator_symbol
class FlagUtils {
  /// Offset entre la letra ASCII (A=65) y su Regional Indicator Symbol (🇦=127462)
  static const int _offset = 127397;

  /// Convierte un código ISO de 2 letras a su emoji de bandera.
  ///
  /// Retorna una cadena vacía si [code] es nulo o no tiene exactamente 2 caracteres.
  static String codeToFlag(String? code) {
    if (code == null || code.length != 2) return '';
    final upper = code.toUpperCase();
    final first = upper.codeUnitAt(0) + _offset;
    final second = upper.codeUnitAt(1) + _offset;
    return String.fromCharCodes([first, second]);
  }
}
