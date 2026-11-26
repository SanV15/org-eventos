// import { Routes } from '@angular/router';
// import { LoginComponent } from './features/auth/login/login.component';
// import { DashboardComponent } from './features/dashboard/dashboard.component';

// import { RegistroClienteComponent } from './features/clientes/registro-cliente/registro-cliente.component';
// import { DashboardClienteComponent } from './features/portal-cliente/dashboard-cliente/dashboard-cliente.component';
// import { roleGuard } from './core/guards/role.guard';
// import { ListadoClientesComponent } from './features/clientes/listado-clientes/listado-clientes.component';
// import { EditarClienteComponent } from './features/clientes/editar-cliente/editar-cliente.component';
// import { ListadoProveedoresComponent } from './features/proveedores/listado-proveedores/listado-proveedores.component';
// import { NuevoProveedorComponent } from './features/proveedores/nuevo-proveedor/nuevo-proveedor.component';
// import { EditarProveedorComponent } from './features/proveedores/editar-proveedor/editar-proveedor.component';
// import { PerfilProveedorComponent } from './features/proveedores/perfil-proveedor/perfil-proveedor.component';
// import { ListadoServiciosComponent } from './features/servicios/listado-servicios/listado-servicios.component';
// import { ListadoCotizacionesComponent } from './features/cotizaciones/listado-cotizaciones/listado-cotizaciones.component';
// import { NuevaCotizacionComponent } from './features/cotizaciones/nueva-cotizacion/nueva-cotizacion.component';
// import { DetalleCotizacionComponent } from './features/cotizaciones/detalle-cotizacion/detalle-cotizacion.component';
// import { EstadoCuentaComponent } from './features/pagos/estado-cuenta/estado-cuenta.component';
// import { CajaGeneralComponent } from './features/finanzas/caja-general/caja-general.component';
// import { ListadoEventosComponent } from './features/eventos/listado-eventos/listado-eventos.component';
// import { PlanificadorOperativoComponent } from './features/eventos/planificador-operativo/planificador-operativo.component';
// import { TareasExternasComponent } from './features/eventos/tareas-externas/tareas-externas.component';
// import { RegistroUsuarioComponent } from './features/usuarios/registro-usuario/registro-usuario.component';
// import { ListadoUsuariosComponent } from './features/usuarios/listado-usuarios/listado-usuarios.component';

// export const routes: Routes = [
//   { path: 'login', component: LoginComponent },

//   // Rutas protegidas (Administrativas)
//   {
//     path: 'dashboard',
//     component: DashboardComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Panel de Control'
//     }
//   },
//   {
//     path: 'clientes/nuevo',
//     component: RegistroClienteComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Nuevo Cliente'
//     }
//   },

//   // Ruta protegida (Exclusiva del Cliente)
//   {
//     path: 'mi-evento',
//     component: DashboardClienteComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Cliente'],
//       breadcrumb: 'Mi Evento'
//     }
//   },
//   {
//     path: 'clientes',
//     component: ListadoClientesComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Clientes'
//     }
//   },
//   {
//     path: 'clientes/editar/:id',
//     component: EditarClienteComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Editar Cliente'
//     }
//   },

//   {
//     path: 'proveedores',
//     component: ListadoProveedoresComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Proveedores'
//     }
//   },
//   {
//     path: 'proveedores/nuevo',
//     component: NuevoProveedorComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Nuevo Proveedor'
//     }
//   },
//   {
//     path: 'proveedores/editar/:id',
//     component: EditarProveedorComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Editar Proveedor'
//     }
//   },
//   {
//     path: 'proveedores/:id/perfil',
//     component: PerfilProveedorComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Perfil de Proveedor'
//     }
//   },

//   {
//     path: 'servicios',
//     component: ListadoServiciosComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Servicios Internos'
//     }
//   },
//   {
//     path: 'cotizaciones',
//     component: ListadoCotizacionesComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Cotizaciones'
//     }
//   },
//   {
//     path: 'cotizaciones/nueva',
//     component: NuevaCotizacionComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Nueva Cotización'
//     }
//   },
//   {
//     path: 'cotizaciones/:id',
//     component: DetalleCotizacionComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Empleado'],
//       breadcrumb: 'Detalle de Cotización'
//     }
//   },

//   // Módulo de Finanzas y Pagos
//   {
//     path: 'pagos',
//     component: CajaGeneralComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Pagos y Caja General'
//     }
//   },

//   // RUTA INDIVIDUAL (Estado de Cuenta del cliente)
//   {
//     path: 'clientes/:id/finanzas',
//     component: EstadoCuentaComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Estado de Cuenta'
//     }
//   },

//   {
//     path: 'eventos',
//     component: ListadoEventosComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador', 'Recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Administración de Eventos'
//     }
//   },
//   {
//     path: 'eventos/:id/planificador',
//     component: PlanificadorOperativoComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador','recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Planificador Operativo'
//     }
//   },
//   {
//     path: 'eventos/tareas-externas',
//     component: TareasExternasComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador','recepcionista', 'Coordinador', 'Empleado'],
//       breadcrumb: 'Tareas Externas'
//     }
//   },

//   // Módulo exclusivo de Administrador
//   {
//     path: 'usuarios/nuevo',
//     component: RegistroUsuarioComponent,
//     canActivate: [roleGuard],
//     data: {
//       rolesPermitidos: ['Administrador'],
//       breadcrumb: 'Agregar Usuario'
//     }
//   },
//   {
//   path: 'usuarios',
//   component: ListadoUsuariosComponent,
//   canActivate: [roleGuard],
//   data: {
//     rolesPermitidos: ['Administrador'],
//     breadcrumb: 'Usuarios'
//   }
// },
// {
//   path: 'usuarios/nuevo',
//   component: RegistroUsuarioComponent,
//   canActivate: [roleGuard],
//   data: {
//     rolesPermitidos: ['Administrador'],
//     breadcrumb: 'Agregar Usuario'
//   }
// },

