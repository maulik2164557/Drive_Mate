import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/car_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../core/utils/calculation_utils.dart';
import '../../../models/booking_model.dart';
import '../../../services/receipt_pdf_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import 'package:intl/intl.dart';

class CarDetailsScreen extends StatelessWidget {
  final CarModel car;
  final DateTime pickup;
  final DateTime drop;
  final String pickupLocation;
  final String dropLocation;

  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.pickup,
    required this.drop,
    required this.pickupLocation,
    required this.dropLocation,
  });

  @override
  Widget build(BuildContext context) {
    final double totalPrice = CalculationUtils.calculateTotalPrice(car.pricePerHour, pickup, drop);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel!;

    return Scaffold(
      appBar: AppNavbar(title: car.name),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          car.imageUrl,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 280, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 80)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(car.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                Text(car.category, style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                              ],
                            ),
                          ),
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 16, color: Color(0xFF1E3A8A)),
                            label: Text('${car.district} Office', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            backgroundColor: const Color(0xFFEFF6FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('District Depot', '${car.district}, Gujarat Office'),
                      _buildInfoRow('Fuel Type', car.fuelType),
                      _buildInfoRow('Seating Capacity', '${car.seatingCapacity} Seater'),
                      _buildInfoRow('Transmission', car.transmission),
                      const Divider(height: 32),
                      const Text('Booking Schedule & Depot Route', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          children: [
                            // Pickup Location & Time Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.trip_origin, color: Colors.green, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('PICKUP LOCATION & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        pickupLocation.trim().isNotEmpty ? pickupLocation.trim() : '${car.district} Office / Main Depot',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEE, dd MMM yyyy, hh:mm a').format(pickup),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Drop Location & Time Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('DROP LOCATION & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(
                                        dropLocation.trim().isNotEmpty ? dropLocation.trim() : '${car.district} Office / Main Depot',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEE, dd MMM yyyy, hh:mm a').format(drop),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Price', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('₹${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => _handleBooking(context, user, totalPrice),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                          child: const Text('Confirm Booking', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context, dynamic user, double amount) async {
    // 0. Schedule Validity Check
    if (!drop.isAfter(pickup)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid schedule: Drop date & time must be after pickup date & time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. KYC Check
    if (user.kycStatus != 'Verified') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('KYC Verification Required'),
            ],
          ),
          content: const Text(
            'Your KYC status is pending. Please upload your Aadhaar Card and Driving Licence in your profile to complete verification before booking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Go to KYC Page'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Stripe Simulation
    _showPaymentModal(context, amount);
  }

  void _showPaymentModal(BuildContext context, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Payment Method', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 8),
            Text('Total Payable: ₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const Divider(height: 24),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.credit_card, color: Color(0xFF1E3A8A))),
              title: const Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Visa, MasterCard, RuPay (Stripe Test)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showCardPaymentModal(context, amount);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.qr_code, color: Color(0xFF1E3A8A))),
              title: const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant UPI QR code generation'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showQrPaymentModal(context, amount);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A8A))),
              title: const Text('UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('GPay, PhonePe, Paytm, BHIM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showUpiPaymentModal(context, amount);
              },
            ),
            const SizedBox(height: 16),
            Text('Secured by Stripe Test Mode', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showCardPaymentModal(BuildContext context, double amount) {
    final cardNumCtrl = TextEditingController(text: '4242 4242 4242 4242');
    final expiryCtrl = TextEditingController(text: '12/28');
    final cvvCtrl = TextEditingController(text: '123');
    final nameCtrl = TextEditingController(text: 'Maulik Patoliya');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF1E3A8A), size: 28),
                  SizedBox(width: 10),
                  Text('Card Payment (Stripe Test)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Cardholder Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cardNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Card Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)),
                validator: (v) => v == null || v.length < 12 ? 'Enter valid card number' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: expiryCtrl,
                      decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.length < 3 ? 'Invalid CVV' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _executeSuccessfulPayment(ctx, amount);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Pay ₹${amount.toStringAsFixed(2)} Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrPaymentModal(BuildContext context, double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code, color: Color(0xFF1E3A8A), size: 28),
                SizedBox(width: 10),
                Text('Scan UPI QR Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Scan with GPay, PhonePe, Paytm, or BHIM', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2, size: 150, color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 8),
                  Text('DriveMate Merchant UPI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _executeSuccessfulPayment(ctx, amount),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Simulate QR Scan & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpiPaymentModal(BuildContext context, double amount) {
    final upiCtrl = TextEditingController(text: 'maulik@oksbi');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A8A), size: 28),
                  SizedBox(width: 10),
                  Text('Pay via UPI ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: upiCtrl,
                decoration: const InputDecoration(labelText: 'Enter UPI ID (e.g. username@okhdfc)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.alternate_email)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid UPI ID' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _executeSuccessfulPayment(ctx, amount);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Verify & Pay ₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeSuccessfulPayment(BuildContext parentContext, double amount) async {
    final bookingProvider = Provider.of<BookingProvider>(parentContext, listen: false);
    final authProvider = Provider.of<AuthProvider>(parentContext, listen: false);
    final user = authProvider.userModel;
    final userId = user!.uid;
    final carId = car.carId;

    // Generate unique official Invoice Number
    final invoiceNumber = ReceiptPdfService.generateInvoiceNumber();

    Navigator.pop(parentContext); // Close payment modal sheet

    // Show Success Payment Receipt Dialog immediately
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 12),
            Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INVOICE NUMBER',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        Text(
                          invoiceNumber,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Booking for ${car.name} is confirmed.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Pickup: $pickupLocation\n(${DateFormat('dd MMM yyyy, hh:mm a').format(pickup)})'),
            const SizedBox(height: 4),
            Text('Drop: $dropLocation\n(${DateFormat('dd MMM yyyy, hh:mm a').format(drop)})'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount Paid:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Official PDF invoice ($invoiceNumber.pdf) generated & downloaded automatically.',
                    style: const TextStyle(color: Colors.black87, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              ReceiptPdfService.downloadReceiptPdf(
                bookingId: invoiceNumber,
                invoiceNumber: invoiceNumber,
                customerName: user.fullName,
                customerEmail: user.email,
                mobileNumber: user.mobileNumber,
                carName: car.name,
                category: car.category,
                district: car.district,
                pickupLocation: pickupLocation,
                pickupDateTime: pickup,
                dropLocation: dropLocation,
                dropDateTime: drop,
                totalPrice: amount,
                paymentMethod: 'UPI / Card Online',
              );
            },
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Download Invoice PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close receipt dialog
              Navigator.pop(parentContext); // Pop CarDetailsScreen back to UserDashboard
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );

    // Trigger Automatic PDF Receipt Download on Device
    try {
      await ReceiptPdfService.downloadReceiptPdf(
        bookingId: invoiceNumber,
        invoiceNumber: invoiceNumber,
        customerName: user.fullName,
        customerEmail: user.email,
        mobileNumber: user.mobileNumber,
        carName: car.name,
        category: car.category,
        district: car.district,
        pickupLocation: pickupLocation,
        pickupDateTime: pickup,
        dropLocation: dropLocation,
        dropDateTime: drop,
        totalPrice: amount,
        paymentMethod: 'UPI / Card Online',
      );
    } catch (e) {
      debugPrint('Receipt PDF download note: $e');
    }

    // Save booking to Firestore in background and update history
    try {
      final booking = BookingModel(
        bookingId: '',
        invoiceNumber: invoiceNumber,
        userId: userId,
        carId: carId,
        pickupLocation: pickupLocation,
        pickupDateTime: pickup,
        dropLocation: dropLocation,
        dropDateTime: drop,
        totalPrice: amount,
        status: 'Pending Journey',
        createdAt: DateTime.now(),
      );

      await bookingProvider.createBooking(booking);
      bookingProvider.fetchUserBookings(userId);
    } catch (e) {
      debugPrint('Booking creation background note: $e');
    }
  }
}
