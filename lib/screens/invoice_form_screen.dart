import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/pdf_generator.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  late InvoiceModel invoice;
  bool isGenerating = false;

  /// null = not yet chosen, false = AP/Telangana (CGST+SGST), true = Other (IGST)
  bool? isInterState;

  // ── Seller ────────────────────────────────────────────────────────────────
  late TextEditingController companyNameController;
  late TextEditingController proprietorNameController;
  late TextEditingController addressLine1Controller;
  late TextEditingController gstinController;
  late TextEditingController sellerStateNameController;
  late TextEditingController sellerStateCodeController;
  late TextEditingController emailController;

  // ── Invoice Meta ──────────────────────────────────────────────────────────
  late TextEditingController invoiceNoController;
  late TextEditingController invoiceDateController;
  late TextEditingController deliveryNoteController;
  late TextEditingController modeOfPaymentController;
  late TextEditingController referenceNoController;
  late TextEditingController referenceDateController;
  late TextEditingController otherReferencesController;
  late TextEditingController buyerOrderNoController;
  late TextEditingController buyerOrderDateController;
  late TextEditingController dispatchDocNoController;
  late TextEditingController deliveryNoteDateController;
  late TextEditingController dispatchedThroughController;
  late TextEditingController destinationController;
  late TextEditingController vesselFlightNoController;
  late TextEditingController placeOfReceiptByShipperController;
  late TextEditingController cityPortOfLoadingController;
  late TextEditingController cityPortOfDischargeController;
  late TextEditingController billOfLadingController;
  late TextEditingController motorVehicleNoController;
  late TextEditingController termsOfDeliveryController;

  // ── Consignee ─────────────────────────────────────────────────────────────
  late TextEditingController consigneeNameController;
  late TextEditingController consigneeAddressController;
  late TextEditingController consigneeStateController;
  late TextEditingController consigneeStateCodeController;

  // ── Buyer ─────────────────────────────────────────────────────────────────
  late TextEditingController buyerNameController;
  late TextEditingController buyerAddressController;
  late TextEditingController buyerStateController;
  late TextEditingController buyerStateCodeController;

  // ── Line Item ─────────────────────────────────────────────────────────────
  late TextEditingController itemDescriptionController;
  late TextEditingController hsnSacController;
  late TextEditingController quantityController;
  late TextEditingController quantityUnitController;
  late TextEditingController rateInclTaxController;
  late TextEditingController rateController;
  late TextEditingController perController;

  // ── GST ───────────────────────────────────────────────────────────────────
  late TextEditingController gstHsnSacController;
  late TextEditingController gstRateController;

  // ── Bank Details ──────────────────────────────────────────────────────────
  late TextEditingController bankAccountHolderNameController;
  late TextEditingController bankNameController;
  late TextEditingController bankAccountNoController;
  late TextEditingController bankBranchIfscController;

  // ── Footer ────────────────────────────────────────────────────────────────
  late TextEditingController signatureCompanyNameController;
  late TextEditingController declarationTextController;

  @override
  void initState() {
    super.initState();
    invoice = const InvoiceModel();
    _initControllers();
    // Show state selection dialog on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStateDialog());
  }

  void _initControllers() {
    companyNameController = TextEditingController(text: invoice.companyName ?? '');
    proprietorNameController = TextEditingController(text: invoice.proprietorName ?? '');
    addressLine1Controller = TextEditingController(text: invoice.addressLine1 ?? '');
    gstinController = TextEditingController(text: invoice.gstin ?? '');
    sellerStateNameController = TextEditingController(text: invoice.sellerStateName ?? '');
    sellerStateCodeController = TextEditingController(text: invoice.sellerStateCode ?? '');
    emailController = TextEditingController(text: invoice.email ?? '');

    invoiceNoController = TextEditingController(text: invoice.invoiceNo ?? '');
    invoiceDateController = TextEditingController(text: invoice.invoiceDate ?? '');
    deliveryNoteController = TextEditingController(text: invoice.deliveryNote ?? '');
    modeOfPaymentController = TextEditingController(text: invoice.modeOfPayment ?? '');
    referenceNoController = TextEditingController(text: invoice.referenceNo ?? '');
    referenceDateController = TextEditingController(text: invoice.referenceDate ?? '');
    otherReferencesController = TextEditingController(text: invoice.otherReferences ?? '');
    buyerOrderNoController = TextEditingController(text: invoice.buyerOrderNo ?? '');
    buyerOrderDateController = TextEditingController(text: invoice.buyerOrderDate ?? '');
    dispatchDocNoController = TextEditingController(text: invoice.dispatchDocNo ?? '');
    deliveryNoteDateController = TextEditingController(text: invoice.deliveryNoteDate ?? '');
    dispatchedThroughController = TextEditingController(text: invoice.dispatchedThrough ?? '');
    destinationController = TextEditingController(text: invoice.destination ?? '');
    vesselFlightNoController = TextEditingController(text: invoice.vesselFlightNo ?? '');
    placeOfReceiptByShipperController = TextEditingController(text: invoice.placeOfReceiptByShipper ?? '');
    cityPortOfLoadingController = TextEditingController(text: invoice.cityPortOfLoading ?? '');
    cityPortOfDischargeController = TextEditingController(text: invoice.cityPortOfDischarge ?? '');
    billOfLadingController = TextEditingController(text: invoice.billOfLading ?? '');
    motorVehicleNoController = TextEditingController(text: invoice.motorVehicleNo ?? '');
    termsOfDeliveryController = TextEditingController(text: invoice.termsOfDelivery ?? '');

    consigneeNameController = TextEditingController(text: invoice.consigneeName ?? '');
    consigneeAddressController = TextEditingController(text: invoice.consigneeAddress ?? '');
    consigneeStateController = TextEditingController(text: invoice.consigneeState ?? '');
    consigneeStateCodeController = TextEditingController(text: invoice.consigneeStateCode ?? '');

    buyerNameController = TextEditingController(text: invoice.buyerName ?? '');
    buyerAddressController = TextEditingController(text: invoice.buyerAddress ?? '');
    buyerStateController = TextEditingController(text: invoice.buyerState ?? '');
    buyerStateCodeController = TextEditingController(text: invoice.buyerStateCode ?? '');

    itemDescriptionController = TextEditingController(text: invoice.itemDescription ?? '');
    hsnSacController = TextEditingController(text: invoice.hsnSac ?? '');
    quantityController = TextEditingController(text: invoice.quantity ?? '');
    quantityUnitController = TextEditingController(text: invoice.quantityUnit ?? '');
    rateInclTaxController = TextEditingController(text: invoice.rateInclTax ?? '');
    rateController = TextEditingController(text: invoice.rate ?? '');
    perController = TextEditingController(text: invoice.per ?? '');

    gstHsnSacController = TextEditingController(text: invoice.gstHsnSac ?? '');
    gstRateController = TextEditingController(text: invoice.gstRate ?? '');

    bankAccountHolderNameController = TextEditingController(text: invoice.bankAccountHolderName ?? '');
    bankNameController = TextEditingController(text: invoice.bankName ?? '');
    bankAccountNoController = TextEditingController(text: invoice.bankAccountNo ?? '');
    bankBranchIfscController = TextEditingController(text: invoice.bankBranchIfsc ?? '');

    signatureCompanyNameController = TextEditingController(text: invoice.signatureCompanyName ?? '');
    declarationTextController = TextEditingController(text: invoice.declarationText ?? '');
  }

  @override
  void dispose() {
    companyNameController.dispose();
    proprietorNameController.dispose();
    addressLine1Controller.dispose();
    gstinController.dispose();
    sellerStateNameController.dispose();
    sellerStateCodeController.dispose();
    emailController.dispose();
    invoiceNoController.dispose();
    invoiceDateController.dispose();
    deliveryNoteController.dispose();
    modeOfPaymentController.dispose();
    referenceNoController.dispose();
    referenceDateController.dispose();
    otherReferencesController.dispose();
    buyerOrderNoController.dispose();
    buyerOrderDateController.dispose();
    dispatchDocNoController.dispose();
    deliveryNoteDateController.dispose();
    dispatchedThroughController.dispose();
    destinationController.dispose();
    vesselFlightNoController.dispose();
    placeOfReceiptByShipperController.dispose();
    cityPortOfLoadingController.dispose();
    cityPortOfDischargeController.dispose();
    billOfLadingController.dispose();
    motorVehicleNoController.dispose();
    termsOfDeliveryController.dispose();
    consigneeNameController.dispose();
    consigneeAddressController.dispose();
    consigneeStateController.dispose();
    consigneeStateCodeController.dispose();
    buyerNameController.dispose();
    buyerAddressController.dispose();
    buyerStateController.dispose();
    buyerStateCodeController.dispose();
    itemDescriptionController.dispose();
    hsnSacController.dispose();
    quantityController.dispose();
    quantityUnitController.dispose();
    rateInclTaxController.dispose();
    rateController.dispose();
    perController.dispose();
    gstHsnSacController.dispose();
    gstRateController.dispose();
    bankAccountHolderNameController.dispose();
    bankNameController.dispose();
    bankAccountNoController.dispose();
    bankBranchIfscController.dispose();
    signatureCompanyNameController.dispose();
    declarationTextController.dispose();
    super.dispose();
  }

  /// Show dialog to pick AP/Telangana (CGST+SGST) or Other (IGST)
  Future<void> _showStateDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Buyer State'),
        content: const Text(
          'Choose the buyer\'s state to determine the tax type for this invoice.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                setState(() => isInterState = false);
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Andhra Pradesh / Telangana\n(CGST + SGST)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                setState(() => isInterState = true);
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Other State\n(IGST)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _updateInvoiceFromControllers() {
    invoice = InvoiceModel(
      companyName: companyNameController.text,
      proprietorName: proprietorNameController.text,
      addressLine1: addressLine1Controller.text,
      gstin: gstinController.text,
      sellerStateName: sellerStateNameController.text,
      sellerStateCode: sellerStateCodeController.text,
      email: emailController.text,
      invoiceNo: invoiceNoController.text,
      invoiceDate: invoiceDateController.text,
      deliveryNote: deliveryNoteController.text,
      modeOfPayment: modeOfPaymentController.text,
      referenceNo: referenceNoController.text,
      referenceDate: referenceDateController.text,
      otherReferences: otherReferencesController.text,
      buyerOrderNo: buyerOrderNoController.text,
      buyerOrderDate: buyerOrderDateController.text,
      dispatchDocNo: dispatchDocNoController.text,
      deliveryNoteDate: deliveryNoteDateController.text,
      dispatchedThrough: dispatchedThroughController.text,
      destination: destinationController.text,
      vesselFlightNo: vesselFlightNoController.text,
      placeOfReceiptByShipper: placeOfReceiptByShipperController.text,
      cityPortOfLoading: cityPortOfLoadingController.text,
      cityPortOfDischarge: cityPortOfDischargeController.text,
      billOfLading: billOfLadingController.text,
      motorVehicleNo: motorVehicleNoController.text,
      termsOfDelivery: termsOfDeliveryController.text,
      consigneeName: consigneeNameController.text,
      consigneeAddress: consigneeAddressController.text,
      consigneeState: consigneeStateController.text,
      consigneeStateCode: consigneeStateCodeController.text,
      buyerName: buyerNameController.text,
      buyerAddress: buyerAddressController.text,
      buyerState: buyerStateController.text,
      buyerStateCode: buyerStateCodeController.text,
      itemDescription: itemDescriptionController.text,
      hsnSac: hsnSacController.text,
      quantity: quantityController.text,
      quantityUnit: quantityUnitController.text,
      rateInclTax: rateInclTaxController.text,
      rate: rateController.text,
      per: perController.text,
      isInterState: isInterState ?? false,
      gstHsnSac: gstHsnSacController.text,
      gstRate: gstRateController.text,
      bankAccountHolderName: bankAccountHolderNameController.text,
      bankName: bankNameController.text,
      bankAccountNo: bankAccountNoController.text,
      bankBranchIfsc: bankBranchIfscController.text,
      signatureCompanyName: signatureCompanyNameController.text,
      declarationText: declarationTextController.text,
    );
  }

  Future<void> _generateInvoicePdf() async {
    setState(() => isGenerating = true);
    try {
      _updateInvoiceFromControllers();
      await PdfGenerator.generateInvoice(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice PDF generated and saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      );

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      );

  /// Tax-type badge shown in the app bar subtitle
  Widget _taxBadge() {
    if (isInterState == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isInterState! ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isInterState! ? 'IGST (Other State)' : 'CGST + SGST (AP/Telangana)',
        style: TextStyle(
          fontSize: 11,
          color: isInterState! ? Colors.orange.shade800 : Colors.green.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tax Invoice Generator'),
            _taxBadge(),
          ],
        ),
        backgroundColor: Colors.blue,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: 'Change tax type',
            onPressed: _showStateDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SELLER ────────────────────────────────────────────────
                _sectionHeader('Seller Information'),
                _field(companyNameController, 'Company Name'),
                _field(proprietorNameController, 'Proprietor Name'),
                _field(addressLine1Controller, 'Address'),
                _field(gstinController, 'GSTIN/UIN'),
                _field(sellerStateNameController, 'State Name'),
                _field(sellerStateCodeController, 'State Code'),
                _field(emailController, 'E-Mail',
                    keyboardType: TextInputType.emailAddress),

                // ── INVOICE DETAILS ───────────────────────────────────────
                _sectionHeader('Invoice Details'),
                _field(invoiceNoController, 'Invoice No.'),
                _field(invoiceDateController, 'Invoice Date'),
                _field(deliveryNoteController, 'Delivery Note'),
                _field(modeOfPaymentController, 'Mode/Terms of Payment'),
                _field(referenceNoController, 'Reference No.'),
                _field(referenceDateController, 'Reference Date'),
                _field(otherReferencesController, 'Other References'),
                _field(buyerOrderNoController, "Buyer's Order No."),
                _field(buyerOrderDateController, 'Buyer Order Date'),
                _field(dispatchDocNoController, 'Dispatch Doc No.'),
                _field(deliveryNoteDateController, 'Delivery Note Date'),
                _field(dispatchedThroughController, 'Dispatched Through'),
                _field(destinationController, 'Destination'),
                _field(vesselFlightNoController, 'Vessel/Flight No.'),
                _field(placeOfReceiptByShipperController,
                    'Place of Receipt by Shipper'),
                _field(cityPortOfLoadingController, 'City/Port of Loading'),
                _field(cityPortOfDischargeController, 'City/Port of Discharge'),
                _field(billOfLadingController, 'Bill of Lading/LR-RR No.'),
                _field(motorVehicleNoController, 'Motor Vehicle No.'),
                _field(termsOfDeliveryController, 'Terms of Delivery'),

                // ── CONSIGNEE ─────────────────────────────────────────────
                _sectionHeader('Consignee (Ship To)'),
                _field(consigneeNameController, 'Consignee Name'),
                _field(consigneeAddressController, 'Address'),
                _field(consigneeStateController, 'State Name'),
                _field(consigneeStateCodeController, 'State Code'),

                // ── BUYER ─────────────────────────────────────────────────
                _sectionHeader('Buyer (Bill To)'),
                _field(buyerNameController, 'Buyer Name'),
                _field(buyerAddressController, 'Address'),
                _field(buyerStateController, 'State Name'),
                _field(buyerStateCodeController, 'State Code'),

                // ── LINE ITEM ─────────────────────────────────────────────
                _sectionHeader('Line Item'),
                _field(itemDescriptionController, 'Item Description'),
                _field(hsnSacController, 'HSN/SAC'),
                _field(quantityController, 'Quantity',
                    keyboardType: TextInputType.number),
                _field(quantityUnitController, 'Quantity Unit (e.g. sqf)'),
                _field(rateInclTaxController, 'Rate (Incl. of Tax)',
                    keyboardType: TextInputType.number),
                _field(rateController, 'Rate',
                    keyboardType: TextInputType.number),
                _field(perController, 'Per (e.g. sqf)'),

                // ── GST ───────────────────────────────────────────────────
                _sectionHeader(isInterState == true
                    ? 'GST Details (IGST)'
                    : 'GST Details (CGST + SGST)'),
                _field(gstHsnSacController, 'HSN/SAC (GST)'),
                _field(
                  gstRateController,
                  isInterState == true
                      ? 'IGST Rate % (e.g. 18)'
                      : 'Total GST Rate % (e.g. 18 → 9% CGST + 9% SGST)',
                  keyboardType: TextInputType.number,
                ),

                // ── BANK DETAILS ──────────────────────────────────────────
                _sectionHeader("Company's Bank Details"),
                _field(bankAccountHolderNameController, "A/c Holder's Name"),
                _field(bankNameController, 'Bank Name'),
                _field(bankAccountNoController, 'Account No.',
                    keyboardType: TextInputType.number),
                _field(bankBranchIfscController, 'Branch & IFS Code'),

                // ── FOOTER ────────────────────────────────────────────────
                _sectionHeader('Footer'),
                _field(signatureCompanyNameController,
                    'Company Name (for Signature)'),
                _field(declarationTextController, 'Declaration Text'),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Sticky bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: isGenerating ? null : _generateInvoicePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Generate Invoice PDF',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}