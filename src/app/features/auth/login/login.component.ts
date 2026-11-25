import { Component, inject } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { TemaService } from '../../../core/services/tema.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  readonly temaService = inject(TemaService);

  mostrarContrasenia: boolean = false;
  enviando: boolean = false;

  loginForm: FormGroup = this.fb.group({
    correo: ['', [Validators.required, Validators.email]],
    contrasenia: ['', [Validators.required]]
  });

  mensajeError: string = '';

  alternarContrasenia(): void {
    this.mostrarContrasenia = !this.mostrarContrasenia;
  }

  onSubmit(): void {
    if (this.loginForm.valid && !this.enviando) {
      this.enviando = true;
      this.mensajeError = '';
      const { correo, contrasenia } = this.loginForm.value;

      this.authService.login(correo, contrasenia).subscribe({
        next: (res) => {
          this.enviando = false;
          console.log('Login exitoso', res);

          const rol = this.authService.obtenerRol();

          if (rol === 'Cliente') {
            this.router.navigate(['/mi-evento']);
          } else {
            this.router.navigate(['/dashboard']);
          }
        },
        error: (err) => {
          this.enviando = false;
          console.error(err);
          this.mensajeError = err.error?.mensaje || 'Error al iniciar sesión';
        }
      });
    } else {
      this.loginForm.markAllAsTouched();
    }
  }
}