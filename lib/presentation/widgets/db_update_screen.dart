import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../bootstrap/app_initializer.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla informativa de actualización de base de datos.
///
/// Se muestra SOLO cuando se detecta que la BD pre-cargada en assets es
/// más reciente que la versión aplicada localmente (ver [DbVersionManager]).
///
/// ## Comportamiento
/// 1. Pantalla completa centrada con logo, texto y [CircularProgressIndicator]
/// 2. **Sin botones de acción** — es puramente informativa (no blocker)
/// 3. Al iniciar, ejecuta la inicialización completa de la app incluyendo
///    la copia de la BD desde assets (delegada a [AppInitializer])
/// 4. Al terminar, transiciona automáticamente a [HimnarioApp] (app principal)
/// 5. Si ocurre un error, igualmente transiciona para no dejar al usuario
///    atrapado — la app puede funcionar con la BD anterior o crear una nueva
///
/// ## Diseño
/// - Logo circular con ícono de nota musical (consistente con [StandbyScreen])
/// - Título "MQ App" con tipografía displayLarge, weight w300, letterSpacing 4
/// - Animación de fade-in en el [CircularProgressIndicator]
/// - Colores y tipografía del tema de la app
/// - Responsive: centrado con SingleChildScrollView para móvil y desktop
///
/// NOTA: NO crea su propio MaterialApp. Se renderiza dentro del MaterialApp
/// compartido de main.dart para evitar navegadores anidados.
class DbUpdateScreen extends StatefulWidget {
  /// Contenedor de Riverpod para pasar a la app principal tras la transición.
  final ProviderContainer container;

  const DbUpdateScreen({required this.container, super.key});

  @override
  State<DbUpdateScreen> createState() => _DbUpdateScreenState();
}

class _DbUpdateScreenState extends State<DbUpdateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  String _statusMessage = 'Preparando...';
  bool _isComplete = false;
  bool _hasError = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // ── Animación de fade-in para el progress indicator ──
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // ── Iniciar la actualización en el siguiente frame ──
    // Esto permite que el widget se monte y la animación comience
    // antes de que el trabajo pesado (copia de BD) bloquee el hilo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performInitialization();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Ejecuta la inicialización completa de la aplicación.
  ///
  /// [AppInitializer.initialize] se encarga internamente de:
  /// 1. Inicializar la BD (copiar desde assets si es necesario, migraciones)
  /// 2. Configurar logging y plataforma
  /// 3. Iniciar servicios de red (mDNS, gRPC) según plataforma
  Future<void> _performInitialization() async {
    try {
      setState(() {
        _statusMessage = 'Copiando base de datos...';
      });

      // Inicializar todos los servicios.
      // DatabaseHelper._initDatabase() compara versiones internamente
      // y copia la BD desde assets si el asset es más reciente.
      await AppInitializer.initialize(container: widget.container);

      setState(() {
        _statusMessage = '¡Listo!';
        _hasError = false;
      });
    } catch (e) {
      // Error durante la inicialización — registrar pero no bloquear
      debugPrint('DbUpdateScreen: Error durante inicialización: $e');
      setState(() {
        _statusMessage = 'Continuando...';
        _hasError = true;
      });
    } finally {
      setState(() => _isComplete = true);
      // La transición se dispara desde el build() vía _buildTransitionTrigger
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo de la app ──
                _buildLogo(),
                const SizedBox(height: 40),

                // ── Título "MQ App" ──
                Text(
                  'MQ App',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                ),
                const SizedBox(height: 32),

                // ── Indicador de progreso animado ──
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProgressSection(),
                ),

                // ── Transición silenciosa al completar ──
                if (_isComplete) _buildTransitionTrigger(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sección de progreso: spinner, título, subtítulo y estado.
  Widget _buildProgressSection() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Progress indicator o icono de completado según estado
        if (_hasError)
          Icon(
            Icons.cloud_done_rounded,
            size: 48,
            color: colors.tertiary,
          )
        else
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),

        const SizedBox(height: 24),

        // "Actualizando base de datos..."
        Text(
          _hasError
              ? 'Preparando la aplicación...'
              : 'Actualizando base de datos...',
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        // Estado detallado (ej: "Copiando base de datos...")
        Text(
          _statusMessage,
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(height: 16),

        // Subtítulo opcional
        if (!_hasError)
          Text(
            'Este proceso puede tomar unos segundos',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  /// Dispara la transición a la app principal cuando el proceso termina.
  ///
  /// Usa runApp() directamente (patrón estándar para splash screens)
  /// en lugar de Navigator, porque esta pantalla no tiene un MaterialApp
  /// propio — comparte el de main.dart.
  Widget _buildTransitionTrigger() {
    if (!_isTransitioning) {
      _isTransitioning = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          runApp(
            UncontrolledProviderScope(
              container: widget.container,
              child: MaterialApp(
                title: 'MQ App',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,
                home: const HimnarioApp(),
              ),
            ),
          );
        }
      });
    }
    return const SizedBox.shrink();
  }

  /// Logo circular con ícono de nota musical.
  ///
  /// Consistente con el diseño de [StandbyScreen] (misma forma, tamaño
  /// y estilo de borde).
  Widget _buildLogo() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 64,
        color: colors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
