import '../chords/chord_parser.dart';

/// Utilidad para normalizar strings, usada principalmente para
/// ordenamiento inteligente que ignore acentos, diéresis y símbolos.
class StringUtils {
  static const _accents = <String, String>{
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
    'â': 'a', 'ê': 'e', 'î': 'i', 'ô': 'o', 'û': 'u',
    'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ü': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'À': 'A', 'È': 'E', 'Ì': 'I', 'Ò': 'O', 'Ù': 'U',
    'Â': 'A', 'Ê': 'E', 'Î': 'I', 'Ô': 'O', 'Û': 'U',
    'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ü': 'U',
    'ñ': 'n', 'Ñ': 'N',
  };

  /// Normaliza [text] para ordenamiento: elimina acentos,
  /// diéresis, y símbolos no alfabéticos al inicio.
  ///
  /// Ejemplos:
  ///   "Ámazing" → "Amazing"
  ///   "(Salmo 23)" → "Salmo 23"
  ///   "¡Aleluya!" → "Aleluya"
  ///   "¿Qué?" → "Que"
  static String normalizeForSort(String text) {
    if (text.isEmpty) return text;

    // 1. Eliminar símbolos no alfabéticos del inicio
    var cleaned = text.replaceFirst(RegExp(r'^[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+'), '');

    // 2. Reemplazar acentos y diéresis
    cleaned = cleaned.split('').map((c) => _accents[c] ?? c).join();

    return cleaned;
  }

  /// Compara dos strings para ordenamiento, ignorando acentos y símbolos.
  /// Retorna negativo si a < b, positivo si a > b, 0 si son iguales.
  static int compareForSort(String a, String b) {
    return normalizeForSort(a).compareTo(normalizeForSort(b));
  }

  /// Normaliza texto para búsqueda: minúsculas, sin acentos, sin puntuación.
  ///
  /// "Éxodo" → "exodo"
  /// "¡Aleluya!" → "aleluya"
  /// "Santa Biblia (Salmo 23)" → "santa biblia salmo 23"
  /// "[G]Dios es [C]amor" → "dios es amor"
  static String normalizeForSearch(String text) {
    var result = stripChords(text);  // Eliminar acordes ChordPro primero
    result = result.toLowerCase().trim();
    // Quitar acentos
    result = result.split('').map((c) => _accents[c] ?? c).join();
    // Quitar caracteres no alfanuméricos (excepto espacios)
    result = result.replaceAll(RegExp(r'[^\w\s]'), '');
    // Colapsar espacios múltiples
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
