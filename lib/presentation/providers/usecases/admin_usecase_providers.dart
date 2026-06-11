import 'package:flutter_riverpod/flutter_riverpod.dart';

export '../../../domain/usecases/admin/manage_categorias.dart'
    show
        GetAllCategoriasUseCase,
        CreateCategoriaUseCase,
        UpdateCategoriaUseCase,
        DeleteCategoriaUseCase;
export '../../../domain/usecases/admin/manage_fondos.dart'
    show
        GetAllFondosUseCase,
        CreateFondoUseCase,
        UpdateFondoUseCase,
        DeleteFondoUseCase;
export '../../../domain/usecases/admin/manage_paises.dart'
    show
        GetAllPaisesUseCase,
        CreatePaisUseCase,
        UpdatePaisUseCase,
        DeletePaisUseCase;
export '../../../domain/usecases/admin/manage_pistas.dart'
    show
        GetPistasByHimnoUseCase,
        CreatePistaUseCase,
        DeletePistaUseCase;
export '../../../domain/usecases/admin/manage_usuarios.dart'
    show
        GetAllUsuariosUseCase,
        CreateUsuarioUseCase,
        UpdateUsuarioUseCase,
        DeleteUsuarioUseCase;

import '../../../domain/usecases/admin/manage_categorias.dart';
import '../../../domain/usecases/admin/manage_fondos.dart';
import '../../../domain/usecases/admin/manage_paises.dart';
import '../../../domain/usecases/admin/manage_pistas.dart';
import '../../../domain/usecases/admin/manage_usuarios.dart';

import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../../data/repositories/categoria_repository_impl.dart';
import '../../../data/repositories/fondo_pantalla_repository_impl.dart';
import '../../../data/repositories/pais_repository_impl.dart';
import '../../../data/repositories/pista_audio_repository_impl.dart';

// ─────────────────────────────────────────────────────────────
// Providers de casos de uso — Admin (Categorías, Países, Pistas, Fondos, Usuarios)
// ─────────────────────────────────────────────────────────────
// Estos providers viven en presentation/ para desacoplar
// flutter_riverpod de la capa de dominio.

// ─── Categorías ───
final getAllCategoriasUseCaseProvider =
    Provider<GetAllCategoriasUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllCategoriasUseCase(CategoriaRepositoryImpl(dataSource));
});

final createCategoriaUseCaseProvider =
    Provider<CreateCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreateCategoriaUseCase(CategoriaRepositoryImpl(dataSource));
});

final updateCategoriaUseCaseProvider =
    Provider<UpdateCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdateCategoriaUseCase(CategoriaRepositoryImpl(dataSource));
});

final deleteCategoriaUseCaseProvider =
    Provider<DeleteCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeleteCategoriaUseCase(CategoriaRepositoryImpl(dataSource));
});

// ─── Países ───
final getAllPaisesUseCaseProvider = Provider<GetAllPaisesUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllPaisesUseCase(PaisRepositoryImpl(dataSource));
});

final createPaisUseCaseProvider = Provider<CreatePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreatePaisUseCase(PaisRepositoryImpl(dataSource));
});

final updatePaisUseCaseProvider = Provider<UpdatePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdatePaisUseCase(PaisRepositoryImpl(dataSource));
});

final deletePaisUseCaseProvider = Provider<DeletePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeletePaisUseCase(PaisRepositoryImpl(dataSource));
});

// ─── Pistas ───
final getPistasByHimnoUseCaseProvider =
    Provider<GetPistasByHimnoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetPistasByHimnoUseCase(PistaAudioRepositoryImpl(dataSource));
});

final createPistaUseCaseProvider = Provider<CreatePistaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreatePistaUseCase(PistaAudioRepositoryImpl(dataSource));
});

final deletePistaUseCaseProvider = Provider<DeletePistaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeletePistaUseCase(PistaAudioRepositoryImpl(dataSource));
});

// ─── Fondos ───
final getAllFondosUseCaseProvider = Provider<GetAllFondosUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllFondosUseCase(FondoPantallaRepositoryImpl(dataSource));
});

final createFondoUseCaseProvider = Provider<CreateFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreateFondoUseCase(FondoPantallaRepositoryImpl(dataSource));
});

final updateFondoUseCaseProvider = Provider<UpdateFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdateFondoUseCase(FondoPantallaRepositoryImpl(dataSource));
});

final deleteFondoUseCaseProvider = Provider<DeleteFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeleteFondoUseCase(FondoPantallaRepositoryImpl(dataSource));
});

// ─── Usuarios ───
final getAllUsuariosUseCaseProvider = Provider<GetAllUsuariosUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return GetAllUsuariosUseCase(repository);
});

final createUsuarioUseCaseProvider = Provider<CreateUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return CreateUsuarioUseCase(repository);
});

final updateUsuarioUseCaseProvider = Provider<UpdateUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return UpdateUsuarioUseCase(repository);
});

final deleteUsuarioUseCaseProvider = Provider<DeleteUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return DeleteUsuarioUseCase(repository);
});
