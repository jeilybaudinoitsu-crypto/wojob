import 'package:flutter_test/flutter_test.dart';

import 'package:wojob/main.dart';
import 'package:wojob/core/di/service_locator.dart';
import 'package:wojob/domain/repositories/repositories.dart';

void main() {
  setUpAll(() async {
    await setupDependencies(isTest: true);
  });

  tearDownAll(() {
    resetDependencies();
  });

  testWidgets('La pantalla de bienvenida muestra las acciones de acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WoJobApp(
        termsAcceptanceRepository: _AcceptedTermsRepository(),
        onboardingRepository: _CompletedFirstRunRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WoJob'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Navega al registro y valida el formulario', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WoJobApp(
        termsAcceptanceRepository: _AcceptedTermsRepository(),
        onboardingRepository: _CompletedFirstRunRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(find.text('Datos personales'), findsOneWidget);

    await tester.ensureVisible(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    expect(find.text('Campo obligatorio'), findsWidgets);
  });
}

class _AcceptedTermsRepository implements TermsAcceptanceRepository {
  @override
  Future<bool> hasAcceptedTerms() async => true;

  @override
  Future<void> acceptTerms() async {}
}

class _CompletedFirstRunRepository implements FirstRunRepository {
  @override
  Future<bool> isFirstRun() async => false;

  @override
  Future<void> completeFirstRun() async {}
}
