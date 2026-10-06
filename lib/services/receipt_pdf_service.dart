import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptPdfService {
  /// Generates a standardized, unique invoice number.
  static String generateInvoiceNumber([String? bookingId]) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    if (bookingId != null && bookingId.isNotEmpty) {
      final cleanId = bookingId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final suffix = cleanId.length > 6 ? cleanId.substring(cleanId.length - 6).toUpperCase() : cleanId.toUpperCase();
      return 'INV-$dateStr-$suffix';
    }
    final timeSuffix = (now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    return 'INV-$dateStr-$timeSuffix';
  }

  /// Builds and returns the raw PDF document bytes for the tax invoice / receipt.
  static Future<Uint8List> generateInvoicePdfBytes({
    required String bookingId,
    String? invoiceNumber,
    required String customerName,
    required String customerEmail,
    required String mobileNumber,
    required String carName,
    required String category,
    required String district,
    required String pickupLocation,
    required DateTime pickupDateTime,
    required String dropLocation,
    required DateTime dropDateTime,
    required double totalPrice,
    required String paymentMethod,
    DateTime? invoiceDate,
  }) async {
    final effectiveInvoiceNumber = invoiceNumber ?? generateInvoiceNumber(bookingId);
    final shortBookingId = bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : (bookingId.isEmpty ? 'BK-DM' : bookingId.toUpperCase());
    final issuanceDate = invoiceDate ?? DateTime.now();

    final formattedInvoiceDate = DateFormat('dd MMM yyyy, hh:mm a').format(issuanceDate);
    final formattedPickup = DateFormat('dd MMM yyyy, hh:mm a').format(pickupDateTime);
    final formattedDrop = DateFormat('dd MMM yyyy, hh:mm a').format(dropDateTime);
    final durationHours = dropDateTime.difference(pickupDateTime).inHours;
    final durationDays = (durationHours / 24).toStringAsFixed(1);

    // Pricing calculation
    final gstRate = 0.18; // 18% GST standard in vehicle rental services
    final baseAmount = totalPrice / (1 + gstRate);
    final totalGst = totalPrice - baseAmount;
    final cgst = totalGst / 2;
    final sgst = totalGst / 2;

    // Load fonts gracefully with fallback
    pw.ThemeData theme;
    try {
      final baseFont = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      final italicFont = await PdfGoogleFonts.robotoItalic();
      theme = pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        italic: italicFont,
      );
    } catch (_) {
      theme = pw.ThemeData.base();
    }

    final pdf = pw.Document(theme: theme);

    // Color definitions
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // #1E3A8A
    const secondaryColor = PdfColor.fromInt(0xFF0284C7); // #0284C7
    const darkTextColor = PdfColor.fromInt(0xFF0F172A); // #0F172A
    const mutedTextColor = PdfColor.fromInt(0xFF64748B); // #64748B
    const lightBgColor = PdfColor.fromInt(0xFFF8FAFC); // #F8FAFC
    const borderColor = PdfColor.fromInt(0xFFE2E8F0); // #E2E8F0
    const successBg = PdfColor.fromInt(0xFFDCFCE7); // #DCFCE7
    const successText = PdfColor.fromInt(0xFF166534); // #166534

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DriveMate',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Gujarat Premium Self-Drive Car Rentals',
                        style: pw.TextStyle(
                          color: secondaryColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'GSTIN: 24AAACD9821F1ZX | Reg: DM-GJ-2024',
                        style: const pw.TextStyle(color: mutedTextColor, fontSize: 8),
                      ),
                      pw.Text(
                        '24/7 Helpline: +91 1800-DRIVEMATE | help@drivemate.com',
                        style: const pw.TextStyle(color: mutedTextColor, fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(
                      color: lightBgColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: const pw.BoxDecoration(
                            color: successBg,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'PAID & CONFIRMED',
                            style: pw.TextStyle(
                              color: successText,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 10),

              // 2. Invoice & Booking Reference Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: lightBgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INVOICE NUMBER', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          effectiveInvoiceNumber,
                          style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BOOKING REFERENCE', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '#$shortBookingId',
                          style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATE OF ISSUANCE', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          formattedInvoiceDate,
                          style: pw.TextStyle(color: darkTextColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT METHOD', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          paymentMethod,
                          style: pw.TextStyle(color: darkTextColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 3. Customer & Depot Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Customer Info
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILLED TO (CUSTOMER DETAILS)',
                            style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(customerName, style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('Email: $customerEmail', style: const pw.TextStyle(color: mutedTextColor, fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text('Mobile: $mobileNumber', style: const pw.TextStyle(color: mutedTextColor, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  // Right: Depot & Rental Branch
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RENTAL DEPOT & SERVICE',
                            style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('$district Office Depot', style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('Service: Self-Drive Vehicle Rental', style: const pw.TextStyle(color: mutedTextColor, fontSize: 9)),
                          pw.SizedBox(height: 2),
                          pw.Text('Region: Gujarat, India', style: const pw.TextStyle(color: mutedTextColor, fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 4. Vehicle & Journey Schedule Card
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('VEHICLE & JOURNEY SCHEDULE', style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Duration: $durationHours Hours ($durationDays Days)', style: pw.TextStyle(color: darkTextColor, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Vehicle Model', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                              pw.Text(carName, style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Category', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                              pw.Text(category, style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Pickup Point & Time', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                              pw.Text(pickupLocation, style: pw.TextStyle(color: darkTextColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text(formattedPickup, style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Drop Point & Time', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                              pw.Text(dropLocation, style: pw.TextStyle(color: darkTextColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text(formattedDrop, style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 5. Itemized Financial Billing Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: lightBgColor,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 5, child: pw.Text('DESCRIPTION', style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 2, child: pw.Text('SCHEDULE / UNITS', textAlign: pw.TextAlign.center, style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold))),
                          pw.Expanded(flex: 3, child: pw.Text('AMOUNT (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                    ),
                    pw.Divider(color: borderColor, height: 1),
                    // Row 1: Base Rental
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Vehicle Rental Charges', style: pw.TextStyle(color: darkTextColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                pw.Text('Self-drive rental for $carName ($category)', style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('$durationHours Hrs', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: darkTextColor, fontSize: 9)),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('INR ${baseAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: darkTextColor, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(color: borderColor, height: 1),
                    // Row 2: CGST
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text('Central GST (CGST @ 9%)', style: const pw.TextStyle(color: darkTextColor, fontSize: 9)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('9%', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('INR ${cgst.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: darkTextColor, fontSize: 9)),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(color: borderColor, height: 1),
                    // Row 3: SGST
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text('State GST (SGST @ 9%)', style: const pw.TextStyle(color: darkTextColor, fontSize: 9)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text('9%', textAlign: pw.TextAlign.center, style: const pw.TextStyle(color: mutedTextColor, fontSize: 8)),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text('INR ${sgst.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(color: darkTextColor, fontSize: 9)),
                          ),
                        ],
                      ),
                    ),
                    pw.Divider(color: primaryColor, thickness: 1.5, height: 1),
                    // Total Row
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const pw.BoxDecoration(
                        color: lightBgColor,
                        borderRadius: pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(5),
                          bottomRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL AMOUNT PAID',
                            style: pw.TextStyle(color: darkTextColor, fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'INR ${totalPrice.toStringAsFixed(2)}',
                            style: pw.TextStyle(color: primaryColor, fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // 6. Security, Terms & Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBgColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This is an electronically generated tax invoice and payment confirmation. No physical signature is required.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(color: mutedTextColor, fontSize: 8),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'DriveMate Gujarat | 24/7 Helpline: +91 1800-DRIVEMATE | www.drivemate.com',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(color: primaryColor, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates the PDF invoice and triggers immediate download on the client device.
  static Future<void> downloadReceiptPdf({
    required String bookingId,
    String? invoiceNumber,
    required String customerName,
    required String customerEmail,
    required String mobileNumber,
    required String carName,
    required String category,
    required String district,
    required String pickupLocation,
    required DateTime pickupDateTime,
    required String dropLocation,
    required DateTime dropDateTime,
    required double totalPrice,
    required String paymentMethod,
    DateTime? invoiceDate,
  }) async {
    final effectiveInvoice = invoiceNumber ?? generateInvoiceNumber(bookingId);
    final filename = 'DriveMate_${effectiveInvoice.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf';

    debugPrint('Generating genuine PDF invoice $effectiveInvoice ($filename)...');

    try {
      final pdfBytes = await generateInvoicePdfBytes(
        bookingId: bookingId,
        invoiceNumber: effectiveInvoice,
        customerName: customerName,
        customerEmail: customerEmail,
        mobileNumber: mobileNumber,
        carName: carName,
        category: category,
        district: district,
        pickupLocation: pickupLocation,
        pickupDateTime: pickupDateTime,
        dropLocation: dropLocation,
        dropDateTime: dropDateTime,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
        invoiceDate: invoiceDate,
      );

      // Trigger cross-platform download / share as actual .pdf binary
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
      debugPrint('Invoice PDF download triggered successfully: $filename');
    } catch (e) {
      debugPrint('Error generating or downloading invoice PDF: $e');
      rethrow;
    }
  }

  /// Opens the native print or PDF preview dialog.
  static Future<void> printOrPreviewPdf({
    required String bookingId,
    String? invoiceNumber,
    required String customerName,
    required String customerEmail,
    required String mobileNumber,
    required String carName,
    required String category,
    required String district,
    required String pickupLocation,
    required DateTime pickupDateTime,
    required String dropLocation,
    required DateTime dropDateTime,
    required double totalPrice,
    required String paymentMethod,
    DateTime? invoiceDate,
  }) async {
    final effectiveInvoice = invoiceNumber ?? generateInvoiceNumber(bookingId);
    final filename = 'DriveMate_${effectiveInvoice.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.pdf';

    final pdfBytes = await generateInvoicePdfBytes(
      bookingId: bookingId,
      invoiceNumber: effectiveInvoice,
      customerName: customerName,
      customerEmail: customerEmail,
      mobileNumber: mobileNumber,
      carName: carName,
      category: category,
      district: district,
      pickupLocation: pickupLocation,
      pickupDateTime: pickupDateTime,
      dropLocation: dropLocation,
      dropDateTime: dropDateTime,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,
      invoiceDate: invoiceDate,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: filename,
    );
  }
}
