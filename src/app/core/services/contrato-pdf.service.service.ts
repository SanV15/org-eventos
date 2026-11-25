import { Injectable } from '@angular/core';
import jsPDF from 'jspdf';

@Injectable({
  providedIn: 'root'
})
export class ContratoPdfService {

  generarPdfContrato(contrato: any) {
    const doc = new jsPDF('p', 'mm', 'a4');
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const margin = 15;
    const contentWidth = pageWidth - (margin * 2);
    let y = 20;

    // 1. ENCABEZADO CORPORATIVO Y TÍTULO
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(20);
    doc.setTextColor(79, 70, 229); // Índigo
    doc.text('OrgEventos', margin, y);

    doc.setFontSize(10);
    doc.setTextColor(31, 41, 55);
    doc.text(`Contrato #: ${contrato.idContrato}`, pageWidth - margin, y, { align: 'right' });
    
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(107, 114, 128);
    const fechaFormateada = new Date(contrato.fechaContrato).toLocaleDateString();
    doc.text(`Fecha de Emisión: ${fechaFormateada}`, pageWidth - margin, y + 5, { align: 'right' });

    y += 10;
    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(17, 24, 39);
    doc.text('CONTRATO DE PRESTACIÓN DE SERVICIOS PARA EVENTOS', margin, y);

    // 🏷️ ETIQUETA DE ESTATUS SUPERIOR
    const estado = contrato.estadoContrato?.toUpperCase() || 'PENDIENTE';
    let badgeColor = [245, 158, 11]; // Naranja para Pendiente
    if (estado === 'ACTIVO') badgeColor = [16, 185, 129]; // Verde para Activo
    if (estado === 'LIQUIDADO') badgeColor = [79, 70, 229]; // Índigo para Liquidado

    doc.setFillColor(badgeColor[0], badgeColor[1], badgeColor[2]);
    doc.roundedRect(margin, y + 4, 35, 6, 1, 1, 'F');
    doc.setFontSize(7.5);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);
    doc.text(`ESTADO: ${estado}`, margin + 17.5, y + 8, { align: 'center' });

    y += 16;
    doc.setLineWidth(0.4);
    doc.setDrawColor(229, 231, 235);
    doc.line(margin, y, pageWidth - margin, y);
    y += 8;

    // 2. INTRODUCCIÓN
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9.5);
    doc.setTextColor(55, 65, 81);
    const introTexto = `Contrato de prestación de servicios celebrado entre la empresa organizadora OrgEventos y el cliente ${contrato.nombreCliente}, bajo los términos, declaraciones y condiciones financieras descritas en el presente documento:`;
    const splitIntro = doc.splitTextToSize(introTexto, contentWidth);
    doc.text(splitIntro, margin, y);
    y += splitIntro.length * 5 + 6;

    // 3. DATOS GENERALES DEL EVENTO
    doc.setFillColor(243, 244, 246);
    doc.roundedRect(margin, y, contentWidth, 30, 2, 2, 'F');
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    doc.setTextColor(17, 24, 39);
    doc.text('1. Datos Generales del Evento', margin + 5, y + 6);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9.5);
    doc.setTextColor(55, 65, 81);
    doc.text(`• Evento: ${contrato.nombreEvento}`, margin + 5, y + 13);
    doc.text(`• Fecha Programada: ${contrato.fechaEvento}`, margin + 5, y + 19);
    doc.text(`• Lugar / Sede: ${contrato.lugar}`, margin + 5, y + 25);
    doc.text(`• Invitados: ${contrato.numeroInvitados}`, margin + 110, y + 13);
    doc.text(`• Contacto: ${contrato.telefonoCliente}`, margin + 110, y + 19);
    
    y += 36;

    // 4. DESGLOSE DE SERVICIOS
    let alturaServicios = 14 + (contrato.servicios?.length || 0) * 6 + 10;
    doc.setFillColor(243, 244, 246);
    doc.roundedRect(margin, y, contentWidth, alturaServicios, 2, 2, 'F');
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    doc.setTextColor(17, 24, 39);
    doc.text('2. Desglose de Servicios Contratados', margin + 5, y + 6);

    y += 11;
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8.5);
    doc.setTextColor(75, 85, 99);
    doc.text('Concepto', margin + 5, y);
    doc.text('Tipo', margin + 95, y);
    doc.text('Cant.', margin + 125, y);
    doc.text('Subtotal', pageWidth - margin - 5, y, { align: 'right' });
    
    y += 3;
    doc.setLineWidth(0.3);
    doc.line(margin + 5, y, pageWidth - margin - 5, y);
    y += 5;

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(31, 41, 55);
    if (contrato.servicios) {
      for (const s of contrato.servicios) {
        doc.text(s.nombre, margin + 5, y);
        doc.text(s.tipo, margin + 95, y);
        doc.text(s.cantidad.toString(), margin + 125, y);
        doc.text(`$${s.subtotal.toFixed(2)}`, pageWidth - margin - 5, y, { align: 'right' });
        y += 6;
      }
    }

    y += 2;
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9.5);
    doc.setTextColor(17, 24, 39);
    doc.text(`Monto Total Acordado: $${contrato.montoAcordado.toFixed(2)} MXN`, pageWidth - margin - 5, y, { align: 'right' });
    
    y += 12;

    // 5. PLAN DE PAGOS CON ESTATUS LIMPIO
    let alturaPagos = 14 + (contrato.cuotas?.length || 0) * 6 + 6;
    doc.setFillColor(243, 244, 246);
    doc.roundedRect(margin, y, contentWidth, alturaPagos, 2, 2, 'F');
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10.5);
    doc.setTextColor(17, 24, 39);
    doc.text('3. Plan de Pagos Autorizado', margin + 5, y + 6);

    y += 11;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(31, 41, 55);

    if (contrato.cuotas) {
      for (const c of contrato.cuotas) {
        const estadoCuota = (c.estado || 'Pendiente').toUpperCase();
        doc.text(`• Cuota #${c.numeroCuota} — $${c.monto.toFixed(2)} (Límite: ${c.fechaLimite}) — [${estadoCuota}]`, margin + 5, y);
        y += 6;
      }
    }

    y += 14;

    // 6. CONSTANCIA DE ACEPTACIÓN DIGITAL
    if (y > pageHeight - 40) {
      doc.addPage();
      y = 20;
    }

    doc.setFillColor(248, 250, 252);
    doc.setDrawColor(203, 213, 225);
    doc.roundedRect(margin, y, contentWidth, 26, 2, 2, 'FD');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8);
    doc.setTextColor(79, 70, 229);
    doc.text('CONSTANCIA DE ACEPTACIÓN DIGITAL - ORGEVENTOS', margin + 5, y + 6);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7.5);
    doc.setTextColor(55, 65, 81);
    doc.text('Este documento constituye un contrato electrónico válido respaldado por el sistema OrgEventos.', margin + 5, y + 11);
    doc.text('• Método de aceptación: Registro y validación del primer abono (Anticipo) en plataforma.', margin + 5, y + 16);
    doc.text(`• Cliente vinculado: ${contrato.nombreCliente} (ID Sistema: #${contrato.idContrato})`, margin + 5, y + 21);

    doc.save(`Contrato_Oficial_${contrato.idContrato}.pdf`);
  }
}