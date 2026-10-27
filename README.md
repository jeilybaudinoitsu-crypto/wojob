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
- Planes de sala: FREE (10 empleados), BUSINESS GOLD ($25/mes, 250 empleados)
  y CEO DIAMOND ($60/mes, empleados ilimitados).
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
Supabase, en orden numérico del 1 al 6. Si ya existen, no vuelvas a ejecutar los
`CREATE TABLE`; comprueba los nombres de tablas, columnas y tipos en **Table
Editor**. La migración 6 añade el plan y el límite de empleados de cada sala,
además de la validación del cupo en la base de datos. Esas migraciones crean las
tablas, pero no crean buckets ni políticas RLS.

| Tabla | Propósito |
| --- | --- |
| `empresas` | Salas/empresas, con `id_sala` único. |
| `perfiles` | Perfil del usuario; `id` = `auth.users.id`. |
| `solicitudes_sala` | Solicitudes de acceso de empleados a una sala. |
| `horarios` | Turnos por empleado y día de la semana. |
| `asistencias` | Marcaciones (tipo, `latitud`, `longitud`, `foto_url`). |

Los planes pagados se cobran mediante Stripe Checkout. La app solicita el
checkout a una Edge Function autenticada y el plan solo se activa cuando el
webhook firmado de Stripe confirma una suscripción activa. En esta primera
versión se pueden contratar planes desde FREE; los cambios y cancelaciones de
planes de pago aún no se gestionan desde la app.

### Pagos con Stripe (modo de pruebas)

Antes de probar, completa la configuración de base de datos y ejecuta
`supabase/stripe_payment_security.sql` según los pasos siguientes de esta guía.

1. En Stripe, activa **test mode** y crea los productos BUSINESS GOLD y CEO
   DIAMOND con precios **recurrentes mensuales**. Usa la moneda que quieres
   cobrar y precios que coincidan con los importes mostrados en la app; copia
   los dos identificadores `price_...`.
2. En Supabase, abre **Edge Functions → Secrets** y añade:

   | Nombre | Valor |
   | --- | --- |
   | `STRIPE_SECRET_KEY` | Clave secreta de pruebas `sk_test_...` |
   | `STRIPE_PRICE_BUSINESS_GOLD` | ID de precio mensual `price_...` |
   | `STRIPE_PRICE_CEO_DIAMOND` | ID de precio mensual `price_...` |
   | `STRIPE_SUCCESS_URL` | `wojob://payment-success?session_id={CHECKOUT_SESSION_ID}` |
   | `STRIPE_CANCEL_URL` | `wojob://payment-cancelled` |
   | `STRIPE_WEBHOOK_SECRET` | Se añade en el paso 4, cuando Stripe genere el endpoint |

   `SUPABASE_URL` y las claves de API de Supabase ya están disponibles para las
   Edge Functions. **No** guardes una clave `sk_...` o `whsec_...` en Flutter,
   en `assets/config/` ni en el `.env` del cliente. El flujo alojado por Stripe
   no necesita la publishable key `pk_test_...` de Stripe.
   Android ya está configurado para abrir los enlaces `wojob://` en la app; la
   aplicación escucha ambos retornos. En el retorno de éxito, la app refresca
   la sala, pero solo el webhook firmado confirma y activa el plan.
3. Enlaza el directorio con tu proyecto y despliega las funciones:

   ```bash
   supabase link --project-ref <PROJECT_REF>
   supabase functions deploy create-checkout-session
   supabase functions deploy stripe-webhook
   ```

4. En Stripe, añade un webhook con esta URL:
   `https://<PROJECT_REF>.supabase.co/functions/v1/stripe-webhook`. Selecciona
   `customer.subscription.created`, `customer.subscription.updated` y
   `customer.subscription.deleted`. Copia el secreto de firma `whsec_...` a
   `STRIPE_WEBHOOK_SECRET` en Supabase. La función verifica esa firma; el resto
   de las funciones conserva la validación JWT predeterminada.
5. Inicia sesión en WoJob como administrador de una sala FREE y elige un plan.
   Para probar en Stripe test mode, usa una tarjeta de prueba publicada por
   Stripe (por ejemplo, `4242 4242 4242 4242`) con una fecha futura y cualquier
   CVC. Revisa **Developers → Webhooks → Events** para confirmar que el webhook
   llegó; el plan solo cambiará después de recibir esos eventos.

Para producción, crea precios y webhook en **live mode** y reemplaza las claves
`sk_test_...` / `whsec_...` por sus equivalentes de producción. Configura URLs
de éxito/cancelación HTTPS válidas. Las instrucciones oficiales de
[despliegue de Edge Functions](https://supabase.com/docs/guides/functions/deploy)
y [secretos de Edge Functions](https://supabase.com/docs/guides/functions/secrets)
incluyen los detalles de la CLI y el Dashboard.

La ubicación que captura la app es GPS (`latitud`/`longitud`), no la dirección
IP del dispositivo.

Después de crear las tablas, ejecuta una vez
[`supabase/auth_registration.sql`](./supabase/auth_registration.sql) y
[`supabase/room_access_policies.sql`](./supabase/room_access_policies.sql) desde
el **SQL Editor**, en ese orden. El primero crea el perfil al registrar una
cuenta mediante un trigger `SECURITY DEFINER` en un esquema privado y convierte
las contraseñas de sala existentes y futuras a hash bcrypt. El segundo instala
las políticas protegidas que enlazan la sala recién creada con su administrador,
permiten restaurar salas y autorizan enviar, ver y aprobar solicitudes. No
ejecutes estos scripts antes de crear `empresas`, `perfiles` y
`solicitudes_sala`.

Después, ejecuta una vez
[`supabase/stripe_payment_security.sql`](./supabase/stripe_payment_security.sql)
en el SQL Editor. Este script elimina el permiso previo para cambiar planes
directamente desde el cliente, de modo que solo el webhook de Stripe puede
actualizar una suscripción. Es idempotente y también es necesario si ya
ejecutaste la migración 6 o una versión anterior de las políticas de sala.

La contraseña de la cuenta **no** se guarda en `perfiles`: la gestiona
**Supabase Auth** (`auth.users`) mediante almacenamiento seguro de contraseñas.
En **Authentication → Sign In / Providers → Email**, desactiva **Confirm email**
para permitir el registro sin confirmación. La app conserva únicamente el flujo
por código para recuperar contraseñas.

La recuperación de contraseña usa un código enviado por correo. En
**Authentication → Emails → Reset password**, configura `{{ .Token }}` en la
plantilla para que coincida con el flujo de la app. Configura el OTP en ocho
dígitos; si el panel no muestra esta opción, utiliza la Management API:

```bash
curl -X PATCH "https://api.supabase.com/v1/projects/<PROJECT_REF>/config/auth" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"mailer_otp_length": 8}'
```

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
