import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const roleGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  const rolRequerido = route.data['rolesPermitidos'] as Array<string>;
  const rolUsuario = authService.obtenerRol();

  // Si el usuario no ha iniciado sesión
  if (!rolUsuario) {
    router.navigate(['/login']); // Ajusta a tu ruta de login
    return false;
  }

  // Si tiene uno de los roles permitidos para la ruta
  if (rolRequerido.includes(rolUsuario)) {
    return true;
  }

  // Si no tiene permiso, lo pateamos a su respectiva "burbuja"
  if (rolUsuario === 'Cliente') {
    router.navigate(['/mi-evento']);
  } else {
    router.navigate(['/dashboard']);
  }
  
  return false;
};