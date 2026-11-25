import { TestBed } from '@angular/core/testing';

import { TicketPdfServiceService } from './ticket-pdf.service.service';

describe('TicketPdfServiceService', () => {
  let service: TicketPdfServiceService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(TicketPdfServiceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
