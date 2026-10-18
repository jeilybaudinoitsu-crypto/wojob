import 'package:flutter_test/flutter_test.dart';

import 'package:wojob/main.dart';

void main() {
  testWidgets('La pantalla de bienvenida muestra las acciones de acceso',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WoJobApp());
    await tester.pumpAndSettle();

    expect(find.text('WoJob'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Navega al registro y valida el formulario',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WoJobApp());
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
