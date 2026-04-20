import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/pdf_generator.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  // Initialize invoice with default values
  late InvoiceModel invoice;
  bool isGenerating = false;

  // Text controllers for all fields
  late TextEditingController companyNameController;
  late TextEditingController proprietorNameController;
  late TextEditingController addressLine1Controller;
  late TextEditingController addressLine2Controller;
  late TextEditingController addressLine3Controller;
  late TextEditingController gstinController;
  late TextEditingController sellerStateNameController;
  late TextEditingController sellerStateCodeController;
  late TextEditingController emailController;

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
  late TextEditingController billOfLadingController;
  late TextEditingController motorVehicleNoController;
  late TextEditingController termsOfDeliveryController;

  late TextEditingController consigneeNameController;
  late TextEditingController consigneeAddressController;
  late TextEditingController consigneeStateController;
  late TextEditingController consigneeStateCodeController;

  late TextEditingController buyerNameController;
  late TextEditingController buyerAddressController;
  late TextEditingController buyerStateController;
  late TextEditingController buyerStateCodeController;

  late TextEditingController itemDescriptionController;
  late TextEditingController hsnSacController;
  late TextEditingController quantityController;
  late TextEditingController quantityUnitController;
  late TextEditingController rateInclTaxController;
  late TextEditingController rateController;
  late TextEditingController perController;
  late TextEditingController amount1Controller;
  late TextEditingController amount2Controller;

  late TextEditingController totalQuantityController;
  late TextEditingController totalAmountController;
  late TextEditingController amountInWordsController;

  late TextEditingController gstHsnSacController;
  late TextEditingController taxableValueController;
  late TextEditingController gstRateController;
  late TextEditingController gstAmountController;
  late TextEditingController totalTaxAmountController;
  late TextEditingController gstTotalTaxableValueController;
  late TextEditingController taxAmountInWordsController;

  late TextEditingController signatureCompanyNameController;
  late TextEditingController declarationTextController;

  @override
  void initState() {
    super.initState();
    invoice = InvoiceModel(); // Initialize with defaults

    // Initialize all controllers with default values
    companyNameController = TextEditingController(text: invoice.companyName);
    proprietorNameController = TextEditingController(text: invoice.proprietorName);
    addressLine1Controller = TextEditingController(text: invoice.addressLine1);
    addressLine2Controller = TextEditingController(text: invoice.addressLine2);
    addressLine3Controller = TextEditingController(text: invoice.addressLine3);
    gstinController = TextEditingController(text: invoice.gstin);
    sellerStateNameController = TextEditingController(text: invoice.sellerStateName);
    sellerStateCodeController = TextEditingController(text: invoice.sellerStateCode);
    emailController = TextEditingController(text: invoice.email);

    invoiceNoController = TextEditingController(text: invoice.invoiceNo);
    invoiceDateController = TextEditingController(text: invoice.invoiceDate);
    deliveryNoteController = TextEditingController(text: invoice.deliveryNote);
    modeOfPaymentController = TextEditingController(text: invoice.modeOfPayment);
    referenceNoController = TextEditingController(text: invoice.referenceNo);
    referenceDateController = TextEditingController(text: invoice.referenceDate);
    otherReferencesController = TextEditingController(text: invoice.otherReferences);
    buyerOrderNoController = TextEditingController(text: invoice.buyerOrderNo);
    buyerOrderDateController = TextEditingController(text: invoice.buyerOrderDate);
    dispatchDocNoController = TextEditingController(text: invoice.dispatchDocNo);
    deliveryNoteDateController = TextEditingController(text: invoice.deliveryNoteDate);
    dispatchedThroughController = TextEditingController(text: invoice.dispatchedThrough);
    destinationController = TextEditingController(text: invoice.destination);
    billOfLadingController = TextEditingController(text: invoice.billOfLading);
    motorVehicleNoController = TextEditingController(text: invoice.motorVehicleNo);
    termsOfDeliveryController = TextEditingController(text: invoice.termsOfDelivery);

    consigneeNameController = TextEditingController(text: invoice.consigneeName);
    consigneeAddressController = TextEditingController(text: invoice.consigneeAddress);
    consigneeStateController = TextEditingController(text: invoice.consigneeState);
    consigneeStateCodeController = TextEditingController(text: invoice.consigneeStateCode);

    buyerNameController = TextEditingController(text: invoice.buyerName);
    buyerAddressController = TextEditingController(text: invoice.buyerAddress);
    buyerStateController = TextEditingController(text: invoice.buyerState);
    buyerStateCodeController = TextEditingController(text: invoice.buyerStateCode);

    itemDescriptionController = TextEditingController(text: invoice.itemDescription);
    hsnSacController = TextEditingController(text: invoice.hsnSac);
    quantityController = TextEditingController(text: invoice.quantity);
    quantityUnitController = TextEditingController(text: invoice.quantityUnit);
    rateInclTaxController = TextEditingController(text: invoice.rateInclTax);
    rateController = TextEditingController(text: invoice.rate);
    perController = TextEditingController(text: invoice.per);
    amount1Controller = TextEditingController(text: invoice.amount1);
    amount2Controller = TextEditingController(text: invoice.amount2);

    totalQuantityController = TextEditingController(text: invoice.totalQuantity);
    totalAmountController = TextEditingController(text: invoice.totalAmount);
    amountInWordsController = TextEditingController(text: invoice.amountInWords);

    gstHsnSacController = TextEditingController(text: invoice.gstHsnSac);
    taxableValueController = TextEditingController(text: invoice.taxableValue);
    gstRateController = TextEditingController(text: invoice.gstRate);
    gstAmountController = TextEditingController(text: invoice.gstAmount);
    totalTaxAmountController = TextEditingController(text: invoice.totalTaxAmount);
    gstTotalTaxableValueController = TextEditingController(text: invoice.gstTotalTaxableValue);
    taxAmountInWordsController = TextEditingController(text: invoice.taxAmountInWords);

    signatureCompanyNameController = TextEditingController(text: invoice.signatureCompanyName);
    declarationTextController = TextEditingController(text: invoice.declarationText);
  }

  @override
  void dispose() {
    // Dispose all controllers to free memory
    companyNameController.dispose();
    proprietorNameController.dispose();
    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    addressLine3Controller.dispose();
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
    amount1Controller.dispose();
    amount2Controller.dispose();

    totalQuantityController.dispose();
    totalAmountController.dispose();
    amountInWordsController.dispose();

    gstHsnSacController.dispose();
    taxableValueController.dispose();
    gstRateController.dispose();
    gstAmountController.dispose();
    totalTaxAmountController.dispose();
    gstTotalTaxableValueController.dispose();
    taxAmountInWordsController.dispose();

    signatureCompanyNameController.dispose();
    declarationTextController.dispose();

    super.dispose();
  }

  /// Update the invoice object with values from all controllers
  void updateInvoiceFromControllers() {
    invoice = InvoiceModel(
      companyName: companyNameController.text,
      proprietorName: proprietorNameController.text,
      addressLine1: addressLine1Controller.text,
      addressLine2: addressLine2Controller.text,
      addressLine3: addressLine3Controller.text,
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
      amount1: amount1Controller.text,
      amount2: amount2Controller.text,
      totalQuantity: totalQuantityController.text,
      totalAmount: totalAmountController.text,
      amountInWords: amountInWordsController.text,
      gstHsnSac: gstHsnSacController.text,
      taxableValue: taxableValueController.text,
      gstRate: gstRateController.text,
      gstAmount: gstAmountController.text,
      totalTaxAmount: totalTaxAmountController.text,
      gstTotalTaxableValue: gstTotalTaxableValueController.text,
      taxAmountInWords: taxAmountInWordsController.text,
      signatureCompanyName: signatureCompanyNameController.text,
      declarationText: declarationTextController.text,
    );
  }

  /// Handle Generate Invoice button press
  Future<void> generateInvoicePdf() async {
    setState(() => isGenerating = true);

    try {
      updateInvoiceFromControllers();
      await PdfGenerator.generateInvoice(invoice);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice PDF generated and saved to Downloads!'),
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
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }

  /// Build a section header with title
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// Build a text form field
  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Invoice Generator'),
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Main scrollable form content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============ SELLER INFO SECTION ============
                buildSectionHeader('Seller Information'),
                buildTextField(companyNameController, 'Company Name'),
                buildTextField(proprietorNameController, 'Proprietor Name'),
                buildTextField(addressLine1Controller, 'Address Line 1'),
                buildTextField(addressLine2Controller, 'Address Line 2'),
                buildTextField(addressLine3Controller, 'Address Line 3'),
                buildTextField(gstinController, 'GSTIN'),
                buildTextField(sellerStateNameController, 'State Name'),
                buildTextField(sellerStateCodeController, 'State Code'),
                buildTextField(emailController, 'Email'),

                // ============ INVOICE DETAILS SECTION ============
                buildSectionHeader('Invoice Details'),
                buildTextField(invoiceNoController, 'Invoice No'),
                buildTextField(invoiceDateController, 'Invoice Date'),
                buildTextField(deliveryNoteController, 'Delivery Note'),
                buildTextField(modeOfPaymentController, 'Mode of Payment'),
                buildTextField(referenceNoController, 'Reference No'),
                buildTextField(referenceDateController, 'Reference Date'),
                buildTextField(otherReferencesController, 'Other References'),
                buildTextField(buyerOrderNoController, 'Buyer Order No'),
                buildTextField(buyerOrderDateController, 'Buyer Order Date'),
                buildTextField(dispatchDocNoController, 'Dispatch Doc No'),
                buildTextField(deliveryNoteDateController, 'Delivery Note Date'),
                buildTextField(dispatchedThroughController, 'Dispatched Through'),
                buildTextField(destinationController, 'Destination'),
                buildTextField(billOfLadingController, 'Bill of Lading'),
                buildTextField(motorVehicleNoController, 'Motor Vehicle No'),
                buildTextField(termsOfDeliveryController, 'Terms of Delivery'),

                // ============ CONSIGNEE SECTION ============
                buildSectionHeader('Consignee (Ship To)'),
                buildTextField(consigneeNameController, 'Consignee Name'),
                buildTextField(consigneeAddressController, 'Consignee Address'),
                buildTextField(consigneeStateController, 'State'),
                buildTextField(consigneeStateCodeController, 'State Code'),

                // ============ BUYER SECTION ============
                buildSectionHeader('Buyer (Bill To)'),
                buildTextField(buyerNameController, 'Buyer Name'),
                buildTextField(buyerAddressController, 'Buyer Address'),
                buildTextField(buyerStateController, 'State'),
                buildTextField(buyerStateCodeController, 'State Code'),

                // ============ LINE ITEM SECTION ============
                buildSectionHeader('Line Item'),
                buildTextField(itemDescriptionController, 'Item Description'),
                buildTextField(hsnSacController, 'HSN/SAC'),
                buildTextField(quantityController, 'Quantity'),
                buildTextField(quantityUnitController, 'Quantity Unit'),
                buildTextField(rateInclTaxController, 'Rate (Incl. Tax)'),
                buildTextField(rateController, 'Rate'),
                buildTextField(perController, 'Per'),
                buildTextField(amount1Controller, 'Amount 1'),
                buildTextField(amount2Controller, 'Amount 2'),

                // ============ TOTALS SECTION ============
                buildSectionHeader('Totals'),
                buildTextField(totalQuantityController, 'Total Quantity'),
                buildTextField(totalAmountController, 'Total Amount'),
                buildTextField(amountInWordsController, 'Amount in Words'),

                // ============ GST SECTION ============
                buildSectionHeader('GST Details'),
                buildTextField(gstHsnSacController, 'GST HSN/SAC'),
                buildTextField(taxableValueController, 'Taxable Value'),
                buildTextField(gstRateController, 'GST Rate'),
                buildTextField(gstAmountController, 'GST Amount'),
                buildTextField(totalTaxAmountController, 'Total Tax Amount'),
                buildTextField(gstTotalTaxableValueController, 'Total Taxable Value'),
                buildTextField(taxAmountInWordsController, 'Tax Amount in Words'),

                // ============ FOOTER SECTION ============
                buildSectionHeader('Footer'),
                buildTextField(signatureCompanyNameController, 'Company Name (Signature)'),
                buildTextField(declarationTextController, 'Declaration Text'),

                // Add bottom padding for the sticky button area
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Sticky bottom button bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: isGenerating ? null : generateInvoicePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Generate Invoice PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
