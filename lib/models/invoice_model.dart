/// Invoice model with all fields as optional/nullable strings
/// All fields come pre-filled with default values
class InvoiceModel {
  // ============ SELLER INFO ============
  String? companyName;
  String? proprietorName;
  String? addressLine1;
  String? addressLine2;
  String? addressLine3;
  String? gstin;
  String? sellerStateName;
  String? sellerStateCode;
  String? email;

  // ============ INVOICE HEADER ============
  String? invoiceNo;
  String? invoiceDate;
  String? deliveryNote;
  String? modeOfPayment;
  String? referenceNo;
  String? referenceDate;
  String? otherReferences;
  String? buyerOrderNo;
  String? buyerOrderDate;
  String? dispatchDocNo;
  String? deliveryNoteDate;
  String? dispatchedThrough;
  String? destination;
  String? billOfLading;
  String? motorVehicleNo;
  String? termsOfDelivery;

  // ============ CONSIGNEE (SHIP TO) ============
  String? consigneeName;
  String? consigneeAddress;
  String? consigneeState;
  String? consigneeStateCode;

  // ============ BUYER (BILL TO) ============
  String? buyerName;
  String? buyerAddress;
  String? buyerState;
  String? buyerStateCode;

  // ============ LINE ITEM ============
  String? itemDescription;
  String? hsnSac;
  String? quantity;
  String? quantityUnit;
  String? rateInclTax;
  String? rate;
  String? per;
  String? amount1;
  String? amount2;

  // ============ TOTALS ============
  String? totalQuantity;
  String? totalAmount;
  String? amountInWords;

  // ============ GST TABLE ============
  String? gstHsnSac;
  String? taxableValue;
  String? gstRate;
  String? gstAmount;
  String? totalTaxAmount;
  String? gstTotalTaxableValue;
  String? taxAmountInWords;

  // ============ FOOTER ============
  String? signatureCompanyName;
  String? declarationText;

  /// Constructor with default values for all fields
  InvoiceModel({
    // Seller Info
    this.companyName = "PMR TRADING",
    this.proprietorName = "Prop-Maheswara Reddy",
    this.addressLine1 = "PLOTNO-22, OPP IOC PETROL BUNK",
    this.addressLine2 = "PANDIPADU ROAD, Kallur",
    this.addressLine3 = "KURNOOL",
    this.gstin = "AHOPRUI5679M1Z5",
    this.sellerStateName = "Andhra Pradesh",
    this.sellerStateCode = "37",
    this.email = "pmrtraisislding4@gmail.com",

    // Invoice Header
    this.invoiceNo = "POP/202-17/03",
    this.invoiceDate = "20-Apr-25",
    this.deliveryNote = "",
    this.modeOfPayment = "",
    this.referenceNo = "",
    this.referenceDate = "",
    this.otherReferences = "",
    this.buyerOrderNo = "",
    this.buyerOrderDate = "",
    this.dispatchDocNo = "",
    this.deliveryNoteDate = "",
    this.dispatchedThrough = "",
    this.destination = "",
    this.billOfLading = "",
    this.motorVehicleNo = "AP21BG7489",
    this.termsOfDelivery = "",

    // Consignee
    this.consigneeName = "Rheems",
    this.consigneeAddress = "Pedda Anedajalapadu, Gadwal",
    this.consigneeState = "Telangana",
    this.consigneeStateCode = "36",

    // Buyer
    this.buyerName = "Rheems",
    this.buyerAddress = "Pedda Anedajalapadu, Gadwal",
    this.buyerState = "Telangana",
    this.buyerStateCode = "36",

    // Line Item
    this.itemDescription = "Granites",
    this.hsnSac = "632",
    this.quantity = "20",
    this.quantityUnit = "sqf",
    this.rateInclTax = "1.80",
    this.rate = "4.00",
    this.per = "sqf",
    this.amount1 = "900.00",
    this.amount2 = "420.00",

    // Totals
    this.totalQuantity = "400 sqf",
    this.totalAmount = "89.00",
    this.amountInWords = "INR Twenty Three Hundred Twenty Only",

    // GST Table
    this.gstHsnSac = "8802",
    this.taxableValue = "24,000.00",
    this.gstRate = "18%",
    this.gstAmount = "4,320.00",
    this.totalTaxAmount = "4,320.00",
    this.gstTotalTaxableValue = "24,000.00",
    this.taxAmountInWords = "INR Four Thousand Three Hundred Twenty Only",

    // Footer
    this.signatureCompanyName = "PMR TRADING",
    this.declarationText = "We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.",
  });

