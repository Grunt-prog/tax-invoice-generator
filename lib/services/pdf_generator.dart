import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

/// Service to generate tax invoice PDFs
class PdfGenerator {
  /// Generate and save a tax invoice PDF
  static Future<void> generateInvoice(InvoiceModel invoice) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildInvoiceContent(invoice),
          ],
        ),
      );

      // Sanitize invoice number to avoid path issues with slashes
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

        // ── Seller Info (left) + Invoice Details table (right) ─────────────
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
                      _txt(invoice.addressLine2 ?? ''),
                      _txt(invoice.addressLine3 ?? ''),
                      pw.SizedBox(height: 4),
                      _txt('GSTIN/UIN: ${invoice.gstin ?? ''}'),
                      _txt(
                          'State Name : ${invoice.sellerStateName ?? ''}, Code : ${invoice.sellerStateCode ?? ''}'),
                      _txt('E-Mail : ${invoice.email ?? ''}'),
                    ],
                  ),
                ),
              ),

              // Right: Invoice detail rows in a 4-column table
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
                    _detailRow('Invoice No.',
                        invoice.invoiceNo ?? '', 'Dated',
                        invoice.invoiceDate ?? '',
                        boldVal1: true, boldVal2: true),
                    _detailRow('Delivery Note',
                        invoice.deliveryNote ?? '',
                        'Mode/Terms of Payment',
                        invoice.modeOfPayment ?? ''),
                    _detailRow('Reference No. & Date.',
                        invoice.referenceNo ?? '',
                        'Other References',
                        invoice.otherReferences ?? ''),
                    _detailRow("Buyer's Order No.",
                        invoice.buyerOrderNo ?? '', 'Dated',
                        invoice.buyerOrderDate ?? ''),
                    _detailRow('Dispatch Doc No.',
                        invoice.dispatchDocNo ?? '',
                        'Delivery Note Date',
                        invoice.deliveryNoteDate ?? ''),
                    _detailRow('Dispatched through',
                        invoice.dispatchedThrough ?? '', 'Destination',
                        invoice.destination ?? ''),
                    _detailRow('Bill of Lading/LR-RR No.',
                        invoice.billOfLading ?? '',
                        'Motor Vehicle No.',
                        invoice.motorVehicleNo ?? '',
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

        // ── Consignee + Buyer ───────────────────────────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
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
              ),
              pw.Expanded(
                child: pw.Container(
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
              ),
            ],
          ),
        ),

        // ── Line Items Table ────────────────────────────────────────────────
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(24),
            1: pw.FlexColumnWidth(3),
            2: pw.FixedColumnWidth(44),
            3: pw.FixedColumnWidth(48),
            4: pw.FixedColumnWidth(46),
            5: pw.FixedColumnWidth(38),
            6: pw.FixedColumnWidth(28),
            7: pw.FixedColumnWidth(54),
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
              _tc('1'),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  invoice.itemDescription ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              ),
              _tc(invoice.hsnSac ?? ''),
              _tc('${invoice.quantity ?? ''} ${invoice.quantityUnit ?? ''}'),
              _tc(invoice.rateInclTax ?? ''),
              _tc(invoice.rate ?? ''),
              _tc(invoice.per ?? ''),
              _tcR(invoice.amount2 ?? ''),
            ]),
            // IGST row
            pw.TableRow(children: [
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'Igst',
                  style:
                      pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9),
                ),
              ),
              _tc(''),
              _tc(''),
              _tc(''),
              _tc(''),
              _tc(''),
              _tcR(invoice.gstAmount ?? ''),
            ]),
            // Total row
            pw.TableRow(children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Total',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              _tc(''),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  invoice.totalQuantity ?? '',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              _tc(''),
              _tc(''),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  '₹ ${invoice.totalAmount ?? ''}',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
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
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                      text: 'Amount Chargeable (in words)\n',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.TextSpan(
                      text: invoice.amountInWords ?? '',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                  ]),
                ),
              ),
              _txt('E. & O.E'),
            ],
          ),
        ),

        pw.SizedBox(height: 6),

        // ── GST / IGST Summary Table ────────────────────────────────────────
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
            // Header
            pw.TableRow(children: [
              _th('HSN/SAC'),
              _th('Taxable\nValue'),
              _th('IGST\nRate'),
              _th('IGST\nAmount'),
              _th('Total\nTax Amount'),
            ]),
            // Data row
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
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Total',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  invoice.gstTotalTaxableValue ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              _tc(''),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  invoice.totalTaxAmount ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  invoice.totalTaxAmount ?? '',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                  textAlign: pw.TextAlign.right,
                ),
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
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                text: 'Tax Amount (in words) :  ',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.TextSpan(
                text: invoice.taxAmountInWords ?? '',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
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

  // ── Invoice detail table helpers ──────────────────────────────────────────

  static pw.TableRow _detailRow(
    String label1, String val1, String label2, String val2, {
    bool boldVal1 = false,
    bool boldVal2 = false,
  }) {
    return pw.TableRow(children: [
      _detailCell(label1),
      _detailCell(val1, bold: boldVal1),
      _detailCell(label2),
      _detailCell(val2, bold: boldVal2),
    ]);
  }

  static pw.Widget _detailCell(String text, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: bold
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)
            : const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  // ── General helpers ───────────────────────────────────────────────────────

  static pw.Widget _txt(String text) =>
      pw.Text(text, style: const pw.TextStyle(fontSize: 9));

  static pw.Widget _th(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      );

  static pw.Widget _tc(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center),
      );

  static pw.Widget _tcR(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(4),
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