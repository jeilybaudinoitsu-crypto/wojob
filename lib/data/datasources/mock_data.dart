import 'package:uuid/uuid.dart';
import 'package:wojob/data/models/asistencia.dart';
import 'package:wojob/data/models/dia_semana.dart';
import 'package:wojob/data/models/tipo_asistencia.dart';
import 'package:wojob/data/models/empresa.dart';
import 'package:wojob/data/models/horario.dart';
import 'package:wojob/data/models/perfil.dart';
import 'package:wojob/data/models/solicitud_sala.dart';
import 'package:wojob/data/models/tipo_usuario.dart';

const _uuid = Uuid();

class MockData {
  static final empresa = Empresa(
    id: _uuid.v4(),
    idSala: 'NOR-4826',
    nombreEmpresa: 'WoJob',
    direccionEmpresa: 'Av. Principal 123, CDMX',
    passwordHash: 'WoJob.1234',
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
  );

  static final admin = Perfil(
    id: _uuid.v4(),
    empresaId: empresa.id,
    tipoUsuario: TipoUsuario.adminPrincipal,
    nombreCompleto: 'María González',
    correo: 'maria@wojob.com',
    telefono: '5512345678',
    idPersonal: 'ADM-001',
    cargo: 'Gerente',
    estadoActivo: true,
    verificado: true,
    fotoUrl: null,
    cedulaUrl: null,
    createdAt: DateTime.now().subtract(const Duration(days: 18)),
  );

  static final empleado1 = Perfil(
    id: _uuid.v4(),
    empresaId: empresa.id,
    tipoUsuario: TipoUsuario.empleado,
    nombreCompleto: 'Carlos Reyes',
    correo: 'carlos@wojob.com',
    telefono: '5598765432',
    idPersonal: 'EMP-1048',
    cargo: 'Operador',
    estadoActivo: true,
    verificado: true,
    fotoUrl: null,
    cedulaUrl: null,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
  );

  static final empleado2 = Perfil(
    id: _uuid.v4(),
    empresaId: empresa.id,
    tipoUsuario: TipoUsuario.empleado,
    nombreCompleto: 'Ana Torres',
    correo: 'ana@wojob.com',
    telefono: '5545678910',
    idPersonal: 'EMP-1049',
    cargo: 'Vendedora',
    estadoActivo: true,
    verificado: false,
    fotoUrl: null,
    cedulaUrl: null,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  );

  static final solicitudesPendientes = <SolicitudSala>[];

  static final horarios = <Horario>[
    Horario(
      id: _uuid.v4(),
      empresaId: empresa.id,
      empleadoId: empleado1.id,
      diaSemana: DiaSemana.lunes,
      horaEntrada: '09:00',
      horaSalida: '17:00',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Horario(
      id: _uuid.v4(),
      empresaId: empresa.id,
      empleadoId: empleado1.id,
      diaSemana: DiaSemana.martes,
      horaEntrada: '09:00',
      horaSalida: '17:00',
    ),
    Horario(
      id: _uuid.v4(),
      empresaId: empresa.id,
      empleadoId: empleado1.id,
      diaSemana: DiaSemana.miercoles,
      horaEntrada: '09:00',
      horaSalida: '17:00',
    ),
    Horario(
      id: _uuid.v4(),
      empresaId: empresa.id,
      empleadoId: empleado1.id,
      diaSemana: DiaSemana.jueves,
      horaEntrada: '09:00',
      horaSalida: '17:00',
    ),
    Horario(
      id: _uuid.v4(),
      empresaId: empresa.id,
      empleadoId: empleado1.id,
      diaSemana: DiaSemana.viernes,
      horaEntrada: '09:00',
      horaSalida: '17:00',
    ),
  ];

  static final asistencias = <Asistencia>[
    Asistencia(
      id: _uuid.v4(),
      empleadoId: empleado1.id,
      empresaId: empresa.id,
      tipo: TipoAsistencia.entrada,
      fechaHora: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      latitud: 19.432608,
      longitud: -99.133209,
      fotoUrl: '',
    ),
    Asistencia(
      id: _uuid.v4(),
      empleadoId: empleado1.id,
      empresaId: empresa.id,
      tipo: TipoAsistencia.salida,
      fechaHora: DateTime.now().subtract(const Duration(days: 2, hours: -7)),
      latitud: 19.432608,
      longitud: -99.133209,
      fotoUrl: '',
    ),
  ];
}
