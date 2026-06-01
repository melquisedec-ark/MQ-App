import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/presentation/dual_mode_wrapper/device_mode.dart';
import 'package:himnario_id_2/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/display/receptor_binding.dart';
import 'package:himnario_id_2/presentation/views_projection/display/standby_screen.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/live_control_providers.dart';

// ─── Provider Overrides ───────────────────────────────────────

/// Override para receptorInfoProvider con valores mock.
final _receptorInfoOverride = receptorInfoProvider.overrideWith(
  (ref) => const ReceptorInfo(
    isRunning: true,
    port: 50051,
    displayName: 'Display Principal',
  ),
);

/// Override para liveControlProvider (sin himno activo = standby).
final _liveControlEmptyOverride = liveControlProvider.overrideWith(
  (ref) => LiveControlNotifier(),
);

/// Override para deviceModeProvider en modo desktop.
final _desktopModeOverride = deviceModeProvider.overrideWith(
  (ref) => _DesktopModeNotifier(),
);

class _DesktopModeNotifier extends DualModeNotifier {
  _DesktopModeNotifier() : super() {
    // Inicializar en modo desktop
    setMode(DeviceMode.desktop);
  }
}

Widget _buildTestApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      _receptorInfoOverride,
      _liveControlEmptyOverride,
      _desktopModeOverride,
      ...overrides,
    ],
    child: const MaterialApp(
      home: StandbyScreen(),
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────────

void main() {
  group('StandbyScreen', () {
    testWidgets('Renderiza el texto de espera principal', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      // Usar pump() porque el PulseIndicator tiene animación infinita
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Título principal
      expect(find.text('HimnarioID'), findsOneWidget);

      // Mensaje de espera
      expect(
        find.text('Esperando conexión del controlador...'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra información de red/puerto', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Nombre del display
      expect(find.text('Display Principal'), findsOneWidget);

      // Puerto - "Puerto: 50051"
      expect(find.textContaining('50051'), findsWidgets);

      // Debe mostrar el ícono de wifi
      expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

      // Debe mostrar el ícono de cast
      expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
    });

    testWidgets(
      'Muestra "Conéctate desde tu móvil"',
      (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.text('Conéctate desde tu móvil'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Muestra el botón "Salir del modo Receptor"', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Salir del modo Receptor'),
        findsOneWidget,
      );
    });

    testWidgets('Muestra el indicador de pulso animado', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // El texto "Esperando controlador..." aparece dentro del PulseIndicator
      expect(find.text('Esperando controlador...'), findsOneWidget);

      // El icono cast_connected está presente
      expect(find.byIcon(Icons.cast_connected), findsOneWidget);
    });

    testWidgets('Fondo de pantalla es negro', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que el Scaffold tiene backgroundColor Colors.black
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets(
      'Muestra "Proyección activa" cuando hay un himno cargado',
      (tester) async {
        // Crear un notifier con un himno cargado usando el constructor de Himno
        final notifier = LiveControlNotifier();
        const himno = Himno(
          id: 1,
          titulo: 'Santo, Santo, Santo',
          numero: 1,
          tipo: HimnoTipo.oficial,
        );
        notifier.loadHymn(himno, []);

        final override = liveControlProvider.overrideWith(
          (ref) => notifier,
        );

        await tester.pumpWidget(
          _buildTestApp(overrides: [override]),
        );
        // No hay PulseIndicator, pumpAndSettle es seguro aquí
        await tester.pumpAndSettle();

        // Debe mostrar "Proyección activa" en vez del mensaje de espera
        expect(find.text('Proyección activa'), findsOneWidget);
        expect(
          find.text('Esperando conexión del controlador...'),
          findsNothing,
        );
      },
    );

    testWidgets('El logo de nota musical se renderiza', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Icono de nota musical (logo principal)
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });
  });
}
