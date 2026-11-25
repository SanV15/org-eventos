import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CajaGeneralComponent } from './caja-general.component';

describe('CajaGeneralComponent', () => {
  let component: CajaGeneralComponent;
  let fixture: ComponentFixture<CajaGeneralComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CajaGeneralComponent]
    })
    .compileComponents();
    
    fixture = TestBed.createComponent(CajaGeneralComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
