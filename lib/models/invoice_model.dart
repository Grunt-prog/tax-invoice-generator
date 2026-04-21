/// Model for a Tax Invoice.
///
/// Fields the USER fills in the form:
///   - All seller/buyer/consignee info
///   - invoiceNo, invoiceDate, motorVehicleNo, etc.
///   - itemDescription, hsnSac, quantity, quantityUnit, rateInclTax, rate, per
///   - gstRate  (IGST % — e.g. "18")
///   - gstHsnSac
///   - declarationText, signatureCompanyName
///
/// Fields that are AUTO-CALCULATED (never shown in the form UI):
///   - amount2          = rate × quantity
///   - gstAmount        = (amount2 × gstRate) / 100
///   - totalAmount      = amount2 + gstAmount
///   - taxableValue     = amount2  (pre-tax value)
///   - totalTaxAmount   = gstAmount
///   - gstTotalTaxableValue = taxableValue (summary table total)
///   - totalQuantity    = quantity + unit (display string)
///   - amountInWords    = totalAmount in words (INR ... Only)
///   - taxAmountInWords = gstAmount in words (INR ... Only)
class InvoiceModel {
  // ── Seller ────────────────────────────────────────────────────────────────
  final String? companyName;
  final String? proprietorName;
  final String? addressLine1;
  final String? gstin;
  final String? sellerStateName;
  final String? sellerStateCode;
  final String? email;

  // ── Invoice Meta ──────────────────────────────────────────────────────────
  final String? invoiceNo;
  final String? invoiceDate;
  final String? deliveryNote;
  final String? modeOfPayment;
  final String? referenceNo;
  final String? otherReferences;
  final String? buyerOrderNo;
  final String? buyerOrderDate;
  final String? dispatchDocNo;
  final String? deliveryNoteDate;
  final String? dispatchedThrough;
  final String? destination;
  final String? billOfLading;
  final String? motorVehicleNo;
  final String? termsOfDelivery;

  // ── Consignee ─────────────────────────────────────────────────────────────
  final String? consigneeName;
  final String? consigneeAddress;
  final String? consigneeState;
  final String? consigneeStateCode;

  // ── Buyer ─────────────────────────────────────────────────────────────────
  final String? buyerName;
  final String? buyerAddress;
  final String? buyerState;
  final String? buyerStateCode;

  // ── Line Item (user-entered) ───────────────────────────────────────────────
  final String? itemDescription;
  final String? hsnSac;
  final String? quantity;       // numeric string e.g. "400"
  final String? quantityUnit;   // e.g. "sqf"
  final String? rateInclTax;    // display only
  final String? rate;           // numeric string e.g. "60"
  final String? per;            // e.g. "sqf"

  // ── GST (user-entered) ────────────────────────────────────────────────────
  final String? gstHsnSac;
  final String? gstRate;        // numeric string e.g. "18"

  // ── Auto-calculated (DO NOT show in UI) ───────────────────────────────────
  final String? amount2;             // rate × quantity
  final String? gstAmount;           // amount2 × gstRate / 100
  final String? totalAmount;         // amount2 + gstAmount
  final String? taxableValue;        // same as amount2
  final String? totalTaxAmount;      // same as gstAmount
  final String? gstTotalTaxableValue;// same as taxableValue (summary total row)
  final String? totalQuantity;       // "400 sqf"
  final String? amountInWords;       // total in words
  final String? taxAmountInWords;    // gst in words

  // ── Declaration ───────────────────────────────────────────────────────────
  final String? declarationText;
  final String? signatureCompanyName;

  const InvoiceModel({
    this.companyName,
    this.proprietorName,
    this.addressLine1,
    this.gstin,
    this.sellerStateName,
    this.sellerStateCode,
    this.email,
    this.invoiceNo,
    this.invoiceDate,
    this.deliveryNote,
    this.modeOfPayment,
    this.referenceNo,
    this.otherReferences,
    this.buyerOrderNo,
    this.buyerOrderDate,
    this.dispatchDocNo,
    this.deliveryNoteDate,
    this.dispatchedThrough,
    this.destination,
    this.billOfLading,
    this.motorVehicleNo,
    this.termsOfDelivery,
    this.consigneeName,
    this.consigneeAddress,
    this.consigneeState,
    this.consigneeStateCode,
    this.buyerName,
    this.buyerAddress,
    this.buyerState,
    this.buyerStateCode,
    this.itemDescription,
    this.hsnSac,
    this.quantity,
    this.quantityUnit,
    this.rateInclTax,
    this.rate,
    this.per,
    this.gstHsnSac,
    this.gstRate,
    // auto-calculated — normally leave null, call withCalculations()
    this.amount2,
    this.gstAmount,
    this.totalAmount,
    this.taxableValue,
    this.totalTaxAmount,
    this.gstTotalTaxableValue,
    this.totalQuantity,
    this.amountInWords,
    this.taxAmountInWords,
    this.declarationText,
    this.signatureCompanyName,
  });

