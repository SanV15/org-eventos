import { Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { TemaService } from './core/services/tema.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss'
})
export class AppComponent {
  title = 'org-eventos-web';
  readonly temaService = inject(TemaService);
}