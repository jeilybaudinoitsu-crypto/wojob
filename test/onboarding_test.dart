import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wojob/domain/repositories/repositories.dart';
import 'package:wojob/presentation/widgets/first_run_gate.dart';
import 'package:wojob/presentation/widgets/terms_acceptance_gate.dart';

void main() {
  testWidgets('muestra las páginas y completa el onboarding una sola vez', (
    tester,
  ) async {
    final repository = _MemoryFirstRunRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Control de asistencia'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación GPS'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de horarios'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¡Bienvenido a WoJob!'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(repository.firstRun, isFalse);
    expect(find.text('Contenido principal'), findsOneWidget);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    expect(find.text('Contenido principal'), findsOneWidget);
    expect(find.text('Control de asistencia'), findsNothing);
  });

  testWidgets('explica las funciones antes de mostrar los términos legales', (
    tester,
  ) async {
    final firstRunRepository = _MemoryFirstRunRepository();
    final termsRepository = _MemoryTermsRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: FirstRunGate(
          repository: firstRunRepository,
          child: TermsAcceptanceGate(
            repository: termsRepository,
            child: const Scaffold(
              body: Center(child: Text('Contenido principal')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ASÍ FUNCIONA WOJOB'), findsOneWidget);
    expect(find.text('Control de asistencia'), findsOneWidget);
    expect(find.text('Términos y privacidad'), findsNothing);

    for (var page = 0; page < 3; page++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Términos y privacidad'), findsOneWidget);
    expect(find.text('Contenido principal'), findsNothing);
  });
}

Widget _app(FirstRunRepository repository) {
  return MaterialApp(
    home: FirstRunGate(
      repository: repository,
      child: const Scaffold(body: Center(child: Text('Contenido principal'))),
    ),
  );
}

class _MemoryFirstRunRepository implements FirstRunRepository {
  bool firstRun = true;

  @override
  Future<bool> isFirstRun() async => firstRun;

  @override
  Future<void> completeFirstRun() async {
    firstRun = false;
  }
}

class _MemoryTermsRepository implements TermsAcceptanceRepository {
  bool accepted = false;

  @override
  Future<bool> hasAcceptedTerms() async => accepted;

  @override
  Future<void> acceptTerms() async {
    accepted = true;
  }
}
