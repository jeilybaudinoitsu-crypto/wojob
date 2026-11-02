import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:wojob/core/theme/app_theme.dart';
import 'package:wojob/data/datasources/mock_data.dart';
import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/data/models/tipo_usuario.dart';
import 'package:wojob/presentation/screens/admin/admin_home_screen.dart';
import 'package:wojob/presentation/screens/employee/employee_home_screen.dart';
import 'package:wojob/presentation/state/asistencia_state.dart';
import 'package:wojob/presentation/state/auth_state.dart' as app_state;
import 'package:wojob/presentation/state/empresa_state.dart';
import 'package:wojob/presentation/state/settings_state.dart';

void main() {
  late app_state.AuthState auth;
  late EmpresaState empresa;
  late AsistenciaState asistencia;
  late SettingsState settings;

  setUp(() {
    auth = app_state.AuthState();
    empresa = EmpresaState();
    asistencia = AsistenciaState();
    settings = SettingsState();
  });

  Widget app(Widget home) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: empresa),
      ChangeNotifierProvider.value(value: asistencia),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home,
    ),
  );

  void mobile(WidgetTester tester, {double width = 390}) {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('Empleado abre su sala con dirección, marcación y horario', (
    tester,
  ) async {
    mobile(tester);
    auth.currentUser = MockData.empleado1;
    await tester.pumpWidget(app(const EmployeeHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Dirección de la empresa'), findsOneWidget);
    expect(find.text(MockData.empresa.direccionEmpresa), findsOneWidget);
    expect(find.text('Marcar entrada'), findsOneWidget);
    expect(find.text('Marcar salida'), findsOneWidget);
    expect(find.text('Mi horario'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Entrar a mi sala'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Historial empleado completo y privado; directorio sin datos personales',
    (tester) async {
      mobile(tester);
      auth.currentUser = MockData.empleado1;
      await tester.pumpWidget(app(const EmployeeHomeScreen()));
      await tester.pumpAndSettle();
      await tab(tester, 'Mi historial');
      expect(find.text('Carlos Reyes'), findsWidgets);
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Salida'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Entradas'));
      await tester.pumpAndSettle();
      expect(find.text('Salida'), findsNothing);
      await tab(tester, 'Miembros');
      expect(find.text('Ana Torres'), findsOneWidget);
      expect(find.text('María González'), findsOneWidget);
      expect(find.textContaining('EMP-1049'), findsNothing);
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
      await tester.tap(find.text('Ana Torres'));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      await tab(tester, 'Perfil');
      expect(find.text(MockData.empleado1.correo), findsOneWidget);
      expect(find.text('Suscripción de la sala'), findsNothing);
      await tab(tester, 'Mi historial');
      expect(find.text('Salida'), findsNothing);
    },
  );

  testWidgets('Administrador conserva todas las opciones en barra inferior', (
    tester,
  ) async {
    mobile(tester);
    auth.currentUser = MockData.admin;
    await tester.pumpWidget(app(const AdminHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('ID de sala'), findsOneWidget);
    expect(find.text(MockData.empresa.idSala), findsOneWidget);
    expect(find.text('Dirección de la sala'), findsOneWidget);
    expect(find.text('Acciones principales'), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tab(tester, 'Turnos');
    expect(find.text('Nuevo turno'), findsOneWidget);
    await tester.tap(find.text('Carlos Reyes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Asignar turno'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asignar turno'));
    await tester.pumpAndSettle();
    expect(empresa.horariosDeEmpleado(MockData.empleado1.id).length, 6);
    await tab(tester, 'Asistencias');
    await tab(tester, 'Miembros');
    expect(find.byIcon(Icons.person_remove_outlined), findsNWidgets(2));
    await tab(tester, 'Solicitudes');
    expect(find.text('Sin solicitudes'), findsOneWidget);
    await tab(tester, 'Inicio');
    expect(find.text('Dirección de la sala'), findsOneWidget);
  });

  testWidgets(
    'Sin sala mantiene flujo para unirse y oculta navegación de sala',
    (tester) async {
      mobile(tester);
      auth.currentUser = MockData.empleado1.copyWith(clearEmpresa: true);
      await tester.pumpWidget(app(const EmployeeHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Enviar solicitud para unirme'), findsOneWidget);
      await tester.tap(find.text('Enviar solicitud para unirme'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa ID de sala'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Empleado sin horario ni historial y tamaño estrecho', (
    tester,
  ) async {
    mobile(tester, width: 320);
    auth.currentUser = MockData.empleado2;
    await tester.pumpWidget(app(const EmployeeHomeScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Aún no tienes horarios asignados.'),
      180,
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes horarios asignados.'), findsOneWidget);
    await tab(tester, 'Mi historial');
    expect(find.text('Sin registros'), findsOneWidget);
    await tab(tester, 'Miembros');
    await tab(tester, 'Perfil');
  });

  testWidgets('Administrador secundario conserva navegación de administrador', (
    tester,
  ) async {
    mobile(tester, width: 320);
    auth.currentUser = MockData.admin.copyWith(
      tipoUsuario: TipoUsuario.adminSecundario,
    );
    await tester.pumpWidget(app(const AdminHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tab(tester, 'Asistencias');
    await tab(tester, 'Solicitudes');
  });

  testWidgets('Marcar entrada abre formulario y exige fotografía', (
    tester,
  ) async {
    mobile(tester);
    auth.currentUser = MockData.empleado1;
    await tester.pumpWidget(app(const EmployeeHomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar entrada'));
    await tester.pumpAndSettle();
    expect(find.text('Datos del registro'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Confirmar entrada'), 180);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar entrada'));
    await tester.pumpAndSettle();
    expect(find.text('Debes tomar una foto para marcar.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'Directorio local solo contiene miembros de la sala solicitada',
    () async {
      await empresa.loadDirectorio(MockData.empresa.id);
      expect(empresa.directorio.length, 3);
      await empresa.loadDirectorio('otra-sala');
      expect(empresa.directorio, isEmpty);
    },
  );

  test('Salir de la sala limpia el directorio y sus errores', () async {
    await empresa.loadDirectorio(MockData.empresa.id);
    empresa.clearSalaData();
    expect(empresa.directorio, isEmpty);
    expect(empresa.directorioError, isNull);
    expect(empresa.directorioLoading, isFalse);
  });

  testWidgets('Cabecera tiene título legible sobre el fondo oscuro', (
    tester,
  ) async {
    mobile(tester);
    auth.currentUser = MockData.empleado1;
    await tester.pumpWidget(app(const EmployeeHomeScreen()));
    await tester.pumpAndSettle();
    final titulo = find.text('Inicio').first;
    expect(tester.widget<Text>(titulo).style?.color, Colors.white);
  });

  test('Asistencias se ordenan por fecha descendente, no por inserción', () {
    final original = List<Asistencia>.from(MockData.asistencias);
    addTearDown(() {
      MockData.asistencias
        ..clear()
        ..addAll(original);
    });
    final newer = Asistencia(
      id: 'new',
      empleadoId: MockData.empleado1.id,
      empresaId: MockData.empresa.id,
      tipo: TipoAsistencia.entrada,
      fechaHora: DateTime(2026, 12, 1),
      latitud: 19,
      longitud: -99,
      fotoUrl: '',
    );
    final older = Asistencia(
      id: 'old',
      empleadoId: MockData.empleado1.id,
      empresaId: MockData.empresa.id,
      tipo: TipoAsistencia.salida,
      fechaHora: DateTime(2026, 1, 1),
      latitud: 19,
      longitud: -99,
      fotoUrl: '',
    );
    MockData.asistencias
      ..clear()
      ..addAll([newer, older]);
    final state = AsistenciaState();
    expect(state.historialDeEmpleado(MockData.empleado1.id).first.id, 'new');
    expect(state.asistenciasDeEmpresa(MockData.empresa.id).first.id, 'new');
  });
}
