// =============================================================================
// lib/books_canon.dart
// =============================================================================
// Metadatos canónicos de los 66 libros de la Biblia (orden y total_capitulos).
// Usado por build_biblia_db.dart para insertar filas de `libro` y `capitulo`
// sin depender de los datos fuente (que sólo traen los textos).
//
// Orden canónico:
//   AT (1-39):  Génesis → Malaquías
//   NT (40-66): Mateo → Apocalipsis
// =============================================================================

class BookCanonEntry {
  final int numero;        // 1-66
  final String nombre;     // "Génesis", "1 Juan", etc.
  final String abreviatura; // "Gn", "1Jn", etc.
  final String testamento; // "AT" | "NT"
  final int totalCapitulos;

  const BookCanonEntry({
    required this.numero,
    required this.nombre,
    required this.abreviatura,
    required this.testamento,
    required this.totalCapitulos,
  });
}

const List<BookCanonEntry> kBookCanon = [
  // Antiguo Testamento (1-39)
  BookCanonEntry(numero:  1, nombre: 'Génesis',       abreviatura: 'Gn',  testamento: 'AT', totalCapitulos: 50),
  BookCanonEntry(numero:  2, nombre: 'Éxodo',         abreviatura: 'Ex',  testamento: 'AT', totalCapitulos: 40),
  BookCanonEntry(numero:  3, nombre: 'Levítico',      abreviatura: 'Lv',  testamento: 'AT', totalCapitulos: 27),
  BookCanonEntry(numero:  4, nombre: 'Números',       abreviatura: 'Nm',  testamento: 'AT', totalCapitulos: 36),
  BookCanonEntry(numero:  5, nombre: 'Deuteronomio',  abreviatura: 'Dt',  testamento: 'AT', totalCapitulos: 34),
  BookCanonEntry(numero:  6, nombre: 'Josué',         abreviatura: 'Jos', testamento: 'AT', totalCapitulos: 24),
  BookCanonEntry(numero:  7, nombre: 'Jueces',        abreviatura: 'Jue', testamento: 'AT', totalCapitulos: 21),
  BookCanonEntry(numero:  8, nombre: 'Rut',           abreviatura: 'Ru',  testamento: 'AT', totalCapitulos:  4),
  BookCanonEntry(numero:  9, nombre: '1 Samuel',      abreviatura: '1Sa', testamento: 'AT', totalCapitulos: 31),
  BookCanonEntry(numero: 10, nombre: '2 Samuel',      abreviatura: '2Sa', testamento: 'AT', totalCapitulos: 24),
  BookCanonEntry(numero: 11, nombre: '1 Reyes',       abreviatura: '1Re', testamento: 'AT', totalCapitulos: 22),
  BookCanonEntry(numero: 12, nombre: '2 Reyes',       abreviatura: '2Re', testamento: 'AT', totalCapitulos: 25),
  BookCanonEntry(numero: 13, nombre: '1 Crónicas',    abreviatura: '1Cr', testamento: 'AT', totalCapitulos: 29),
  BookCanonEntry(numero: 14, nombre: '2 Crónicas',    abreviatura: '2Cr', testamento: 'AT', totalCapitulos: 36),
  BookCanonEntry(numero: 15, nombre: 'Esdras',        abreviatura: 'Esd', testamento: 'AT', totalCapitulos: 10),
  BookCanonEntry(numero: 16, nombre: 'Nehemías',      abreviatura: 'Neh', testamento: 'AT', totalCapitulos: 13),
  BookCanonEntry(numero: 17, nombre: 'Ester',         abreviatura: 'Est', testamento: 'AT', totalCapitulos: 10),
  BookCanonEntry(numero: 18, nombre: 'Job',           abreviatura: 'Job', testamento: 'AT', totalCapitulos: 42),
  BookCanonEntry(numero: 19, nombre: 'Salmos',        abreviatura: 'Sal', testamento: 'AT', totalCapitulos: 150),
  BookCanonEntry(numero: 20, nombre: 'Proverbios',    abreviatura: 'Pr',  testamento: 'AT', totalCapitulos: 31),
  BookCanonEntry(numero: 21, nombre: 'Eclesiastés',   abreviatura: 'Ec',  testamento: 'AT', totalCapitulos: 12),
  BookCanonEntry(numero: 22, nombre: 'Cantares',      abreviatura: 'Cnt', testamento: 'AT', totalCapitulos:  8),
  BookCanonEntry(numero: 23, nombre: 'Isaías',        abreviatura: 'Is',  testamento: 'AT', totalCapitulos: 66),
  BookCanonEntry(numero: 24, nombre: 'Jeremías',      abreviatura: 'Jer', testamento: 'AT', totalCapitulos: 52),
  BookCanonEntry(numero: 25, nombre: 'Lamentaciones', abreviatura: 'Lam', testamento: 'AT', totalCapitulos:  5),
  BookCanonEntry(numero: 26, nombre: 'Ezequiel',      abreviatura: 'Eze', testamento: 'AT', totalCapitulos: 48),
  BookCanonEntry(numero: 27, nombre: 'Daniel',        abreviatura: 'Dan', testamento: 'AT', totalCapitulos: 12),
  BookCanonEntry(numero: 28, nombre: 'Oseas',         abreviatura: 'Os',  testamento: 'AT', totalCapitulos: 14),
  BookCanonEntry(numero: 29, nombre: 'Joel',          abreviatura: 'Jl',  testamento: 'AT', totalCapitulos:  3),
  BookCanonEntry(numero: 30, nombre: 'Amós',          abreviatura: 'Am',  testamento: 'AT', totalCapitulos:  9),
  BookCanonEntry(numero: 31, nombre: 'Abdías',        abreviatura: 'Ab',  testamento: 'AT', totalCapitulos:  1),
  BookCanonEntry(numero: 32, nombre: 'Jonás',         abreviatura: 'Jon', testamento: 'AT', totalCapitulos:  4),
  BookCanonEntry(numero: 33, nombre: 'Miqueas',       abreviatura: 'Mi',  testamento: 'AT', totalCapitulos:  7),
  BookCanonEntry(numero: 34, nombre: 'Nahúm',         abreviatura: 'Na',  testamento: 'AT', totalCapitulos:  3),
  BookCanonEntry(numero: 35, nombre: 'Habacuc',       abreviatura: 'Hab', testamento: 'AT', totalCapitulos:  3),
  BookCanonEntry(numero: 36, nombre: 'Sofonías',      abreviatura: 'Sof', testamento: 'AT', totalCapitulos:  3),
  BookCanonEntry(numero: 37, nombre: 'Hageo',         abreviatura: 'Hag', testamento: 'AT', totalCapitulos:  2),
  BookCanonEntry(numero: 38, nombre: 'Zacarías',      abreviatura: 'Zac', testamento: 'AT', totalCapitulos: 14),
  BookCanonEntry(numero: 39, nombre: 'Malaquías',     abreviatura: 'Mal', testamento: 'AT', totalCapitulos:  4),

  // Nuevo Testamento (40-66)
  BookCanonEntry(numero: 40, nombre: 'Mateo',            abreviatura: 'Mt',  testamento: 'NT', totalCapitulos: 28),
  BookCanonEntry(numero: 41, nombre: 'Marcos',           abreviatura: 'Mc',  testamento: 'NT', totalCapitulos: 16),
  BookCanonEntry(numero: 42, nombre: 'Lucas',            abreviatura: 'Lc',  testamento: 'NT', totalCapitulos: 24),
  BookCanonEntry(numero: 43, nombre: 'Juan',             abreviatura: 'Jn',  testamento: 'NT', totalCapitulos: 21),
  BookCanonEntry(numero: 44, nombre: 'Hechos',           abreviatura: 'Hch', testamento: 'NT', totalCapitulos: 28),
  BookCanonEntry(numero: 45, nombre: 'Romanos',          abreviatura: 'Ro',  testamento: 'NT', totalCapitulos: 16),
  BookCanonEntry(numero: 46, nombre: '1 Corintios',      abreviatura: '1Co', testamento: 'NT', totalCapitulos: 16),
  BookCanonEntry(numero: 47, nombre: '2 Corintios',      abreviatura: '2Co', testamento: 'NT', totalCapitulos: 13),
  BookCanonEntry(numero: 48, nombre: 'Gálatas',          abreviatura: 'Ga',  testamento: 'NT', totalCapitulos:  6),
  BookCanonEntry(numero: 49, nombre: 'Efesios',          abreviatura: 'Ef',  testamento: 'NT', totalCapitulos:  6),
  BookCanonEntry(numero: 50, nombre: 'Filipenses',       abreviatura: 'Fil', testamento: 'NT', totalCapitulos:  4),
  BookCanonEntry(numero: 51, nombre: 'Colosenses',       abreviatura: 'Col', testamento: 'NT', totalCapitulos:  4),
  BookCanonEntry(numero: 52, nombre: '1 Tesalonicenses', abreviatura: '1Ts', testamento: 'NT', totalCapitulos:  5),
  BookCanonEntry(numero: 53, nombre: '2 Tesalonicenses', abreviatura: '2Ts', testamento: 'NT', totalCapitulos:  3),
  BookCanonEntry(numero: 54, nombre: '1 Timoteo',        abreviatura: '1Ti', testamento: 'NT', totalCapitulos:  6),
  BookCanonEntry(numero: 55, nombre: '2 Timoteo',        abreviatura: '2Ti', testamento: 'NT', totalCapitulos:  4),
  BookCanonEntry(numero: 56, nombre: 'Tito',             abreviatura: 'Tit', testamento: 'NT', totalCapitulos:  3),
  BookCanonEntry(numero: 57, nombre: 'Filemón',          abreviatura: 'Flm', testamento: 'NT', totalCapitulos:  1),
  BookCanonEntry(numero: 58, nombre: 'Hebreos',          abreviatura: 'He',  testamento: 'NT', totalCapitulos: 13),
  BookCanonEntry(numero: 59, nombre: 'Santiago',         abreviatura: 'Stg', testamento: 'NT', totalCapitulos:  5),
  BookCanonEntry(numero: 60, nombre: '1 Pedro',          abreviatura: '1Pe', testamento: 'NT', totalCapitulos:  5),
  BookCanonEntry(numero: 61, nombre: '2 Pedro',          abreviatura: '2Pe', testamento: 'NT', totalCapitulos:  3),
  BookCanonEntry(numero: 62, nombre: '1 Juan',           abreviatura: '1Jn', testamento: 'NT', totalCapitulos:  5),
  BookCanonEntry(numero: 63, nombre: '2 Juan',           abreviatura: '2Jn', testamento: 'NT', totalCapitulos:  1),
  BookCanonEntry(numero: 64, nombre: '3 Juan',           abreviatura: '3Jn', testamento: 'NT', totalCapitulos:  1),
  BookCanonEntry(numero: 65, nombre: 'Judas',            abreviatura: 'Jud', testamento: 'NT', totalCapitulos:  1),
  BookCanonEntry(numero: 66, nombre: 'Apocalipsis',      abreviatura: 'Ap',  testamento: 'NT', totalCapitulos: 22),
];
