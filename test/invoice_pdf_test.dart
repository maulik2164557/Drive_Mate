import 'package:flutter_test/flutter_test.dart';
import 'package:drive_mate/services/receipt_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ReceiptPdfService generates valid PDF with invoice number', () async {
    final invoiceNo = ReceiptPdfService.generateInvoiceNumber('BK123456');
    expect(invoiceNo.startsWith('INV-'), true);
    expect(invoiceNo.contains('123456'), true);

    final pdfBytes = await ReceiptPdfService.generateInvoicePdfBytes(
      bookingId: 'BK12345678',
      invoiceNumber: invoiceNo,
      customerName: 'Maulik Patoliya',
      customerEmail: 'maulik@example.com',
      mobileNumber: '+91 9876543210',
      carName: 'Hyundai Creta SX',
      category: 'SUV',
      district: 'Ahmedabad',
      pickupLocation: 'Ahmedabad Airport Depot',
      pickupDateTime: DateTime(2026, 10, 10, 10, 0),
      dropLocation: 'Ahmedabad Airport Depot',
      dropDateTime: DateTime(2026, 10, 12, 18, 0),
      totalPrice: 4800.0,
      paymentMethod: 'UPI (GPay / PhonePe)',
    );

    expect(pdfBytes.isNotEmpty, true);
    // PDF Magic bytes: %PDF (0x25, 0x50, 0x44, 0x46)
    expect(pdfBytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]);
  });
}
