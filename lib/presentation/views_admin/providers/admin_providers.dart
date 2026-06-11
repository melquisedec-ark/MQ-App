// ─────────────────────────────────────────────────────────────
// Proveedores de casos de uso — Módulo Admin
// ─────────────────────────────────────────────────────────────
// Barrel file que re-exporta los providers de todos los casos
// de uso del módulo de administración desde presentation/.

export '../../providers/usecases/admin_usecase_providers.dart'
    show
        // Categorías
        GetAllCategoriasUseCase,
        getAllCategoriasUseCaseProvider,
        CreateCategoriaUseCase,
        createCategoriaUseCaseProvider,
        UpdateCategoriaUseCase,
        updateCategoriaUseCaseProvider,
        DeleteCategoriaUseCase,
        deleteCategoriaUseCaseProvider,
        // Países
        GetAllPaisesUseCase,
        getAllPaisesUseCaseProvider,
        CreatePaisUseCase,
        createPaisUseCaseProvider,
        UpdatePaisUseCase,
        updatePaisUseCaseProvider,
        DeletePaisUseCase,
        deletePaisUseCaseProvider,
        // Pistas
        GetPistasByHimnoUseCase,
        getPistasByHimnoUseCaseProvider,
        CreatePistaUseCase,
        createPistaUseCaseProvider,
        DeletePistaUseCase,
        deletePistaUseCaseProvider,
        // Fondos
        GetAllFondosUseCase,
        getAllFondosUseCaseProvider,
        CreateFondoUseCase,
        createFondoUseCaseProvider,
        UpdateFondoUseCase,
        updateFondoUseCaseProvider,
        DeleteFondoUseCase,
        deleteFondoUseCaseProvider,
        // Usuarios
        GetAllUsuariosUseCase,
        getAllUsuariosUseCaseProvider,
        CreateUsuarioUseCase,
        createUsuarioUseCaseProvider,
        UpdateUsuarioUseCase,
        updateUsuarioUseCaseProvider,
        DeleteUsuarioUseCase,
        deleteUsuarioUseCaseProvider;