  /// Returns a new [InvoiceModel] with all calculated fields populated.
  /// Call this BEFORE passing the model to [PdfGenerator.generateInvoice].
  ///
  /// Example:
  ///   final ready = invoice.withCalculations();
  ///   await PdfGenerator.generateInvoice(ready);
  InvoiceModel withCalculations() {
    // Parse user-entered numeric strings safely
    final double qty = double.tryParse(quantity ?? '') ?? 0;
    final double rt = double.tryParse(rate ?? '') ?? 0;
    final double gstPct = double.tryParse(gstRate ?? '') ?? 0;

    final double calcAmount = qty * rt;
    final double calcGst = (calcAmount * gstPct) / 100;
    final double calcTotal = calcAmount + calcGst;

    final String fmtAmount = _fmt(calcAmount);
    final String fmtGst = _fmt(calcGst);
    final String fmtTotal = _fmt(calcTotal);
    final String fmtQty = '${_fmtQty(qty)} ${quantityUnit ?? ''}'.trim();

    return InvoiceModel(
      // copy all user-entered fields unchanged
      companyName: companyName,
      proprietorName: proprietorName,
      addressLine1: addressLine1,
      gstin: gstin,
      sellerStateName: sellerStateName,
      sellerStateCode: sellerStateCode,
      email: email,
      invoiceNo: invoiceNo,
      invoiceDate: invoiceDate,
      deliveryNote: deliveryNote,
      modeOfPayment: modeOfPayment,
      referenceNo: referenceNo,
      otherReferences: otherReferences,
      buyerOrderNo: buyerOrderNo,
      buyerOrderDate: buyerOrderDate,
      dispatchDocNo: dispatchDocNo,
      deliveryNoteDate: deliveryNoteDate,
      dispatchedThrough: dispatchedThrough,
      destination: destination,
      billOfLading: billOfLading,
      motorVehicleNo: motorVehicleNo,
      termsOfDelivery: termsOfDelivery,
      consigneeName: consigneeName,
      consigneeAddress: consigneeAddress,
      consigneeState: consigneeState,
      consigneeStateCode: consigneeStateCode,
      buyerName: buyerName,
      buyerAddress: buyerAddress,
      buyerState: buyerState,
      buyerStateCode: buyerStateCode,
      itemDescription: itemDescription,
      hsnSac: hsnSac,
      quantity: quantity,
      quantityUnit: quantityUnit,
      rateInclTax: rateInclTax,
      rate: rate,
      per: per,
      gstHsnSac: gstHsnSac,
      gstRate: gstRate,
      declarationText: declarationText,
      signatureCompanyName: signatureCompanyName,
      // ── auto-calculated ──
      amount2: fmtAmount,
      gstAmount: fmtGst,
      totalAmount: fmtTotal,
      taxableValue: fmtAmount,
      totalTaxAmount: fmtGst,
      gstTotalTaxableValue: fmtAmount,
      totalQuantity: fmtQty,
      amountInWords: _toWords(calcTotal),
      taxAmountInWords: _toWords(calcGst),
    );
  }

  // ── Formatting helpers ─────────────────────────────────────────────────────

  /// Format a double as Indian-style number with 2 decimal places.
  /// e.g. 24000.0 → "24,000.00"
  static String _fmt(double v) {
    if (v == 0) return '0.00';
    // Split integer and decimal parts
    final String raw = v.toStringAsFixed(2);
    final parts = raw.split('.');
    final String intPart = _indianFormat(parts[0]);
    return '$intPart.${parts[1]}';
  }

  /// Format integer part with Indian grouping (last 3 then groups of 2).
  static String _indianFormat(String n) {
    final bool neg = n.startsWith('-');
    if (neg) n = n.substring(1);
    if (n.length <= 3) return neg ? '-$n' : n;
    final String last3 = n.substring(n.length - 3);
    final String rest = n.substring(0, n.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    final result = '${buf.toString()},$last3';
    return neg ? '-$result' : result;
  }

  /// Format quantity — drop ".0" for whole numbers.
  static String _fmtQty(double v) {
    if (v == v.truncate()) return v.truncate().toString();
    return v.toString();
  }

  // ── Number to words ────────────────────────────────────────────────────────

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
    'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
    'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
    'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  /// Convert a double amount to Indian-style words.
  /// e.g. 28320.00 → "INR Twenty Eight Thousand Three Hundred Twenty Only"
  static String _toWords(double amount) {
    if (amount == 0) return 'INR Zero Only';

    final int paise = (amount * 100).round();
    final int rupees = paise ~/ 100;
    final int paiseRem = paise % 100;

    String words = 'INR ${_rupeeWords(rupees)}';
    if (paiseRem > 0) {
      words += ' and ${_twoDigitWords(paiseRem)} Paise';
    }
    words += ' Only';
    return words;
  }

  static String _rupeeWords(int n) {
    if (n == 0) return 'Zero';
    final buf = StringBuffer();
    if (n >= 10000000) {
      buf.write('${_rupeeWords(n ~/ 10000000)} Crore ');
      n %= 10000000;
    }
    if (n >= 100000) {
      buf.write('${_rupeeWords(n ~/ 100000)} Lakh ');
      n %= 100000;
    }
    if (n >= 1000) {
      buf.write('${_rupeeWords(n ~/ 1000)} Thousand ');
      n %= 1000;
    }
    if (n >= 100) {
      buf.write('${_ones[n ~/ 100]} Hundred ');
      n %= 100;
    }
    buf.write(_twoDigitWords(n));
    return buf.toString().trim();
  }

  static String _twoDigitWords(int n) {
    if (n == 0) return '';
    if (n < 20) return _ones[n];
    final t = _tens[n ~/ 10];
    final o = _ones[n % 10];
    return o.isEmpty ? t : '$t $o';
  }
}