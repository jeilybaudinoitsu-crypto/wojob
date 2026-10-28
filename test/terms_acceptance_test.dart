import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wojob/domain/repositories/repositories.dart';
import 'package:wojob/presentation/widgets/terms_acceptance_gate.dart';

void main() {
  testWidgets('bloquea el acceso hasta aceptar y guarda la aceptación', (
    tester,
  ) async {
    final repository = _MemoryTermsAcceptanceRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Contenido principal'), findsNothing);
    expect(find.text('Términos y privacidad'), findsOneWidget);

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(repository.accepted, isTrue);
    expect(find.text('Contenido principal'), findsOneWidget);
    expect(find.text('Términos y privacidad'), findsNothing);
  });

  testWidgets('rechazar mantiene bloqueado el acceso', (tester) async {
    final repository = _MemoryTermsAcceptanceRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Para usar WoJob, debes aceptar estos términos.'),
      findsOneWidget,
    );
    expect(find.text('Contenido principal'), findsNothing);
    expect(repository.accepted, isFalse);
  });

  testWidgets('no muestra el diálogo si ya se aceptaron los términos', (
    tester,
  ) async {
    final repository = _MemoryTermsAcceptanceRepository()..accepted = true;
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Contenido principal'), findsOneWidget);
    expect(find.text('Términos y privacidad'), findsNothing);
  });
}

Widget _app(TermsAcceptanceRepository repository) {
  return MaterialApp(
    home: TermsAcceptanceGate(
      repository: repository,
      child: const Scaffold(body: Center(child: Text('Contenido principal'))),
    ),
  );
}

class _MemoryTermsAcceptanceRepository implements TermsAcceptanceRepository {
  bool accepted = false;

  @override
  Future<bool> hasAcceptedTerms() async => accepted;

  @override
  Future<void> acceptTerms() async {
    accepted = true;
  }
}
