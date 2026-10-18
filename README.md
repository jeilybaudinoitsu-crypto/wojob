# WoJob

Aplicación Flutter para el **control de asistencia laboral**. Permite a las
empresas (salas) registrar empleados y a los empleados marcar su **entrada** y
**salida** con **hora exacta**, **ubicación GPS** (con precisión) y **fotografía**
del momento, además de consultar su historial y su horario semanal.

Los datos viven en **Supabase** (PostgreSQL + Auth + Storage). Mientras no exista
configuración válida de Supabase, la app funciona en **modo local (mock)** con
datos de ejemplo, de modo que se puede desarrollar y probar sin backend.

---

## Características

- Autenticación por correo, teléfono o ID personal.
- Registro de empresas (salas) con código único (p. ej. `NOR-4826`).
- Registro de empleados (2 pasos): datos personales + contraseña y luego
  cédula/foto de rostro.
- Solicitudes de acceso a una sala (pendiente / aceptada / rechazada).
- Asignación de turnos y horarios por día de la semana.
- Marcación de asistencia con foto comprimida (< 300 KB) y geolocalización.
- Mapa de solo lectura (OpenStreetMap) con la ubicación capturada.
- Historial de asistencias y panel de administración.

---

## Requisitos

- Flutter 3.x (probado con Flutter 3.47 / Dart 3.13).
- Una cuenta y un proyecto en [Supabase](https://supabase.com) (opcional para el
  modo mock).

```bash
flutter --version
flutter pub get
```

---

## Configuración de Supabase

Hay dos formas de indicar la URL y la **anon key** (ambas son credenciales
públicas del cliente, seguras de exponer):

1. **Archivo de assets** (recomendado para desarrollo): edita
   `assets/config/supabase_config.json`.

   ```json
   {
     "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
     "SUPABASE_ANON_KEY": "TU_ANON_KEY"
   }
   ```

2. **Variables de compilación** (recomendado para CI/producción; tienen
   prioridad sobre el archivo):

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
   ```

Si no se configura nada, `SupabaseService.initialize()` no hace nada y la app
arranca en modo mock sin errores.

> **Seguridad:** nunca incluyas la `service_role key` en la app ni en el
> repositorio. La `anon key` sí puede ir en el cliente.

### Base de datos

El esquema SQL está en la carpeta [`database/`](database) y debe ejecutarse en
el editor SQL de Supabase en el orden `tabla1.SQL` → `tabla5.sql`:

| Tabla | Propósito |
| --- | --- |
| `empresas` | Salas/empresas, con `id_sala` único. |
| `perfiles` | Perfil del usuario; `id` = `auth.users.id`. |
| `solicitudes_sala` | Solicitudes de acceso de empleados a una sala. |
| `horarios` | Turnos por empleado y día de la semana. |
| `asistencias` | Marcaciones (tipo, `latitud`, `longitud`, `foto_url`). |

La contraseña **no** se guarda en `perfiles`: la gestiona **Supabase Auth**
(`auth.users`).

Buckets de Storage sugeridos: `asistencias` y `documentos`.

---

## Ejecutar

```bash
flutter pub get
flutter run            # dispositivo/emulador/web disponibles
flutter run -d chrome  # solo web
```

Pruebas y análisis estático:

```bash
flutter analyze
flutter test
flutter build web     # verificación de compilación
```

### Usuarios de ejemplo (modo mock)

| Rol | Credencial | Contraseña |
| --- | --- | --- |
| Administrador | `ADM-001` | `WoJob1234` |
| Empleado | `EMP-1048` | `WoJob1234` |

También se puede iniciar sesión con el correo o el teléfono del perfil de
ejemplo. La sala de ejemplo es `NOR-4826`.

---

## Arquitectura por capas

El proyecto sigue una **arquitectura por capas** (estilo _clean architecture_
simplificada). La regla principal es que las dependencias apuntan hacia adentro:
la **presentación** depende del **dominio**, y el **dominio** no depende de nadie
concreto. La **capa de datos** implementa los contratos del dominio.

```
lib/
├── main.dart                      # Punto de entrada: init de Supabase y arranque
│
├── core/                          # Transversal a toda la app (sin lógica de negocio)
│   ├── config/                    # app_config.dart, supabase_config.dart
│   ├── errors/                    # app_exception.dart
│   ├── theme/                     # colores y tema visual
│   └── utils/                     # validadores y formateadores
│
├── data/                          # Capa de DATOS (implementación / infraestructura)
│   ├── datasources/               # SupabaseService (cliente) y MockData (semilla)
│   ├── models/                    # Entidades que mapean las tablas SQL (toMap/fromMap)
│   └── repositories/              # Implementaciones Supabase de los contratos
│
├── domain/                        # Capa de DOMINIO (contratos + servicios de plataforma)
│   ├── repositories/              # Interfaces abstractas (AuthRepository, ...)
│   └── services/                  # LocationService (GPS), MediaService (cámara/compresión)
│
└── presentation/                  # Capa de PRESENTACIÓN (UI + estado)
    ├── screens/                   # Pantallas por rol: admin/, auth/, employee/, shared/
    ├── state/                     # AppState (ChangeNotifier) — estado y acciones
    └── widgets/                   # Widgets reutilizables de la interfaz
