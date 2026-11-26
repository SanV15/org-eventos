# OrgEventos

Plataforma organizadora de eventos. Este repositorio contiene el frontend Angular, la API ASP.NET Core y la aplicación Flutter en `mobile/`.

## Módulos incluidos

El frontend contiene pantallas para autenticación, dashboard, clientes, cotizaciones, eventos, pagos y finanzas, proveedores, servicios, usuarios y portal de clientes. La API está en `backend/` e incluye controladores, servicios, SignalR y acceso a datos con Entity Framework Core.

## Requisitos

- Node.js y npm compatibles con Angular CLI 17.
- .NET 8 SDK.
- SQL Server con una base de datos y un esquema compatibles con `GestionEventosContext`.

## Frontend

Configura las variables locales antes de iniciar o compilar:

```powershell
Copy-Item .\.env.example .\.env
```

Completa `API_URL` y `STRIPE_PUBLIC_KEY` en `.env`. Los comandos npm generan
`src/assets/runtime-config.js` localmente; ese archivo y `.env` están excluidos
de Git. La clave publicable de Stripe se incluirá en el frontend compilado,
como es necesario para Stripe.js; nunca pongas una clave secreta en el cliente.

```bash
npm ci
npm start
```

La aplicación de desarrollo queda disponible en `http://localhost:4200/`.

## Aplicación móvil

Instala Flutter y ejecuta la aplicación proporcionando la URL base de la API:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://tu-api.example.com
```

Consulta [mobile/README.md](mobile/README.md) para generar un APK.

## Backend

La configuración real no se incluye porque contiene credenciales. Crea una copia local del ejemplo y reemplaza los valores antes de iniciar la API:

```powershell
Copy-Item .\backend\OrgEventos.API\appsettings.example.json .\backend\OrgEventos.API\appsettings.Development.json
$env:ASPNETCORE_URLS = "https://localhost:7106"
dotnet run --project .\backend\OrgEventos.API\OrgEventos.API.csproj
```

La API espera SQL Server, credenciales de AWS/Stripe/SMTP y, para la integración con Google Calendar, un archivo de cuenta de servicio llamado `google-calendar-credentials.json` dentro de `backend/OrgEventos.API/`. Configura estos valores localmente; no subas credenciales. Los `appsettings*.json` locales (excepto `appsettings.example.json`), `google-calendar-credentials.json`, `.vs/`, `launchSettings.json` y archivos de usuario están excluidos por `.gitignore`.

Para compilar la API:

```powershell
dotnet restore .\backend\OrgEventos.API.sln
dotnet build .\backend\OrgEventos.API.sln
```

## Pruebas y compilación del frontend

```bash
npm test -- --watch=false
npm run build
```

La salida de una compilación exitosa se guarda en `dist/`.

## Pendientes y limitaciones conocidas

- **Secretos locales:** el archivo `appsettings.example.json` contiene marcadores, no credenciales funcionales. Falta crear la configuración privada local, proporcionar una base de datos y configurar las integraciones externas.
- **Base de datos:** no se incluyen migraciones ni una copia de la base de datos; prepara el esquema antes de ejecutar la API.
- **Configuración de despliegue:** el frontend aún contiene direcciones de API de desarrollo y la política CORS de la API solo contempla localhost. Hay que configurar los orígenes y endpoints del entorno publicado.
- **Google Calendar:** falta proporcionar localmente el archivo de credenciales de cuenta de servicio y configurar un calendario válido.
- **Pruebas del frontend:** `npm test -- --watch=false` actualmente no compila por tres imports de servicios con nombres que no coinciden con sus clases exportadas (`ContratoPdfService`, `SignalRService` y `TicketPdfService`). Muchas pruebas solo verifican que el servicio o componente se cree; faltan pruebas de comportamiento e integración.
- **Compilación de producción del frontend:** `npm run build` supera el límite configurado para el paquete inicial: genera aproximadamente 1.30 MB frente al máximo de 1 MB. Hay que optimizar o dividir el bundle antes de una compilación de producción satisfactoria.
- **Compilación de la API:** `dotnet build` finaliza correctamente, pero genera advertencias que conviene resolver.

## Tecnologías principales

Angular 17, TypeScript, RxJS, Tailwind CSS, DaisyUI, SignalR y Stripe.js.