//   // Redirecciones por defecto
//   { path: '', redirectTo: '/login', pathMatch: 'full' },
//   { path: '**', redirectTo: '/login' }
// ];

//////DESCOMENTAR EL CODIGO SI NO FUNCIONAN LOS PERMISOS DE EMPLEADO.
import { Routes } from '@angular/router';
import { LoginComponent } from './features/auth/login/login.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';

import { RegistroClienteComponent } from './features/clientes/registro-cliente/registro-cliente.component';
import { DashboardClienteComponent } from './features/portal-cliente/dashboard-cliente/dashboard-cliente.component';
import { roleGuard } from './core/guards/role.guard';
import { ListadoClientesComponent } from './features/clientes/listado-clientes/listado-clientes.component';
import { EditarClienteComponent } from './features/clientes/editar-cliente/editar-cliente.component';
import { ListadoProveedoresComponent } from './features/proveedores/listado-proveedores/listado-proveedores.component';
import { NuevoProveedorComponent } from './features/proveedores/nuevo-proveedor/nuevo-proveedor.component';
import { EditarProveedorComponent } from './features/proveedores/editar-proveedor/editar-proveedor.component';
import { PerfilProveedorComponent } from './features/proveedores/perfil-proveedor/perfil-proveedor.component';
import { ListadoServiciosComponent } from './features/servicios/listado-servicios/listado-servicios.component';
import { ListadoCotizacionesComponent } from './features/cotizaciones/listado-cotizaciones/listado-cotizaciones.component';
import { NuevaCotizacionComponent } from './features/cotizaciones/nueva-cotizacion/nueva-cotizacion.component';
import { DetalleCotizacionComponent } from './features/cotizaciones/detalle-cotizacion/detalle-cotizacion.component';
import { EstadoCuentaComponent } from './features/pagos/estado-cuenta/estado-cuenta.component';
import { CajaGeneralComponent } from './features/finanzas/caja-general/caja-general.component';
import { ListadoEventosComponent } from './features/eventos/listado-eventos/listado-eventos.component';
import { PlanificadorOperativoComponent } from './features/eventos/planificador-operativo/planificador-operativo.component';
import { TareasExternasComponent } from './features/eventos/tareas-externas/tareas-externas.component';
import { RegistroUsuarioComponent } from './features/usuarios/registro-usuario/registro-usuario.component';
import { ListadoUsuariosComponent } from './features/usuarios/listado-usuarios/listado-usuarios.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },

  // Rutas protegidas (Administrativas y Operativas)
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Panel de Control'
    }
  },
  {
    path: 'clientes/nuevo',
    component: RegistroClienteComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Nuevo Cliente'
    }
  },

  // Ruta protegida (Exclusiva del Cliente)
  {
    path: 'mi-evento',
    component: DashboardClienteComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Cliente'],
      breadcrumb: 'Mi Evento'
    }
  },
  {
    path: 'clientes',
    component: ListadoClientesComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Clientes'
    }
  },
  {
    path: 'clientes/editar/:id',
    component: EditarClienteComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Editar Cliente'
    }
  },

  {
    path: 'proveedores',
    component: ListadoProveedoresComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Proveedores'
    }
  },
  {
    path: 'proveedores/nuevo',
    component: NuevoProveedorComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Nuevo Proveedor'
    }
  },
  {
    path: 'proveedores/editar/:id',
    component: EditarProveedorComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Editar Proveedor'
    }
  },
  {
    path: 'proveedores/:id/perfil',
    component: PerfilProveedorComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Perfil de Proveedor'
    }
  },

  {
    path: 'servicios',
    component: ListadoServiciosComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Servicios Internos'
    }
  },
  {
    path: 'cotizaciones',
    component: ListadoCotizacionesComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Cotizaciones'
    }
  },
  {
    path: 'cotizaciones/nueva',
    component: NuevaCotizacionComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Nueva Cotización'
    }
  },
  {
    path: 'cotizaciones/:id',
    component: DetalleCotizacionComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Detalle de Cotización'
    }
  },

  // Módulo de Finanzas y Pagos
  {
    path: 'pagos',
    component: CajaGeneralComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Pagos y Caja General'
    }
  },

  // RUTA INDIVIDUAL (Estado de Cuenta del cliente)
  {
    path: 'clientes/:id/finanzas',
    component: EstadoCuentaComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Estado de Cuenta'
    }
  },

  {
    path: 'eventos',
    component: ListadoEventosComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Administración de Eventos'
    }
  },
  {
    path: 'eventos/:id/planificador',
    component: PlanificadorOperativoComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Planificador Operativo'
    }
  },
  {
    path: 'eventos/tareas-externas',
    component: TareasExternasComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador', 'Empleado'],
      breadcrumb: 'Tareas Externas'
    }
  },

  // Módulo exclusivo de Administrador
  {
    path: 'usuarios',
    component: ListadoUsuariosComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador'],
      breadcrumb: 'Usuarios'
    }
  },
  {
    path: 'usuarios/nuevo',
    component: RegistroUsuarioComponent,
    canActivate: [roleGuard],
    data: {
      rolesPermitidos: ['Administrador'],
      breadcrumb: 'Agregar Usuario'
    }
  },

  // Redirecciones por defecto
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: '**', redirectTo: '/login' }
];