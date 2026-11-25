import { TestBed } from '@angular/core/testing';

import { ContratoPdfServiceService } from './contrato-pdf.service.service';

describe('ContratoPdfServiceService', () => {
  let service: ContratoPdfServiceService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(ContratoPdfServiceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
