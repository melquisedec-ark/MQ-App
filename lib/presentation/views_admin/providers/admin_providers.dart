// ─────────────────────────────────────────────────────────────
// Proveedores de casos de uso — Módulo Admin
// ─────────────────────────────────────────────────────────────
// Barrel file que re-exporta los providers de todos los casos
// de uso del módulo de administración para facilitar su consumo
// desde la capa de presentación.

export '../../../../domain/usecases/admin/manage_categorias.dart'
    show
        GetAllCategoriasUseCase,
        getAllCategoriasUseCaseProvider,
        CreateCategoriaUseCase,
        createCategoriaUseCaseProvider,
        UpdateCategoriaUseCase,
        updateCategoriaUseCaseProvider,
        DeleteCategoriaUseCase,
        deleteCategoriaUseCaseProvider;

export '../../../../domain/usecases/admin/manage_paises.dart'
    show
        GetAllPaisesUseCase,
        getAllPaisesUseCaseProvider,
        CreatePaisUseCase,
        createPaisUseCaseProvider,
        UpdatePaisUseCase,
        updatePaisUseCaseProvider,
        DeletePaisUseCase,
        deletePaisUseCaseProvider;

export '../../../../domain/usecases/admin/manage_pistas.dart'
    show
        GetPistasByHimnoUseCase,
        getPistasByHimnoUseCaseProvider,
        CreatePistaUseCase,
        createPistaUseCaseProvider,
        DeletePistaUseCase,
        deletePistaUseCaseProvider;

export '../../../../domain/usecases/admin/manage_fondos.dart'
    show
        GetAllFondosUseCase,
        getAllFondosUseCaseProvider,
        CreateFondoUseCase,
        createFondoUseCaseProvider,
        UpdateFondoUseCase,
        updateFondoUseCaseProvider,
        DeleteFondoUseCase,
        deleteFondoUseCaseProvider;

export '../../../../domain/usecases/admin/manage_usuarios.dart'
    show
        GetAllUsuariosUseCase,
        getAllUsuariosUseCaseProvider,
        CreateUsuarioUseCase,
        createUsuarioUseCaseProvider,
        UpdateUsuarioUseCase,
        updateUsuarioUseCaseProvider,
        DeleteUsuarioUseCase,
        deleteUsuarioUseCaseProvider;
