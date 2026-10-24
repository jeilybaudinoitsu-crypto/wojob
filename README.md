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

Hay dos formas de indicar la URL y una **publishable/anon key** (credencial
pública del cliente; nunca uses la `service_role key`):

1. **Archivo de assets**: edita `assets/config/supabase_config.json`. El archivo
   está vacío inicialmente; mientras siga vacío, la app usa datos mock locales.

   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "<publishable-key>"
   }
   ```

2. **Variables de compilación** (recomendado para CI/producción; tienen
   prioridad sobre el archivo):

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
   ```

La app **no lee `.env`**. Si falta la URL o la key, aparece un aviso permanente
de modo local: no se envían peticiones a Supabase y los cambios se pierden al
cerrar. En modo remoto, el registro, empresas, solicitudes, turnos, asistencias
y fotos pasan por los repositorios Supabase; los fallos de red, Auth, permisos
o Storage se muestran en pantalla.

> **Seguridad:** nunca incluyas la `service_role key` en la app ni en el
> repositorio. La publishable/anon key sí puede ir en el cliente.

### Base de datos y Storage

Si el proyecto aún no tiene las tablas, ejecuta una sola vez los archivos de
[`supabase/migrations/`](./supabase/migrations/) en el **SQL Editor** de
Supabase, en orden numérico del 1 al 5. Si ya existen, no vuelvas a ejecutar los
`CREATE TABLE`; comprueba los nombres de tablas, columnas y tipos en **Table
Editor**. Esas migraciones crean las tablas, pero no crean buckets ni políticas
RLS.

| Tabla | Propósito |
| --- | --- |
| `empresas` | Salas/empresas, con `id_sala` único. |
| `perfiles` | Perfil del usuario; `id` = `auth.users.id`. |
| `solicitudes_sala` | Solicitudes de acceso de empleados a una sala. |
| `horarios` | Turnos por empleado y día de la semana. |
| `asistencias` | Marcaciones (tipo, `latitud`, `longitud`, `foto_url`). |

La ubicación que captura la app es GPS (`latitud`/`longitud`), no la dirección
IP del dispositivo.

La contraseña de la cuenta **no** se guarda en `perfiles`: la gestiona
**Supabase Auth** (`auth.users`). Para exigir la verificación por código durante
el registro, activa **Authentication → Sign In / Providers → Email → Confirm
email**. Después de validar el código en la app, se crea el perfil y se suben
las fotos. Si desactivas esa opción, Supabase no enviará el código de registro
y la app completará el registro sin ese paso.

Configura la longitud del OTP de Supabase en **8** (`mailer_otp_length`) para
que coincida con los campos de la app. Si tu panel no muestra esta opción,
actualiza la configuración de Auth mediante la Management API:

```bash
curl -X PATCH "https://api.supabase.com/v1/projects/<PROJECT_REF>/config/auth" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mailer_otp_length": 8}'
```

Usa un token de acceso con permisos de configuración del proyecto; no lo
incluyas en la app ni en el repositorio. Después, para que el correo de
registro incluya el código en vez del enlace, abre **Authentication → Emails →
Confirm signup** y usa `{{ .Token }}` en el cuerpo, por ejemplo:

```html
<h2>Confirma tu correo</h2>
<p>Ingresa este código de ocho dígitos en la aplicación:</p>
<p><strong>{{ .Token }}</strong></p>
```

La app verifica el código como OTP de registro antes de crear el perfil. Si el
cuerpo de la plantilla está bloqueado, configura primero un SMTP personalizado
desde esa misma sección de Emails. La plantilla **Reset password** es
independiente; también debe usar `{{ .Token }}` para la recuperación de
contraseña descrita a continuación.

Para que la recuperación envíe un código de ocho dígitos en vez de un enlace,
abre **Authentication → Emails → Reset password** en Supabase y
reemplaza el enlace que use `{{ .ConfirmationURL }}` por el código
`{{ .Token }}`. Por ejemplo:

```html
<h2>Restablecer contraseña</h2>
<p>Ingresa este código de ocho dígitos en la aplicación:</p>
<p><strong>{{ .Token }}</strong></p>
```

La app valida el código como OTP de recuperación antes de permitir cambiar la
contraseña. Si la plantilla sigue usando `{{ .ConfirmationURL }}`, el correo
seguirá incluyendo el enlace de recuperación predeterminado.

En **Storage → New bucket**, crea estos buckets como **privados**:

| Bucket | Contenido | Ruta usada por la app |
| --- | --- | --- |
| `avatares` | Foto de perfil | `<auth.uid()>/foto.jpg` |
| `documentos` | Foto de cédula | `<auth.uid()>/cedula.jpg` |
| `asistencias` | Foto al marcar entrada/salida | `<empresa_id>/<auth.uid()>/<id>.jpg` |

Después de crear los buckets y las tablas, ejecuta una sola vez
[`supabase/storage_policies.sql`](./supabase/storage_policies.sql) desde el
**SQL Editor**. Las políticas dejan `documentos` privado, restringen subidas a
la carpeta del usuario y dan acceso a las fotos de asistencia solo al empleado
dueño o a administradores de su empresa. No hagas público el bucket
`documentos`: la app guarda la ruta y solicita URLs firmadas para mostrar las
imágenes.

Finalmente, habilita RLS en las cinco tablas y crea políticas `SELECT`,
`INSERT`, `UPDATE` y `DELETE` según el rol y pertenencia a empresa. Las tablas
deben dar acceso de Data API al rol `authenticated`; no uses la `service_role`
en Flutter ni des acceso público sin RLS. La consola de Supabase → **Database →
Table Editor** muestra las filas remotas; Flutter no usa `localStorage` como
base de datos.

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
