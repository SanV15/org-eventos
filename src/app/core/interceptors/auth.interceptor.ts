import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('token');
  const router = inject(Router); // Inyectamos el enrutador para poder expulsar al usuario

  let reqClonada = req;
  
  // Si hay token, lo pegamos a la petición
  if (token) {
    reqClonada = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }

  // Dejamos pasar la petición, pero nos quedamos "escuchando" la respuesta del backend
  return next(reqClonada).pipe(
    catchError((error: HttpErrorResponse) => {
      // Si el backend dice que el token expiró o es inválido (401)
      if (error.status === 401) {
        localStorage.removeItem('token'); // Destruimos el token zombie
        router.navigate(['/login']);      // Pateamos al usuario a la pantalla de acceso
      }
      return throwError(() => error);
    })
  );
};