import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/ui/app_snackbar.dart';

void main() {
  group('showAppSnackBar (D5)', () {
    testWidgets('muestra snackbar con mensaje', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'Hola mundo');
      await tester.pump();

      expect(find.text('Hola mundo'), findsOneWidget);
    });

    testWidgets('usa duración 3s por defecto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'msg');
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(seconds: 3));
    });

    testWidgets('auto-dismiss después de 3 segundos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'auto-dismiss test');
      await tester.pump();
      expect(find.text('auto-dismiss test'), findsOneWidget);

      // Avanzar 3 segundos en pasos pequeños (tester.pump procesa 1 frame).
      // El timer de SnackBar se completa tras duration; necesitamos
      // bombardear varios frames hasta que el timer dispare.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // El snackbar debe haberse ocultado.
      expect(find.text('auto-dismiss test'), findsNothing);
    });

    testWidgets('reemplaza snackbar pendiente (no stacking)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'primero');
      await tester.pump();
      expect(find.text('primero'), findsOneWidget);

      // Llamar de nuevo antes de que termine la primera.
      showAppSnackBar(context, 'segundo');
      await tester.pump();

      // Solo el segundo debe estar visible.
      expect(find.text('primero'), findsNothing);
      expect(find.text('segundo'), findsOneWidget);
    });

    testWidgets('respeta action cuando se provee', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(
        context,
        'Con acción',
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {},
        ),
      );
      await tester.pump();

      expect(find.text('Deshacer'), findsOneWidget);
    });

    testWidgets('usa SnackBarBehavior.fixed (M3 default)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'msg');
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.fixed);
    });

    testWidgets('success type usa color verde', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'Éxito', type: AppSnackBarType.success);
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFF2E7D32));
    });

    testWidgets('error type usa errorContainer del tema', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      final context = tester.element(find.byType(Scaffold));
      showAppSnackBar(context, 'Error', type: AppSnackBarType.error);
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final expected = Theme.of(context).colorScheme.errorContainer;
      expect(snackBar.backgroundColor, expected);
    });
  });
}
