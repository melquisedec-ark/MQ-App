# 🐛 Reporte de Bug UI: Texto Plano No Centrado y Responsive Roto

## 📌 Diagnóstico
Las pruebas revelaron que la lectura de la letra sin acordes se ha degradado tras la implementación del `ResponsiveChordWidget`. 
El widget `Wrap` (diseñado para mantener unidos los acordes y las sílabas) está forzando una alineación a la izquierda y rompiendo el flujo natural de lectura (text wrapping) de los párrafos cuando no hay acordes presentes.

## 🛠️ Instrucciones de Refactorización (Bifurcación de Renderizado)

No intentes forzar al `ResponsiveChordWidget` a comportarse como un párrafo de texto plano. La solución es **separar los motores de renderizado** según el estado de la aplicación.

Abre el archivo de la pantalla que muestra las estrofas (probablemente `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` o el componente encargado de renderizar la estrofa individual).

Debes implementar una bifurcación lógica (`if/else`) basada en la preferencia del usuario (`appearance.showChords`):

**1. Modo Acordes (Músico):**
Si `showChords` es `true`, sigue utilizando el `ResponsiveChordWidget` que ya está perfeccionado.

**2. Modo Texto Plano (Cantante):**
Si `showChords` es `false`, **NO utilices** `ResponsiveChordWidget`. Utiliza el widget `Text` nativo de Flutter junto con la función `stripChords()` para limpiar la letra. El widget nativo `Text` manejará automáticamente el responsive, los saltos de línea elegantes y el centrado perfecto.

**Ejemplo de implementación requerida:**

```dart
// Dentro de tu método build o _buildLyric() en la pantalla de detalles:

// Si el usuario quiere ver los acordes:
if (appearance.showChords) {
  return ResponsiveChordWidget(
    stanza: stanzaText,
    chordStyle: chordStyle,
    lyricStyle: lyricStyle,
    textAlign: TextAlign.center, // O TextAlign.justify según tu diseño
  );
} 
// Si el usuario SOLO quiere ver la letra:
else {
  return Container(
    width: double.infinity, // Asegura que el contenedor tome todo el ancho para centrar bien
    child: Text(
      // Usar tu función existente para quitar los corchetes [C] del texto
      stripChords(stanzaText), 
      style: lyricStyle,
      textAlign: TextAlign.center, // 🔴 CRÍTICO: Esto centrará el texto perfectamente
      // 🔴 CRÍTICO: Esto permite saltos de línea suaves si la pantalla es pequeña
      softWrap: true, 
    ),
  );
}