  /// Create a copy of this invoice with modified fields
  InvoiceModel copyWith({
    String? companyName,
    String? proprietorName,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? gstin,
    String? sellerStateName,
    String? sellerStateCode,
    String? email,
    String? invoiceNo,
    String? invoiceDate,
    String? deliveryNote,
    String? modeOfPayment,
    String? referenceNo,
    String? referenceDate,
    String? otherReferences,
    String? buyerOrderNo,
    String? buyerOrderDate,
    String? dispatchDocNo,
    String? deliveryNoteDate,
    String? dispatchedThrough,
    String? destination,
    String? billOfLading,
    String? motorVehicleNo,
    String? termsOfDelivery,
    String? consigneeName,
    String? consigneeAddress,
    String? consigneeState,
    String? consigneeStateCode,
    String? buyerName,
    String? buyerAddress,
    String? buyerState,
    String? buyerStateCode,
    String? itemDescription,
    String? hsnSac,
    String? quantity,
    String? quantityUnit,
    String? rateInclTax,
    String? rate,
    String? per,
    String? amount1,
    String? amount2,
    String? totalQuantity,
    String? totalAmount,
    String? amountInWords,
    String? gstHsnSac,
    String? taxableValue,
    String? gstRate,
    String? gstAmount,
    String? totalTaxAmount,
    String? gstTotalTaxableValue,
    String? taxAmountInWords,
    String? signatureCompanyName,
    String? declarationText,
  }) {
    return InvoiceModel(
      companyName: companyName ?? this.companyName,
      proprietorName: proprietorName ?? this.proprietorName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      addressLine3: addressLine3 ?? this.addressLine3,
      gstin: gstin ?? this.gstin,
      sellerStateName: sellerStateName ?? this.sellerStateName,
      sellerStateCode: sellerStateCode ?? this.sellerStateCode,
      email: email ?? this.email,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      referenceNo: referenceNo ?? this.referenceNo,
      referenceDate: referenceDate ?? this.referenceDate,
      otherReferences: otherReferences ?? this.otherReferences,
      buyerOrderNo: buyerOrderNo ?? this.buyerOrderNo,
      buyerOrderDate: buyerOrderDate ?? this.buyerOrderDate,
      dispatchDocNo: dispatchDocNo ?? this.dispatchDocNo,
      deliveryNoteDate: deliveryNoteDate ?? this.deliveryNoteDate,
      dispatchedThrough: dispatchedThrough ?? this.dispatchedThrough,
      destination: destination ?? this.destination,
      billOfLading: billOfLading ?? this.billOfLading,
      motorVehicleNo: motorVehicleNo ?? this.motorVehicleNo,
      termsOfDelivery: termsOfDelivery ?? this.termsOfDelivery,
      consigneeName: consigneeName ?? this.consigneeName,
      consigneeAddress: consigneeAddress ?? this.consigneeAddress,
      consigneeState: consigneeState ?? this.consigneeState,
      consigneeStateCode: consigneeStateCode ?? this.consigneeStateCode,
      buyerName: buyerName ?? this.buyerName,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      buyerState: buyerState ?? this.buyerState,
      buyerStateCode: buyerStateCode ?? this.buyerStateCode,
      itemDescription: itemDescription ?? this.itemDescription,
      hsnSac: hsnSac ?? this.hsnSac,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      rateInclTax: rateInclTax ?? this.rateInclTax,
      rate: rate ?? this.rate,
      per: per ?? this.per,
      amount1: amount1 ?? this.amount1,
      amount2: amount2 ?? this.amount2,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      amountInWords: amountInWords ?? this.amountInWords,
      gstHsnSac: gstHsnSac ?? this.gstHsnSac,
      taxableValue: taxableValue ?? this.taxableValue,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      gstTotalTaxableValue: gstTotalTaxableValue ?? this.gstTotalTaxableValue,
      taxAmountInWords: taxAmountInWords ?? this.taxAmountInWords,
      signatureCompanyName: signatureCompanyName ?? this.signatureCompanyName,
      declarationText: declarationText ?? this.declarationText,
    );
  }
}
