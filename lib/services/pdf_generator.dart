import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class PdfGenerator {
  static Future<pw.ThemeData> _buildTheme() async {
    try {
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
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  static Future<void> generateInvoice(InvoiceModel invoice) async {
    try {
      final InvoiceModel computed = invoice.withCalculations();
      final pdf = pw.Document();
      final theme = await _buildTheme();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          build: (context) => [
            _buildInvoiceContent(computed),
          ],
        ),
      );

      final sanitizedInvoiceNo = (computed.invoiceNo ?? '')
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
    const rupee = '\u20B9';
    final bool isInterState = invoice.isInterState;
    // Half GST rate for CGST/SGST display
    final double gstPct = double.tryParse(invoice.gstRate ?? '') ?? 0;
    final String halfRate = (gstPct / 2).toStringAsFixed(0);

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
                    _detailRow('Invoice No.',
                        invoice.invoiceNo ?? '',
                        'Dated',
                        invoice.invoiceDate ?? '',
                        boldVal1: true, boldVal2: true),
                    _detailRow('Delivery Note',
                        invoice.deliveryNote ?? '',
                        'Mode/Terms of Payment',
                        invoice.modeOfPayment ?? ''),
                    _detailRow('Reference No. & Date.',
                        '${invoice.referenceNo ?? ''}  ${invoice.referenceDate ?? ''}'.trim(),
                        'Other References',
                        invoice.otherReferences ?? ''),
                    _detailRow("Buyer's Order No.",
                        invoice.buyerOrderNo ?? '',
                        'Dated',
                        invoice.buyerOrderDate ?? ''),
                    _detailRow('Dispatch Doc No.',
                        invoice.dispatchDocNo ?? '',
                        'Delivery Note Date',
                        invoice.deliveryNoteDate ?? ''),
                    _detailRow('Dispatched through',
                        invoice.dispatchedThrough ?? '',
                        'Destination',
                        invoice.destination ?? ''),
                    _detailRow('Vessel/Flight No.',
                        invoice.vesselFlightNo ?? '',
                        'Place of receipt by shipper:',
                        invoice.placeOfReceiptByShipper ?? ''),
                    _detailRow('City/Port of Loading',
                        invoice.cityPortOfLoading ?? '',
                        'City/Port of Discharge',
                        invoice.cityPortOfDischarge ?? ''),
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

        // ── Row 2: Consignee | Buyer ────────────────────────────────────────
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
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
                pw.Padding(
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
              ],
            ),
          ],
        ),

        // ── Line Items Table ────────────────────────────────────────────────
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(20),
            1: pw.FlexColumnWidth(4),
            2: pw.FixedColumnWidth(40),
            3: pw.FixedColumnWidth(48),
            4: pw.FixedColumnWidth(44),
            5: pw.FixedColumnWidth(36),
            6: pw.FixedColumnWidth(24),
            7: pw.FixedColumnWidth(52),
          },
          children: [
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
            // Tax row(s) — CGST+SGST or IGST
            if (!isInterState) ...[
              pw.TableRow(children: [
                _tcPad(''),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: pw.Text('Sgst',
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, fontSize: 9)),
                ),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcRPad(invoice.sgstAmount ?? ''),
              ]),
              pw.TableRow(children: [
                _tcPad(''),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 20),
                  child: pw.Text('Cgst',
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, fontSize: 9)),
                ),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcRPad(invoice.cgstAmount ?? ''),
              ]),
            ] else ...[
              pw.TableRow(children: [
                _tcPad(''),
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 40),
                  child: pw.Text('Igst',
                      style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic, fontSize: 9)),
                ),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcPad(''),
                _tcRPad(invoice.igstAmount ?? ''),
              ]),
            ],
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

        // ── Tax Summary Table — CGST+SGST or IGST ──────────────────────────
        if (!isInterState) ...[
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1.5),
              6: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(children: [
                _th('HSN/SAC'),
                _th('Taxable\nValue'),
                _th('CGST\nRate'),
                _th('CGST\nAmount'),
                _th('SGST/UTGST\nRate'),
                _th('SGST/UTGST\nAmount'),
                _th('Total\nTax Amount'),
              ]),
              pw.TableRow(children: [
                _tc(invoice.gstHsnSac ?? ''),
                _tcR(invoice.taxableValue ?? ''),
                _tc('$halfRate%'),
                _tcR(invoice.cgstAmount ?? ''),
                _tc('$halfRate%'),
                _tcR(invoice.sgstAmount ?? ''),
                _tcR(invoice.totalTaxAmount ?? ''),
              ]),
              pw.TableRow(children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Total',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    invoice.gstTotalTaxableValue ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                _tc(''),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    invoice.cgstAmount ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                _tc(''),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    invoice.sgstAmount ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
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
        ] else ...[
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
                _tc('${invoice.gstRate ?? ''}%'),
                _tcR(invoice.igstAmount ?? ''),
                _tcR(invoice.totalTaxAmount ?? ''),
              ]),
              pw.TableRow(children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Total',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    invoice.gstTotalTaxableValue ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                _tc(''),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    invoice.igstAmount ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
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
        ],

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

        // ── Declaration + Bank Details + Signature ──────────────────────────
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Declaration (left)
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
              // Bank Details + Signature (right)
              pw.Container(
                width: 170,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Company's Bank Details",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    pw.SizedBox(height: 3),
                    _bankRow("A/c Holder's Name",
                        invoice.bankAccountHolderName ?? ''),
                    _bankRow('Bank Name', invoice.bankName ?? ''),
                    _bankRow('A/C No.', invoice.bankAccountNo ?? ''),
                    _bankRow('Branch & IFS Code',
                        invoice.bankBranchIfsc ?? ''),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'for ${invoice.signatureCompanyName ?? ''}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.SizedBox(height: 35),
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

  static pw.Widget _bankRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
                text: '$label : ',
                style: const pw.TextStyle(fontSize: 8)),
            pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 8)),
          ]),
        ),
      );

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
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            textAlign: pw.TextAlign.center),
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

  static pw.Widget _tcPad(String text) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center),
      );

  static pw.Widget _tcRPad(String text) => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: pw.Text(text,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right),
      );

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