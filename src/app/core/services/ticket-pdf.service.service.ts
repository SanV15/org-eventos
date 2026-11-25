import { Injectable } from '@angular/core';
import jsPDF from 'jspdf';

@Injectable({
  providedIn: 'root'
})
export class TicketPdfService {

  generarTicket(datosPago: { idCuota: number; montoPagado: number; metodoPago: string; fechaPago: string }) {
    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: [80, 150] });

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('OrgEventos', 40, 15, { align: 'center' });

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text('TICKET DE PAGO', 40, 22, { align: 'center' });
    doc.text('-----------------------------------------', 40, 26, { align: 'center' });

    doc.text(`Fecha: ${datosPago.fechaPago}`, 10, 35);
    doc.text(`Cuota ID: #${datosPago.idCuota}`, 10, 41);
    doc.text(`Método: ${datosPago.metodoPago}`, 10, 47);

    doc.text('-----------------------------------------', 40, 53, { align: 'center' });
    
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('MONTO RECIBIDO:', 40, 62, { align: 'center' });
    
    doc.setFontSize(16);
    doc.text(`$${datosPago.montoPagado.toFixed(2)} MXN`, 40, 70, { align: 'center' });

    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.text('-----------------------------------------', 40, 78, { align: 'center' });
    doc.text('¡Gracias por confiar en nosotros!', 40, 85, { align: 'center' });
    doc.text('Este documento es un comprobante', 40, 90, { align: 'center' });
    doc.text('de abono a su contrato.', 40, 94, { align: 'center' });

    doc.save(`Ticket_Recepcion_Cuota_${datosPago.idCuota}_${Date.now()}.pdf`);
  }
}