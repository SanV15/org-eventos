import { Injectable } from '@angular/core';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { CotizacionLectura } from './cotizacion.service';

@Injectable({
  providedIn: 'root'
})
export class CotizacionPdfService {
  generarYDescargar(cotizacion: CotizacionLectura): void {
    const doc = new jsPDF();

    // Encabezado de marca
    doc.setFontSize(22);
    doc.setTextColor(37, 99, 235);
    doc.text('OrgEventos', 14, 20);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text('Tu evento, nuestra pasión.', 14, 26);

    // Folio y fecha
    doc.setFontSize(14);
    doc.setTextColor(30, 30, 30);
    doc.text('Presupuesto Formal', 140, 20);
    doc.setFontSize(10);
    doc.text(`Folio: #${cotizacion.idCotizacion}`, 140, 26);
    doc.text(`Fecha: ${cotizacion.fecha}`, 140, 31);

    // Datos del cliente
    doc.setFontSize(11);
    doc.setTextColor(50, 50, 50);
    doc.text(`Preparado para: ${cotizacion.nombreClienteCompleto}`, 14, 40);

    let startY = 48;

    // Tabla de servicios internos
    if (cotizacion.serviciosInternos.length > 0) {
      autoTable(doc, {
        startY,
        head: [['Servicio de Agencia', 'Cant.', 'Precio Unit.', 'Subtotal']],
        body: cotizacion.serviciosInternos.map((s) => [
          s.nombreServicio,
          s.cantidad,
          `$${s.precioUnitario.toFixed(2)}`,
          `$${s.subtotal.toFixed(2)}`
        ]),
        theme: 'striped',
        headStyles: { fillColor: [37, 99, 235] },
        styles: { fontSize: 10 }
      });
      startY = (doc as any).lastAutoTable.finalY + 10;
    }

    // Tabla de servicios externos
    if (cotizacion.serviciosExternos.length > 0) {
      autoTable(doc, {
        startY,
        head: [['Servicio Externo', 'Proveedor', 'Cant.', 'Costo', 'Subtotal']],
        body: cotizacion.serviciosExternos.map((se) => [
          se.nombreServicioProveedor +
            (se.observaciones ? `\n(Nota: ${se.observaciones})` : ''),
          se.nombreEmpresaProveedor,
          se.cantidad,
          `$${se.precioCotizado.toFixed(2)}`,
          `$${se.subtotal.toFixed(2)}`
        ]),
        theme: 'striped',
        headStyles: { fillColor: [71, 85, 105] },
        styles: { fontSize: 10 }
      });
      startY = (doc as any).lastAutoTable.finalY + 10;
    }

    // Gran total
    doc.setFontSize(14);
    doc.setTextColor(0, 0, 0);
    doc.text(
      `GRAN TOTAL: $${cotizacion.total.toFixed(2)} MXN`,
      140,
      startY + 10
    );

    doc.save(`Cotizacion_${cotizacion.idCotizacion}.pdf`);
  }
}