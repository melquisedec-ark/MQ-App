class PaisModel {
  final int id;
  final String nombre;
  final String? codigo;

  PaisModel({required this.id, required this.nombre, this.codigo});

  factory PaisModel.fromMap(Map<String, dynamic> map) => PaisModel(
        id: map['id'] as int,
        nombre: map['nombre'] as String,
        codigo: map['codigo'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'codigo': codigo,
      };
}
