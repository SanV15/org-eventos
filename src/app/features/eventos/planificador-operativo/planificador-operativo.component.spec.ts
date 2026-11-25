import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PlanificadorOperativoComponent } from './planificador-operativo.component';

describe('PlanificadorOperativoComponent', () => {
  let component: PlanificadorOperativoComponent;
  let fixture: ComponentFixture<PlanificadorOperativoComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PlanificadorOperativoComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(PlanificadorOperativoComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
