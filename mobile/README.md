# OrgEventos móvil

Aplicación móvil Flutter para OrgEventos.

## Configuración y ejecución

La URL de la API se configura al compilar y no se guarda en el código:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://tu-api.example.com
```

Para generar un APK:

```bash
flutter build apk --dart-define=API_BASE_URL=https://tu-api.example.com
```

Configura `API_BASE_URL` con la URL base de la API, sin `/api` al final.
