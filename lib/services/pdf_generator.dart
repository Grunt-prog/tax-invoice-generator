import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

/// Service to generate tax invoice PDFs
class PdfGenerator {
  /// Generate and save a tax invoice PDF to Downloads folder
  static Future<void> generateInvoice(InvoiceModel invoice) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add invoice page to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildInvoiceContent(invoice),
          ],
        ),
      );

      // Generate filename with timestamp
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filename = 'Invoice_${invoice.invoiceNo}_$timestamp.pdf';

      // Get the save directory (no permissions needed for app-specific storage)
      final saveDir = await _getSaveDirectory();
      final filePath = '${saveDir.path}/$filename';

      // Save PDF to file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF
      await OpenFilex.open(filePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Build the complete invoice content
  static pw.Widget _buildInvoiceContent(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title
        pw.Center(
          child: pw.Text(
            'TAX INVOICE',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 12),

        // Header: Seller Info (Left) + Invoice Details (Right)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Seller Information
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SELLER INFORMATION'),
                    _buildText(invoice.companyName ?? ''),
                    _buildText(invoice.proprietorName ?? ''),
                    _buildText(invoice.addressLine1 ?? ''),
                    _buildText(invoice.addressLine2 ?? ''),
                    _buildText(invoice.addressLine3 ?? ''),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildLabelValue('GSTIN:', invoice.gstin ?? ''),
                              _buildLabelValue('State:', invoice.sellerStateName ?? ''),
                              _buildLabelValue('State Code:', invoice.sellerStateCode ?? ''),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _buildLabelValue('Email:', invoice.email ?? ''),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),

            // Right: Invoice Details
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabel('INVOICE DETAILS'),
                    _buildLabelValue('Invoice No:', invoice.invoiceNo ?? ''),
                    _buildLabelValue('Invoice Date:', invoice.invoiceDate ?? ''),
                    if (invoice.motorVehicleNo != null && invoice.motorVehicleNo!.isNotEmpty)
                      _buildLabelValue('Motor Vehicle No:', invoice.motorVehicleNo ?? ''),
                    if (invoice.deliveryNote != null && invoice.deliveryNote!.isNotEmpty)
                      _buildLabelValue('Delivery Note:', invoice.deliveryNote ?? ''),
                    if (invoice.modeOfPayment != null && invoice.modeOfPayment!.isNotEmpty)
                      _buildLabelValue('Mode of Payment:', invoice.modeOfPayment ?? ''),
                    if (invoice.referenceNo != null && invoice.referenceNo!.isNotEmpty)
                      _buildLabelValue('Reference No:', invoice.referenceNo ?? ''),
                    if (invoice.buyerOrderNo != null && invoice.buyerOrderNo!.isNotEmpty)
                      _buildLabelValue('Buyer Order No:', invoice.buyerOrderNo ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Consignee and Buyer side by side
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Consignee
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabel('CONSIGNEE (SHIP TO)'),
                    _buildText(invoice.consigneeName ?? ''),
                    _buildText(invoice.consigneeAddress ?? ''),
                    _buildLabelValue('State:', invoice.consigneeState ?? ''),
                    _buildLabelValue('State Code:', invoice.consigneeStateCode ?? ''),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),

            // Buyer
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildLabel('BUYER (BILL TO)'),
                    _buildText(invoice.buyerName ?? ''),
                    _buildText(invoice.buyerAddress ?? ''),
                    _buildLabelValue('State:', invoice.buyerState ?? ''),
                    _buildLabelValue('State Code:', invoice.buyerStateCode ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Line Items Table
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            // Table Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableHeader('S.No'),
                _buildTableHeader('Description'),
                _buildTableHeader('HSN/SAC'),
                _buildTableHeader('Qty'),
                _buildTableHeader('Rate\n(Incl.Tax)'),
                _buildTableHeader('Rate'),
                _buildTableHeader('Per'),
                _buildTableHeader('Amount'),
              ],
            ),
            // Line Item Row
            pw.TableRow(
              children: [
                _buildTableCell('1'),
                _buildTableCell(invoice.itemDescription ?? ''),
                _buildTableCell(invoice.hsnSac ?? ''),
                _buildTableCell(invoice.quantity ?? ''),
                _buildTableCell(invoice.rateInclTax ?? ''),
                _buildTableCell(invoice.rate ?? ''),
                _buildTableCell(invoice.per ?? ''),
                _buildTableCell(invoice.amount2 ?? ''),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Totals Row
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Total Quantity: ${invoice.totalQuantity ?? ''}',
                    style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    'Total Amount: ${invoice.totalAmount ?? ''}',
                    style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Amount in Words
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            children: [
              pw.Text(
                'Amount in Words: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Expanded(
                child: pw.Text(
                  invoice.amountInWords ?? '',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // GST Summary Table
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(width: 1),
              verticalInside: pw.BorderSide(width: 1),
            ),
            children: [
              // GST Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableHeader('HSN/SAC'),
                  _buildTableHeader('Taxable Value'),
                  _buildTableHeader('GST Rate'),
                  _buildTableHeader('GST Amount'),
                  _buildTableHeader('Total Amount'),
                ],
              ),
              // GST Row
              pw.TableRow(
                children: [
                  _buildTableCell(invoice.gstHsnSac ?? ''),
                  _buildTableCell(invoice.taxableValue ?? ''),
                  _buildTableCell(invoice.gstRate ?? ''),
                  _buildTableCell(invoice.gstAmount ?? ''),
                  _buildTableCell(invoice.gstAmount ?? ''),
                ],
              ),
              // Totals Row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  _buildTableCell(invoice.gstTotalTaxableValue ?? ''),
                  pw.Container(),
                  _buildTableCell(invoice.totalTaxAmount ?? ''),
                  _buildTableCell(invoice.totalTaxAmount ?? ''),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Tax Amount in Words
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            children: [
              pw.Text(
                'Tax Amount in Words: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Expanded(
                child: pw.Text(
                  invoice.taxAmountInWords ?? '',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Declaration and Signature
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Declaration
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DECLARATION',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.declarationText ?? '',
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),

            // Right: Signature
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 32), // Space for signature
                pw.Text(
                  'For ${invoice.signatureCompanyName ?? ''}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Authorised Signatory',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Build a label with bold text
  static pw.Widget _buildLabel(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    );
  }

  /// Build regular text
  static pw.Widget _buildText(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 9),
    );
  }

  /// Build a label-value pair
  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  /// Build table header cell
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build table data cell
  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Get the directory to save invoices.
  /// Uses app-specific external storage which requires NO runtime permissions
  /// on any Android version (including Android 10+ with scoped storage).
  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // App-specific external storage: /storage/emulated/0/Android/data/<pkg>/files/
      // This does NOT require any runtime permissions on any Android version.
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final invoicesDir = Directory('${directory.path}/Invoices');
        if (!await invoicesDir.exists()) {
          await invoicesDir.create(recursive: true);
        }
        return invoicesDir;
      }
    }

    // Fallback for iOS or if external storage is unavailable
    return await getApplicationDocumentsDirectory();
  }
}
