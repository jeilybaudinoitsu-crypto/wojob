import 'package:flutter_test/flutter_test.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/presentation/state/empresa_state.dart';

void main() {
  group('PlanSuscripcion', () {
    test('define los precios y límites requeridos', () {
      expect(PlanSuscripcion.free.limiteEmpleados, 10);
      expect(PlanSuscripcion.businessGold.precioMensual, 25);
      expect(PlanSuscripcion.businessGold.limiteEmpleados, 250);
      expect(PlanSuscripcion.ceoDiamond.precioMensual, 60);
      expect(PlanSuscripcion.ceoDiamond.limiteEmpleados, isNull);
    });

    test('serializa y restaura el plan y su límite', () {
      final empresa = MockData.empresa.copyWith(
        planSuscripcion: PlanSuscripcion.businessGold,
      );
      final restored = Empresa.fromMap(empresa.toMap());

      expect(restored.planSuscripcion, PlanSuscripcion.businessGold);
      expect(restored.limiteEmpleados, 250);
    });
  });

  test('actualiza el plan y el límite en EmpresaState', () async {
    final state = EmpresaState();
    final updated = await state.updateSubscriptionPlan(
      empresaId: MockData.empresa.id,
      plan: PlanSuscripcion.ceoDiamond,
    );

    expect(updated.planSuscripcion, PlanSuscripcion.ceoDiamond);
    expect(updated.limiteEmpleados, isNull);
    expect(state.empresaById(MockData.empresa.id)?.limiteEmpleados, isNull);
  });
}
