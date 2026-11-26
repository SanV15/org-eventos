import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import {
  UsuariosService,
  RolItem,
  CrearUsuarioPayload
} from '../../../core/services/usuarios.service';
import { TemaService } from '../../../core/services/tema.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-registro-usuario',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './registro-usuario.component.html'
})
export class RegistroUsuarioComponent implements OnInit {
  private usuariosService = inject(UsuariosService);
  private toastr = inject(ToastrService);
  private router = inject(Router);
  readonly temaService = inject(TemaService);

  roles: RolItem[] = [];
  cargandoRoles: boolean = true;
  guardando: boolean = false;
  mostrarPassword: boolean = false;
  errorMensaje: string | null = null;

  modelo: Omit<CrearUsuarioPayload, 'activo'> = {
    nombre: '',
    apellidoPaterno: '',
    apellidoMaterno: '',
    correo: '',
    contrasenia: '',
    idRol: 0
  };

  ngOnInit(): void {
    this.cargarRoles();
  }

cargarRoles(): void {
  this.cargandoRoles = true;
  this.errorMensaje = null;

  const rolesOcultos = ['recepcionista', 'coordinador'];

  this.usuariosService.obtenerRoles().subscribe({
    next: (data) => {
      const lista = Array.isArray(data) ? data : [];
      this.roles = lista.filter(
        r => !rolesOcultos.includes((r.nombre || '').trim().toLowerCase())
      );

      if (this.roles.length > 0 && !this.modelo.idRol) {
        const porDefecto =
          this.roles.find(r => r.nombre.toLowerCase() === 'empleado') ??
          this.roles.find(r => r.nombre.toLowerCase() === 'administrador') ??
          this.roles[0];
        this.modelo.idRol = porDefecto.idRol;
      }
      this.cargandoRoles = false;
    },
    error: (err) => {
      this.errorMensaje = err.error?.mensaje || 'No se pudieron cargar los roles del sistema.';
      this.cargandoRoles = false;
    }
  });
}
  registrarUsuario(): void {
    if (this.guardando) return;

    this.guardando = true;
    this.errorMensaje = null;

    const payload: CrearUsuarioPayload = {
      nombre: this.modelo.nombre.trim(),
      apellidoPaterno: this.modelo.apellidoPaterno.trim(),
      apellidoMaterno: this.modelo.apellidoMaterno?.trim() || null,
      correo: this.modelo.correo.trim(),
      contrasenia: this.modelo.contrasenia,
      idRol: Number(this.modelo.idRol),
      activo: true
    };

    this.usuariosService.crearUsuario(payload).subscribe({
      next: (res) => {
        this.guardando = false;
        this.toastr.success(res?.mensaje || 'Usuario creado correctamente.', '¡Listo!');
        this.limpiarFormulario();
      },
      error: (err) => {
        this.guardando = false;
        const msg =
          err.error?.mensaje ||
          (err.error?.errors ? Object.values(err.error.errors).flat().join(' ') : null) ||
          'No se pudo registrar el usuario.';
        this.errorMensaje = String(msg);
        this.toastr.error(this.errorMensaje, 'Error');
      }
    });
  }

  limpiarFormulario(): void {
    const rolActual = this.modelo.idRol;
    this.modelo = {
      nombre: '',
      apellidoPaterno: '',
      apellidoMaterno: '',
      correo: '',
      contrasenia: '',
      idRol: rolActual
    };
  }

  volver(): void {
    this.router.navigate(['/usuarios']);
  }
}