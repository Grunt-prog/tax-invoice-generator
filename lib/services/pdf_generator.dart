import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class PdfGenerator {
  // Uses the pdf package's built-in Helvetica fonts.
  // Custom TTF files (NotoSans) crash TtfParser._parseCMap in pdf 3.10.x
  // because NotoSans uses a complex cmap-12 Unicode table not fully supported.
  static Future<pw.ThemeData> _buildTheme() async {
    return pw.ThemeData.base();
  }

  static Future<void> generateInvoice(InvoiceModel invoice) async {
    final InvoiceModel computed = invoice.withCalculations();
    final pdf = pw.Document();
    final theme = await _buildTheme();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(14),
        theme: theme,
        build: (context) => _buildInvoiceContent(computed),
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
  }

  static List<pw.Widget> _buildInvoiceContent(InvoiceModel invoice) {
    const rupee = 'Rs.';
    final bool inter = invoice.isInterState;
    // FIX: guard gstRate with null-safe parse before using
    final double gstPct = double.tryParse(invoice.gstRate ?? '0') ?? 0;
    final String halfRate = (gstPct / 2).toStringAsFixed(0);

    // ── Build line-item table rows ──────────────────────────────────────────
    final List<pw.TableRow> lineItemRows = [];

    // Header
    lineItemRows.add(pw.TableRow(children: [
      _th('Description of Goods'),
      _th('HSN/SAC'),
      _th('Quantity'),
      _th('Rate\n(Incl. of Tax)'),
      _th('Rate'),
      _th('per'),
      _th('Amount'),
    ]));

    // Item
    lineItemRows.add(pw.TableRow(children: [
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: pw.Text(
          invoice.itemDescription ?? '',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      _tcPad(invoice.hsnSac ?? ''),
      _tcPad('${invoice.quantity ?? ''} ${invoice.quantityUnit ?? ''}'),
      _tcPad(invoice.rateInclTax ?? ''),
      _tcPad(invoice.rate ?? ''),
      _tcPad(invoice.per ?? ''),
      _tcRPad(invoice.amount2 ?? ''),
    ]));

    // Tax row(s)
    if (!inter) {
      lineItemRows.add(pw.TableRow(children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: pw.Text('SGST',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcRPad(invoice.sgstAmount ?? ''),
      ]));
      lineItemRows.add(pw.TableRow(children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: pw.Text('CGST',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcRPad(invoice.cgstAmount ?? ''),
      ]));
    } else {
      lineItemRows.add(pw.TableRow(children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: pw.Text('IGST',
              style: const pw.TextStyle(fontSize: 9)),
        ),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcPad(''),
        _tcRPad(invoice.igstAmount ?? ''),
      ]));
    }

    // Total
    lineItemRows.add(pw.TableRow(children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text('Total',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
      ),
      _tc(''),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          invoice.totalQuantity ?? '',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
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
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          textAlign: pw.TextAlign.right,
        ),
      ),
    ]));

    // ── Tax summary table ───────────────────────────────────────────────────
    final pw.Widget taxSummaryTable = inter
        ? _buildIgstTable(invoice)
        : _buildCgstSgstTable(invoice, halfRate);

    // ── Page content ────────────────────────────────────────────────────────
    final List<pw.Widget> pageWidgets = [];

    pageWidgets.add(pw.Center(
      child: pw.Text(
        'Tax Invoice',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    ));
    pageWidgets.add(pw.SizedBox(height: 2));

    // Seller + invoice detail rows
    pageWidgets.add(pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
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
                  pw.Text(invoice.companyName ?? '',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              children: [
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(width: 0.5),
                    bottom: pw.BorderSide(width: 0.5),
                    left: pw.BorderSide(width: 0.5),
                    right: pw.BorderSide(width: 0.5),
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
                    _detailRow(
                        'Reference No. & Date.',
                        '${invoice.referenceNo ?? ''}  ${invoice.referenceDate ?? ''}'.trim(),
                        'Other References',
                        invoice.otherReferences ?? ''),
                    _detailRow("Buyer's Order No.", invoice.buyerOrderNo ?? '',
                        'Dated', invoice.buyerOrderDate ?? ''),
                    _detailRow('Dispatch Doc No.', invoice.dispatchDocNo ?? '',
                        'Delivery Note Date', invoice.deliveryNoteDate ?? ''),
                    _detailRow('Dispatched through',
                        invoice.dispatchedThrough ?? '',
                        'Destination', invoice.destination ?? ''),
                    _detailRow('Vessel/Flight No.', invoice.vesselFlightNo ?? '',
                        'Place of receipt by shipper:',
                        invoice.placeOfReceiptByShipper ?? ''),
                    _detailRow('City/Port of Loading',
                        invoice.cityPortOfLoading ?? '',
                        'City/Port of Discharge',
                        invoice.cityPortOfDischarge ?? ''),
                    _detailRow('Bill of Lading/LR-RR No.',
                        invoice.billOfLading ?? '',
                        'Motor Vehicle No.',
                        invoice.motorVehicleNo ?? ''),
                  ],
                ),
                // Terms of Delivery – single full-width cell
                pw.Container(
                  height: 40,
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(width: 0.5),
                      right: pw.BorderSide(width: 0.5),
                      bottom: pw.BorderSide(width: 0.5),
                    ),
                  ),
                  child: pw.Text('Terms of Delivery',
                      style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    // Consignee + Buyer
    pageWidgets.add(pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _txt('Consignee (Ship to)'),
                pw.Text(invoice.consigneeName ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
                pw.Text(invoice.buyerName ?? '',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10)),
                _txt(invoice.buyerAddress ?? ''),
                _txt(
                    'State Name    : ${invoice.buyerState ?? ''}, Code : ${invoice.buyerStateCode ?? ''}'),
              ],
            ),
          ),
        ]),
      ],
    ));

    // Line items table
    pageWidgets.add(pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(width: 0.5),
          verticalInside: pw.BorderSide(width: 0.5),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(4),
          1: pw.FixedColumnWidth(40),
          2: pw.FixedColumnWidth(48),
          3: pw.FixedColumnWidth(44),
          4: pw.FixedColumnWidth(36),
          5: pw.FixedColumnWidth(24),
          6: pw.FixedColumnWidth(52),
        },
        children: lineItemRows,
      ),
    ));

    // Amount in words
    pageWidgets.add(pw.Container(
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
    ));

    pageWidgets.add(pw.SizedBox(height: 2));

    // Tax summary table
    pageWidgets.add(taxSummaryTable);

    // Tax amount in words
    pageWidgets.add(pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(width: 0.5),
          right: pw.BorderSide(width: 0.5),
          bottom: pw.BorderSide(width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Row(
        children: [
          pw.Text(
            'Tax Amount (in words) :  ',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Expanded(
            child: pw.Text(
              invoice.taxAmountInWords ?? '',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
        ],
      ),
    ));

    pageWidgets.add(pw.SizedBox(height: 2));

    // Declaration + bank + signature (Table ensures equal-height cells & solid borders)
    pageWidgets.add(pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FixedColumnWidth(170),
      },
      children: [
        pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
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
          pw.Padding(
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
                _bankRow('Branch & IFS Code', invoice.bankBranchIfsc ?? ''),
                pw.SizedBox(height: 8),
                pw.Text(
                  'for ${invoice.signatureCompanyName ?? ''}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Authorised Signatory',
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ]),
      ],
    ));

    pageWidgets.add(pw.SizedBox(height: 2));

    pageWidgets.add(pw.Center(
      child: pw.Text(
        'This is a Computer Generated Invoice',
        style: const pw.TextStyle(fontSize: 8),
      ),
    ));

    return pageWidgets;
  }

  // ── Tax summary table builders ─────────────────────────────────────────────

  static pw.Widget _buildCgstSgstTable(InvoiceModel inv, String halfRate) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(width: 0.5),
          verticalInside: pw.BorderSide(width: 0.5),
        ),
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
          _tc(inv.gstHsnSac ?? ''),
          _tcR(inv.taxableValue ?? ''),
          _tc('$halfRate%'),
          _tcR(inv.cgstAmount ?? ''),
          _tc('$halfRate%'),
          _tcR(inv.sgstAmount ?? ''),
          _tcR(inv.totalTaxAmount ?? ''),
        ]),
        pw.TableRow(children: [
          _boldCell('Total'),
          _boldRCell(inv.gstTotalTaxableValue ?? ''),
          _tc(''),
          _boldRCell(inv.cgstAmount ?? ''),
          _tc(''),
          _boldRCell(inv.sgstAmount ?? ''),
          _boldRCell(inv.totalTaxAmount ?? ''),
        ]),
      ],
      ),  // Close pw.Table
    );  // Close pw.Container
  }

  static pw.Widget _buildIgstTable(InvoiceModel inv) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(width: 0.5),
          verticalInside: pw.BorderSide(width: 0.5),
        ),
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
          _tc(inv.gstHsnSac ?? ''),
          _tcR(inv.taxableValue ?? ''),
          _tc('${inv.gstRate ?? ''}%'),
          _tcR(inv.igstAmount ?? ''),
          _tcR(inv.totalTaxAmount ?? ''),
        ]),
        pw.TableRow(children: [
          _boldCell('Total'),
          _boldRCell(inv.gstTotalTaxableValue ?? ''),
          _tc(''),
          _boldRCell(inv.igstAmount ?? ''),
          _boldRCell(inv.totalTaxAmount ?? ''),
        ]),
      ],
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  static pw.Widget _boldCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
      );

  static pw.Widget _boldRCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            textAlign: pw.TextAlign.right),
      );

  static pw.Widget _bankRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          children: [
            pw.Text(
              '$label : ',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
            ),
          ],
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
      try {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final invoicesDir = Directory('${directory.path}/Invoices');
          if (!await invoicesDir.exists()) {
            await invoicesDir.create(recursive: true);
          }
          return invoicesDir;
        }
      } catch (_) {
        // fall through
      }
    }
    return getApplicationDocumentsDirectory();
  }
}