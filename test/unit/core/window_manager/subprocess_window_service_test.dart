import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOSink, Process, ProcessException, ProcessStartMode;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/window_manager/window_service.dart';
import 'package:himnario_id_2/core/window_manager/window_state.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockProcess extends Mock implements Process {}

class MockIOSink extends Mock implements IOSink {}

/// Crea un [ProcessStarter] que siempre retorna [mockProcess].
ProcessStarter _mockStarter(MockProcess mockProcess) {
  return (
    String _, List<String> __, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool? includeParentEnvironment,
    bool? runInShell,
    ProcessStartMode? mode,
  }) async {
    return mockProcess;
  };
}

// ═══════════════════════════════════════════════════════════════
// Test suite
// ═══════════════════════════════════════════════════════════════

void main() {
  late MockProcess mockProcess;
  late MockIOSink mockStdin;
  late StreamController<List<int>> stdoutController;
  late StreamController<List<int>> stderrController;
  late Completer<int> exitCodeCompleter;

  setUp(() {
    mockProcess = MockProcess();
    mockStdin = MockIOSink();
    stdoutController = StreamController<List<int>>.broadcast();
    stderrController = StreamController<List<int>>.broadcast();
    exitCodeCompleter = Completer<int>();

    // Configuración por defecto del proceso mock
    when(() => mockProcess.stdin).thenReturn(mockStdin);
    when(() => mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
    when(() => mockProcess.stderr).thenAnswer((_) => stderrController.stream);
    when(
      () => mockProcess.exitCode,
    ).thenAnswer((_) => exitCodeCompleter.future);
    when(() => mockProcess.kill()).thenReturn(true);
    when(() => mockProcess.pid).thenReturn(12345);
  });

  tearDown(() async {
    await stdoutController.close();
    await stderrController.close();
  });

  group('SubprocessWindowService', () {
    test(
      '1. openProjectionWindow() success → emite opened event',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await service.openProjectionWindow({'hymnId': 1});
        // Ceder al event loop para que el stream delivery ocurra
        await Future.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events[0].type, WindowEventType.opened);
        expect(events[0].data, {'hymnId': 1});
      },
    );

    test(
      '2. openProjectionWindow() cuando ya hay ventana → segunda llamada NO-OP',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await service.openProjectionWindow({'hymnId': 1});
        await Future.delayed(Duration.zero);

        // Segunda llamada — no debe lanzar ni emitir otro evento
        await service.openProjectionWindow({'hymnId': 2});
        await Future.delayed(Duration.zero);

        // Solo debe haber 1 evento opened
        expect(
          events.where((e) => e.type == WindowEventType.opened),
          hasLength(1),
        );
      },
    );

    test(
      '3. openProjectionWindow() cuando falla Process.start → relanza excepción',
      () async {
        final ProcessStarter failingStarter = (
          String _, List<String> __, {
          String? workingDirectory,
          Map<String, String>? environment,
          bool? includeParentEnvironment,
          bool? runInShell,
          ProcessStartMode? mode,
        }) async {
          throw ProcessException('Mock error', []);
        };

        final service = SubprocessWindowService(processStarter: failingStarter);
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await expectLater(
          () => service.openProjectionWindow({}),
          throwsA(isA<ProcessException>()),
        );

        // No debe emitir eventos
        expect(events, isEmpty);
      },
    );

    test(
      '4. sendMessage() con ventana abierta → escribe JSON + \\n en stdin',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        await service.openProjectionWindow({});
        await Future.delayed(Duration.zero);

        String? capturedInput;
        when(() => mockStdin.write(captureAny())).thenAnswer((invocation) {
          capturedInput = invocation.positionalArguments[0] as String?;
        });

        await service.sendMessage({'type': 'NEXT_STANZA'});

        expect(capturedInput, '{"type":"NEXT_STANZA"}\n');
        verify(() => mockStdin.write(any())).called(1);
      },
    );

    test(
      '5. sendMessage() sin ventana abierta → NO-OP sin errores',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));

        // No se llamó a openProjectionWindow — no hay proceso
        await service.sendMessage({'type': 'NEXT_STANZA'});

        verifyNever(() => mockStdin.write(any()));
      },
    );

    test(
      '6. closeProjectionWindow() con ventana abierta → llama kill() + emite closed',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await service.openProjectionWindow({});
        await Future.delayed(Duration.zero);
        events.clear(); // limpiar evento opened

        await service.closeProjectionWindow();
        await Future.delayed(Duration.zero);

        verify(() => mockProcess.kill()).called(1);
        // Puede haber 1 o 2 eventos closed (el exitCode.then también emite)
        expect(events.last.type, WindowEventType.closed);
      },
    );

    test(
      '7. closeProjectionWindow() sin ventana abierta → NO-OP',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await service.closeProjectionWindow();
        await Future.delayed(Duration.zero);

        verifyNever(() => mockProcess.kill());
        // closed event se emite igual (comportamiento actual)
        expect(events, hasLength(1));
        expect(events[0].type, WindowEventType.closed);
      },
    );

    test(
      '8. onWindowEvent stream → emite opened y closed en secuencia',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final eventTypes = <WindowEventType>[];
        service.onWindowEvent.listen((e) => eventTypes.add(e.type));

        await service.openProjectionWindow({});
        await service.closeProjectionWindow();
        await Future.delayed(Duration.zero);

        expect(eventTypes.first, WindowEventType.opened);
        expect(eventTypes.last, WindowEventType.closed);
      },
    );

    test(
      '9. stdout del hijo → onChildMessage recibe JSON parseado',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final childMessages = <Map<String, dynamic>>[];
        service.onChildMessage.listen(childMessages.add);

        await service.openProjectionWindow({});
        await Future.delayed(Duration.zero);

        // Simular respuesta del hijo por stdout
        stdoutController.add(utf8.encode('{"status":"ok"}\n'));
        await Future.delayed(Duration.zero);

        expect(childMessages, hasLength(1));
        expect(childMessages[0], {'status': 'ok'});
      },
    );

    test(
      '10. Salida del hijo → emite closed event (exitCode callback)',
      () async {
        final service =
            SubprocessWindowService(processStarter: _mockStarter(mockProcess));
        final events = <WindowEvent>[];
        service.onWindowEvent.listen(events.add);

        await service.openProjectionWindow({});
        await Future.delayed(Duration.zero);
        events.clear(); // limpiar opened

        // Simular que el hijo termina
        exitCodeCompleter.complete(0);
        await Future.delayed(Duration.zero);

        // Al menos debe haber un closed event
        expect(events.any((e) => e.type == WindowEventType.closed), isTrue);
      },
    );
  });
}
