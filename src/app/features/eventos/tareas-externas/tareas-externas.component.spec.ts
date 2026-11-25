import { ComponentFixture, TestBed } from '@angular/core/testing';

import { TareasExternasComponent } from './tareas-externas.component';

describe('TareasExternasComponent', () => {
  let component: TareasExternasComponent;
  let fixture: ComponentFixture<TareasExternasComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TareasExternasComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(TareasExternasComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
