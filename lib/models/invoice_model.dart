/// Model for a Tax Invoice.
///
/// Tax type is controlled by [isInterState]:
///   false → CGST + SGST (Andhra Pradesh / Telangana)
///   true  → IGST (other states)
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
  final String? referenceDate;
  final String? otherReferences;
  final String? buyerOrderNo;
  final String? buyerOrderDate;
  final String? dispatchDocNo;
  final String? deliveryNoteDate;
  final String? dispatchedThrough;
  final String? destination;
  final String? vesselFlightNo;
  final String? placeOfReceiptByShipper;
  final String? cityPortOfLoading;
  final String? cityPortOfDischarge;
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
  final String? quantity;
  final String? quantityUnit;
  final String? rateInclTax;
  final String? rate;
  final String? per;

  // ── Tax config ────────────────────────────────────────────────────────────
  /// false = CGST+SGST (AP/Telangana), true = IGST (other states)
  final bool isInterState;
  final String? gstHsnSac;
  final String? gstRate;

  // ── Bank Details ──────────────────────────────────────────────────────────
  final String? bankAccountHolderName;
  final String? bankName;
  final String? bankAccountNo;
  final String? bankBranchIfsc;

  // ── Auto-calculated (DO NOT show in UI) ───────────────────────────────────
  final String? amount2;
  final String? cgstAmount;
  final String? sgstAmount;
  final String? igstAmount;
  final String? totalAmount;
  final String? taxableValue;
  final String? totalTaxAmount;
  final String? gstTotalTaxableValue;
  final String? totalQuantity;
  final String? amountInWords;
  final String? taxAmountInWords;

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
    this.referenceDate,
    this.otherReferences,
    this.buyerOrderNo,
    this.buyerOrderDate,
    this.dispatchDocNo,
    this.deliveryNoteDate,
    this.dispatchedThrough,
    this.destination,
    this.vesselFlightNo,
    this.placeOfReceiptByShipper,
    this.cityPortOfLoading,
    this.cityPortOfDischarge,
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
    this.isInterState = false,
    this.gstHsnSac,
    this.gstRate,
    this.bankAccountHolderName,
    this.bankName,
    this.bankAccountNo,
    this.bankBranchIfsc,
    // auto-calculated
    this.amount2,
    this.cgstAmount,
    this.sgstAmount,
    this.igstAmount,
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
  InvoiceModel withCalculations() {
    final double qty = double.tryParse(quantity ?? '') ?? 0;
    final double rt = double.tryParse(rate ?? '') ?? 0;
    final double gstPct = double.tryParse(gstRate ?? '') ?? 0;

    final double calcAmount = qty * rt;
    // For CGST+SGST: gstRate is total (e.g. 18%), split equally
    // For IGST: full gstRate applied as IGST
    final double halfGstPct = gstPct / 2;
    final double calcCgst = isInterState ? 0 : (calcAmount * halfGstPct) / 100;
    final double calcSgst = isInterState ? 0 : (calcAmount * halfGstPct) / 100;
    final double calcIgst = isInterState ? (calcAmount * gstPct) / 100 : 0;
    final double calcTotalTax = isInterState ? calcIgst : (calcCgst + calcSgst);
    final double calcTotal = calcAmount + calcTotalTax;

    final String fmtAmount = _fmt(calcAmount);
    final String fmtCgst = isInterState ? '' : _fmt(calcCgst);
    final String fmtSgst = isInterState ? '' : _fmt(calcSgst);
    final String fmtIgst = isInterState ? _fmt(calcIgst) : '';
    final String fmtTotalTax = _fmt(calcTotalTax);
    final String fmtTotal = _fmt(calcTotal);
    final String fmtQty = '${_fmtQty(qty)} ${quantityUnit ?? ''}'.trim();

    return InvoiceModel(
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
      referenceDate: referenceDate,
      otherReferences: otherReferences,
      buyerOrderNo: buyerOrderNo,
      buyerOrderDate: buyerOrderDate,
      dispatchDocNo: dispatchDocNo,
      deliveryNoteDate: deliveryNoteDate,
      dispatchedThrough: dispatchedThrough,
      destination: destination,
      vesselFlightNo: vesselFlightNo,
      placeOfReceiptByShipper: placeOfReceiptByShipper,
      cityPortOfLoading: cityPortOfLoading,
      cityPortOfDischarge: cityPortOfDischarge,
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
      isInterState: isInterState,
      gstHsnSac: gstHsnSac,
      gstRate: gstRate,
      bankAccountHolderName: bankAccountHolderName,
      bankName: bankName,
      bankAccountNo: bankAccountNo,
      bankBranchIfsc: bankBranchIfsc,
      declarationText: declarationText,
      signatureCompanyName: signatureCompanyName,
      // ── auto-calculated ──
      amount2: fmtAmount,
      cgstAmount: fmtCgst,
      sgstAmount: fmtSgst,
      igstAmount: fmtIgst,
      totalAmount: fmtTotal,
      taxableValue: fmtAmount,
      totalTaxAmount: fmtTotalTax,
      gstTotalTaxableValue: fmtAmount,
      totalQuantity: fmtQty,
      amountInWords: _toWords(calcTotal),
      taxAmountInWords: _toWords(calcTotalTax),
    );
  }

  // ── Formatting helpers ─────────────────────────────────────────────────────

  static String _fmt(double v) {
    if (v == 0) return '0.00';
    final String raw = v.toStringAsFixed(2);
    final parts = raw.split('.');
    final String intPart = _indianFormat(parts[0]);
    return '$intPart.${parts[1]}';
  }

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

  static String _fmtQty(double v) {
    if (v == v.truncate()) return v.truncate().toString();
    return v.toString();
  }

  static const _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
    'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
    'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
  ];
  static const _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
    'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

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