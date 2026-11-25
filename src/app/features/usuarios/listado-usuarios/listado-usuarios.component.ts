import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { UsuariosService, UsuarioItem } from '../../../core/services/usuarios.service';
import { TemaService } from '../../../core/services/tema.service';
import { BreadcrumbsComponent } from '../../../shared/components/breadcrumbs/breadcrumbs.component';

@Component({
  selector: 'app-listado-usuarios',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, BreadcrumbsComponent],
  templateUrl: './listado-usuarios.component.html'
})
export class ListadoUsuariosComponent implements OnInit {
  private usuariosService = inject(UsuariosService);
  private toastr = inject(ToastrService);
  readonly temaService = inject(TemaService);

  usuarios: UsuarioItem[] = [];
  cargando: boolean = true;
  errorMensaje: string | null = null;

  usuarioSeleccionado: UsuarioItem | null = null;
  cambiandoEstado: boolean = false;

  usuarioContrasenia: UsuarioItem | null = null;
  nuevaContrasenia: string = '';
  mostrarNuevaContrasenia: boolean = false;
  cambiandoContrasenia: boolean = false;

  ngOnInit(): void {
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
    this.cargando = true;
    this.errorMensaje = null;

    this.usuariosService.obtenerUsuarios().subscribe({
      next: (data) => {
        this.usuarios = Array.isArray(data) ? data : [];
        this.cargando = false;
      },
      error: (err) => {
        this.errorMensaje = err.error?.mensaje || 'Error al cargar los usuarios.';
        this.cargando = false;
      }
    });
  }

  abrirModalEstado(usuario: UsuarioItem): void {
    this.usuarioSeleccionado = usuario;
    const modal = document.getElementById('modal_estado_usuario') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalEstado(): void {
    const modal = document.getElementById('modal_estado_usuario') as HTMLDialogElement;
    if (modal) modal.close();
    this.usuarioSeleccionado = null;
  }

  confirmarCambioEstado(): void {
    if (!this.usuarioSeleccionado || this.cambiandoEstado) return;

    const target = this.usuarioSeleccionado;
    const nuevoEstado = !target.activo;
    this.cambiandoEstado = true;

    this.usuariosService.cambiarEstadoUsuario(target.idUsuario, nuevoEstado).subscribe({
      next: (res) => {
        target.activo = nuevoEstado;
        this.cambiandoEstado = false;
        this.cerrarModalEstado();
        this.toastr.success(
          res?.mensaje || (nuevoEstado ? 'Usuario activado.' : 'Usuario desactivado.'),
          'Estado actualizado'
        );
      },
      error: (err) => {
        this.cambiandoEstado = false;
        this.toastr.error(err.error?.mensaje || 'No se pudo actualizar el estado.', 'Error');
      }
    });
  }

  nombreCompleto(u: UsuarioItem): string {
    return `${u.nombre} ${u.apellidoPaterno} ${u.apellidoMaterno ?? ''}`.trim();
  }

  abrirModalContrasenia(usuario: UsuarioItem): void {
    this.usuarioContrasenia = usuario;
    this.nuevaContrasenia = '';
    this.mostrarNuevaContrasenia = false;
    const modal = document.getElementById('modal_contrasenia_usuario') as HTMLDialogElement;
    if (modal) modal.showModal();
  }

  cerrarModalContrasenia(): void {
    const modal = document.getElementById('modal_contrasenia_usuario') as HTMLDialogElement;
    if (modal) modal.close();
    this.usuarioContrasenia = null;
    this.nuevaContrasenia = '';
    this.mostrarNuevaContrasenia = false;
  }

  confirmarCambioContrasenia(): void {
    if (!this.usuarioContrasenia || this.cambiandoContrasenia) return;

    const pass = this.nuevaContrasenia.trim();
    if (pass.length < 6) {
      this.toastr.warning('La contraseña debe tener al menos 6 caracteres.', 'Validación');
      return;
    }

    const target = this.usuarioContrasenia;
    this.cambiandoContrasenia = true;

    this.usuariosService.cambiarContraseniaUsuario(target.idUsuario, pass).subscribe({
      next: (res) => {
        this.cambiandoContrasenia = false;
        this.cerrarModalContrasenia();
        this.toastr.success(res?.mensaje || 'Contraseña actualizada correctamente.', '¡Listo!');
      },
      error: (err) => {
        this.cambiandoContrasenia = false;
        this.toastr.error(err.error?.mensaje || 'No se pudo cambiar la contraseña.', 'Error');
      }
    });
  }
}