import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../views_admin/providers/admin_providers.dart'
    show getAllFondosUseCaseProvider;

/// Provider que retorna TODOS los fondos activos (cualquier tipo).
final fondosActivosProvider = FutureProvider<List<FondoPantalla>>((ref) async {
  final useCase = ref.read(getAllFondosUseCaseProvider);
  final all = await useCase.execute();
  return all.where((f) => f.activo).toList();
});
