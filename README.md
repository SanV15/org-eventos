# OrgEventos

Plataforma organizadora de eventos. Este repositorio contiene el **frontend web**, desarrollado con Angular 17.

## Módulos incluidos

El frontend contiene pantallas para autenticación, dashboard, clientes, cotizaciones, eventos, pagos y finanzas, proveedores, servicios, usuarios y portal de clientes. La presencia de una pantalla no implica que su flujo esté integrado o validado con el backend.

## Requisitos

- Node.js y npm compatibles con Angular CLI 17.
- El backend/API correspondiente para probar las funciones que consultan o modifican datos.

## Instalación y ejecución

```bash
npm ci
npm start
```

La aplicación de desarrollo queda disponible en `http://localhost:4200/`.

## Pruebas y compilación

```bash
npm test -- --watch=false
npm run build
```

La salida de una compilación exitosa se guarda en `dist/`.

## Pendientes y limitaciones conocidas

- **Backend:** no está incluido en este repositorio. La mayoría de las llamadas esperan una API en `https://localhost:7106`; también hay un servicio de tareas que usa una API de AWS. Para probar los flujos se necesita desplegar o iniciar esos servicios, configurar CORS y disponer de HTTPS local válido.
- **Configuración por entorno:** solo existe `src/environments/environment.ts`. Algunas direcciones de API están escritas directamente en servicios y componentes; conviene centralizarlas y definir valores separados para desarrollo y producción.
- **Pagos:** el frontend usa Stripe con una clave publicable de pruebas. Para procesar pagos hace falta el backend que cree y gestione los intents de Stripe. La clave secreta de Stripe debe permanecer únicamente en el backend, nunca en el frontend.
- **Pruebas automatizadas:** `npm test -- --watch=false` actualmente no compila por tres imports de servicios con nombres que no coinciden con sus clases exportadas (`ContratoPdfService`, `SignalRService` y `TicketPdfService`). Además, muchas pruebas existentes solo verifican que el servicio o componente se cree; faltan pruebas de comportamiento e integración.
- **Compilación de producción:** `npm run build` supera el límite configurado para el paquete inicial: genera aproximadamente 1.30 MB frente al máximo de 1 MB. Hay que optimizar o dividir el bundle antes de una compilación de producción satisfactoria; aumentar el límite debería hacerse solo si está justificado.

## Tecnologías principales

Angular 17, TypeScript, RxJS, Tailwind CSS, DaisyUI, SignalR y Stripe.js.
