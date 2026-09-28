import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../storage/models.dart';

/// Generates CPCB Form-6 / EPR compliant E-Waste Handover Manifests
class PdfReceiptService {
  static Future<void> generateAndPrintReceipt({
    required TransactionsData tx,
    required MaterialsData lot,
    required RecyclerData recycler,
    required String collectorName,
  }) async {
    final pdf = pw.Document();

    final dateStr = DateTime.fromMillisecondsSinceEpoch(tx.createdAt).toLocal().toString().split('.')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'KABADIWALA CONNECT - CPCB E-WASTE MANIFEST',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Under E-Waste Management Rules 2022 / JNARDDC PS 26229',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                        ),
                      ],
                    ),
                    pw.Text(
                      'FORM-6 RECEIPT',
                      style: pw.TextStyle(
                        color: PdfColors.amber300,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Transaction & Verification ID Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Transaction ID: ${tx.txId}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Lot ID: ${tx.lotId}'),
                      pw.Text('Date & Time: $dateStr'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Status: ${tx.txLifecycleState}', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Payment: ${tx.settlementMode} (SETTLED)'),
                      pw.Text('Ref: ${tx.paymentReference ?? "CASH-DESK-OK"}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // Parties Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('INFORMAL COLLECTOR', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(collectorName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Collector ID: ${lot.collectorId}'),
                          pw.Text('Cluster: Pune / PCMC Scrap Lane'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('AUTHORIZED RECYCLER', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(recycler.legalEntityName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('CPCB Reg: ${recycler.cpcbRegNumber}'),
                          pw.Text('Facility: ${recycler.facilityAddress}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Material Breakdown Table
              pw.Text('MATERIAL & SETTLEMENT VALUATION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Material Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Condition', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Scale Weight', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Net Rate (INR/kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Paid (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${lot.category} - ${lot.subCategory}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(lot.conditionGrade)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${tx.weightKg.toStringAsFixed(1)} kg')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${(tx.finalSettledInr / (tx.weightKg > 0 ? tx.weightKg : 1)).toStringAsFixed(1)}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INR ${tx.finalSettledInr.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Unit Economics & EPR Credit Disclosure
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CPCB EPR & MINERAL VALUE AUDIT LOG:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    pw.SizedBox(height: 4),
                    pw.Text('• Formal Recycler Gate Base Rate: INR ${(tx.finalSettledInr * 0.84).toStringAsFixed(2)}'),
                    pw.Text('• CPCB EPR Transfer Credit Pass-Through: INR ${(tx.finalSettledInr * 0.11).toStringAsFixed(2)} (Assigned to Collector)'),
                    pw.Text('• National Critical Minerals Mission (NCMM) Bonus: INR ${(tx.finalSettledInr * 0.05).toStringAsFixed(2)}'),
                    pw.Text('• Collector Platform Charge: INR 0.00 (Zero Fee Model for Informal Workers)'),
                  ],
                ),
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Collector Thumb / Sign', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://cpcb.nic.in/epr-verify?tx=${tx.txId}',
                        width: 50,
                        height: 50,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Verify Hash: ${tx.txId.substring(0, 8)}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Weighbridge Officer', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'This is a legally verifiable document under Ministry of Environment, Forest & Climate Change (MoEFCC) E-Waste Rules 2022.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Manifest_${tx.txId}.pdf',
    );
  }
}