```

### `core/`
Recursos compartidos sin lógica de negocio. `SupabaseConfig` resuelve URL/anon
key (assets + `--dart-define`); `AppConfig` centraliza constantes (buckets,
tamaño máximo de foto). `Validators` y `formatters` son utilidades puras.

### `data/`
- **`models/`**: clases que reflejan las tablas (`Perfil`, `Empresa`,
  `SolicitudSala`, `Horario`, `Asistencia`) con `fromMap`/`toMap`.
- **`datasources/`**: `SupabaseService` (cliente único) y `MockData` (datos de
  ejemplo para el modo local).
- **`repositories/`**: implementaciones de los contratos del dominio sobre
  Supabase Auth, PostgREST y Storage.

### `domain/`
- **`repositories/`**: interfaces abstractas (`AuthRepository`,
  `EmpresaRepository`, `SolicitudRepository`, `HorarioRepository`,
  `AsistenciaRepository`, `StorageRepository`). La presentación depende de
  estas, no de Supabase.
- **`services/`**: servicios de plataforma sin estado de UI —`LocationService`
  (geolocalización con precisión) y `MediaService` (captura y compresión de
  imágenes).

### `presentation/`
- **`state/`**: `AppState` (provider + `ChangeNotifier`) concentra el estado y
  las acciones (login, registro, marcaciones, etc.).
- **`screens/`**: pantallas agrupadas por rol (`auth/`, `employee/`, `admin/`,
  `shared/`), más `welcome_screen` y `home_router`.
- **`widgets/`**: componentes reutilizables (`MapPreview`, `AppTextField`,
  `PrimaryButton`, `SectionCard`, `LocalImage`, ...).

### Flujo de dependencias

```
presentation  ──►  domain  ◄──  data
   (UI/estado)   (contratos)   (Supabase/mock)
```

`presentation` usa las interfaces de `domain`; `data` las implementa. Cambiar el
origen de datos (Supabase por otra API) solo requiere una nueva implementación de
repositorio, sin tocar las pantallas.

---

## Estructura del repositorio

```
wojob/
├── android/ ios/ web/ linux/ macos/ windows/   # Plataformas Flutter
├── assets/
│   ├── config/supabase_config.json             # URL + anon key de Supabase
│   └── images/                                 # Recursos gráficos
├── database/                                   # Esquema SQL (tabla1.SQL ... tabla5.sql)
├── lib/                                         # Código fuente (ver arriba)
├── test/                                        # Pruebas de widgets
└── pubspec.yaml                                 # Dependencias y assets
```
