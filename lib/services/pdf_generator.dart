import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

/// Service to generate tax invoice PDFs
class PdfGenerator {
  /// Load fonts that support the ₹ (Rupee) symbol
  static Future<pw.ThemeData> _buildTheme() async {
    final regularData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final italicData =
        await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');

    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
      italic: pw.Font.ttf(italicData),
    );
  }

  /// Generate and save a tax invoice PDF
  static Future<void> generateInvoice(InvoiceModel invoice) async {
    try {
      final pdf = pw.Document();
      final theme = await _buildTheme();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          build: (context) => [
            _buildInvoiceContent(invoice),
          ],
        ),
      );

      // Sanitize invoice number — slashes break the file path
      final sanitizedInvoiceNo = (invoice.invoiceNo ?? '')
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .replaceAll(' ', '_');
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filename = 'Invoice_${sanitizedInvoiceNo}_$timestamp.pdf';

      final saveDir = await _getSaveDirectory();
      final filePath = '${saveDir.path}/$filename';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await OpenFilex.open(filePath);
    } catch (e) {
      rethrow;
    }
  }

  static pw.Widget _buildInvoiceContent(InvoiceModel invoice) {
    // Rupee symbol via explicit Unicode codepoint — avoids encoding issues
    const rupee = '\u20B9';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Title ──────────────────────────────────────────────────────────
        pw.Center(
          child: pw.Text(
            'Tax Invoice',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),

        // ── Row 1: Seller Info (left) | Invoice Details table (right) ──────
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Seller Info
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        invoice.companyName ?? '',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      _txt(invoice.proprietorName ?? ''),
                      _txt(invoice.addressLine1 ?? ''),
                      pw.SizedBox(height: 4),
                      _txt('GSTIN/UIN: ${invoice.gstin ?? ''}'),
                      _txt(
                          'State Name : ${invoice.sellerStateName ?? ''}, Code : ${invoice.sellerStateCode ?? ''}'),
                      _txt('E-Mail : ${invoice.email ?? ''}'),
                    ],
                  ),
                ),
              ),

              // Right: Invoice detail rows
              pw.Expanded(
                flex: 6,
                child: pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(width: 0.5),
                    verticalInside: pw.BorderSide(width: 0.5),
                  ),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(2),
                  },
                  children: [
                    _detailRow('Invoice No.', invoice.invoiceNo ?? '',
                        'Dated', invoice.invoiceDate ?? '',
                        boldVal1: true, boldVal2: true),
                    _detailRow('Delivery Note', invoice.deliveryNote ?? '',
                        'Mode/Terms of Payment', invoice.modeOfPayment ?? ''),
                    _detailRow('Reference No. & Date.',
                        invoice.referenceNo ?? '',
                        'Other References', invoice.otherReferences ?? ''),
                    _detailRow("Buyer's Order No.",
                        invoice.buyerOrderNo ?? '',
                        'Dated', invoice.buyerOrderDate ?? ''),
                    _detailRow('Dispatch Doc No.',
                        invoice.dispatchDocNo ?? '',
                        'Delivery Note Date', invoice.deliveryNoteDate ?? ''),
                    _detailRow('Dispatched through',
                        invoice.dispatchedThrough ?? '',
                        'Destination', invoice.destination ?? ''),
                    _detailRow('Bill of Lading/LR-RR No.',
                        invoice.billOfLading ?? '',
                        'Motor Vehicle No.', invoice.motorVehicleNo ?? '',
                        boldVal2: true),
                    pw.TableRow(children: [
                      _detailCell('Terms of Delivery'),
                      _detailCell(invoice.termsOfDelivery ?? ''),
                      pw.Container(),
                      pw.Container(),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Row 2: Consignee (Ship to) — full width ─────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _txt('Consignee (Ship to)'),
              pw.Text(
                invoice.consigneeName ?? '',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              _txt(invoice.consigneeAddress ?? ''),
              _txt(
                  'State Name    : ${invoice.consigneeState ?? ''}, Code : ${invoice.consigneeStateCode ?? ''}'),
            ],
          ),
        ),

        // ── Row 3: Buyer (Bill to) — full width ────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _txt('Buyer (Bill to)'),
              pw.Text(
                invoice.buyerName ?? '',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              _txt(invoice.buyerAddress ?? ''),
              _txt(
                  'State Name    : ${invoice.buyerState ?? ''}, Code : ${invoice.buyerStateCode ?? ''}'),
            ],
          ),
        ),

        // ── Line Items Table ────────────────────────────────────────────────
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(20),   // Sl
            1: pw.FlexColumnWidth(4),     // Description — widest column
            2: pw.FixedColumnWidth(40),   // HSN/SAC
            3: pw.FixedColumnWidth(48),   // Quantity
            4: pw.FixedColumnWidth(44),   // Rate (Incl. of Tax)
            5: pw.FixedColumnWidth(36),   // Rate
            6: pw.FixedColumnWidth(24),   // per
            7: pw.FixedColumnWidth(52),   // Amount
          },
          children: [
            // Header row
            pw.TableRow(children: [
              _th('Sl\n%'),
              _th('Description of Goods'),
              _th('HSN/SAC'),
              _th('Quantity'),
              _th('Rate\n(Incl. of Tax)'),
              _th('Rate'),
              _th('per'),
              _th('Amount'),
            ]),
            // Item row
            pw.TableRow(children: [
              _tcPad('1'),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
                child: pw.Text(
                  invoice.itemDescription ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              ),
              _tcPad(invoice.hsnSac ?? ''),
              _tcPad(
                  '${invoice.quantity ?? ''} ${invoice.quantityUnit ?? ''}'),
              _tcPad(invoice.rateInclTax ?? ''),
              _tcPad(invoice.rate ?? ''),
              _tcPad(invoice.per ?? ''),
              _tcRPad(invoice.amount2 ?? ''),
            ]),
            // IGST row — extra bottom padding for spacing
            pw.TableRow(children: [
              _tcPad(''),
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 40),
                child: pw.Text(
                  'Igst',
                  style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic, fontSize: 9),
                ),
              ),
              _tcPad(''),
              _tcPad(''),
              _tcPad(''),
              _tcPad(''),
              _tcPad(''),
              _tcRPad(invoice.gstAmount ?? ''),
            ]),
            // Total row
            pw.TableRow(children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('Total',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              _tc(''),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  invoice.totalQuantity ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              _tc(''),
              _tc(''),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  // Use \u20B9 (explicit Unicode) instead of literal ₹
                  // to avoid font-encoding issues in some PDF renderers
                  '$rupee ${invoice.totalAmount ?? ''}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ]),
          ],
        ),

        // ── Amount in Words ─────────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _txt('Amount Chargeable (in words)'),
                    pw.Text(
                      invoice.amountInWords ?? '',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                  ],
                ),
              ),
              _txt('E. & O.E'),
            ],
          ),
        ),

        pw.SizedBox(height: 6),

        // ── IGST Summary Table ──────────────────────────────────────────────
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(children: [
              _th('HSN/SAC'),
              _th('Taxable\nValue'),
              _th('IGST\nRate'),
              _th('IGST\nAmount'),
              _th('Total\nTax Amount'),
            ]),
            pw.TableRow(children: [
              _tc(invoice.gstHsnSac ?? ''),
              _tcR(invoice.taxableValue ?? ''),
              _tc(invoice.gstRate ?? ''),
              _tcR(invoice.gstAmount ?? ''),
              _tcR(invoice.totalTaxAmount ?? ''),
            ]),
            // Total row
            pw.TableRow(children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Total',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(invoice.gstTotalTaxableValue ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right),
              ),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(invoice.totalTaxAmount ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(invoice.totalTaxAmount ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right),
              ),
            ]),
          ],
        ),

        // ── Tax Amount in Words ─────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                  text: 'Tax Amount (in words) :  ',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.TextSpan(
                  text: invoice.taxAmountInWords ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ]),
          ),
        ),

        pw.SizedBox(height: 6),

        // ── Declaration + Signature ─────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Declaration',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.declarationText ?? '',
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 140,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'for ${invoice.signatureCompanyName ?? ''}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text('Authorised Signatory',
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 6),

        // ── Footer ──────────────────────────────────────────────────────────
        pw.Center(
          child: pw.Text(
            'This is a Computer Generated Invoice',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.TableRow _detailRow(
    String l1, String v1, String l2, String v2, {
    bool boldVal1 = false,
    bool boldVal2 = false,
  }) =>
      pw.TableRow(children: [
        _detailCell(l1),
        _detailCell(v1, bold: boldVal1),
        _detailCell(l2),
        _detailCell(v2, bold: boldVal2),
      ]);

  static pw.Widget _detailCell(String text, {bool bold = false}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: bold
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)
                : const pw.TextStyle(fontSize: 8)),
      );

  static pw.Widget _txt(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 9));

  static pw.Widget _th(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            textAlign: pw.TextAlign.center),
      );

  // Normal centered cell
  static pw.Widget _tc(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center),
      );

  // Right-aligned cell
  static pw.Widget _tcR(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right),
      );

  // Tall padded centered cell (for item rows spacing)
  static pw.Widget _tcPad(String text) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center),
      );

  // Tall padded right-aligned cell
  static pw.Widget _tcRPad(String text) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right),
      );

  /// Get save directory — app-specific, no runtime permissions needed
  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final invoicesDir = Directory('${directory.path}/Invoices');
        if (!await invoicesDir.exists()) {
          await invoicesDir.create(recursive: true);
        }
        return invoicesDir;
      }
    }
    return await getApplicationDocumentsDirectory();
  }
}