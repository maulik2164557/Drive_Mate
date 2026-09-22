import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/car_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../core/utils/calculation_utils.dart';
import '../../../models/booking_model.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import 'package:intl/intl.dart';

class CarDetailsScreen extends StatelessWidget {
  final CarModel car;
  final DateTime pickup;
  final DateTime drop;

  const CarDetailsScreen({
    super.key,
    required this.car,
    required this.pickup,
    required this.drop,
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
                      const Text('Booking Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildScheduleItem('Pickup', pickup),
                      _buildScheduleItem('Drop', drop),
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

  Widget _buildScheduleItem(String label, DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ${DateFormat('dd MMM yyyy, hh:mm a').format(dt)}'),
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context, dynamic user, double amount) async {
    // 1. KYC Check
    if (user.kycStatus != 'Verified') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('KYC Verification Required'),
          content: const Text('Please upload your identification documents in your Profile before booking.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 400,
        child: Column(
          children: [
            const Text('Payment Options', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _paymentItem(Icons.credit_card, 'Credit/Debit Card', context, amount),
            _paymentItem(Icons.qr_code, 'Scan QR Code', context, amount),
            _paymentItem(Icons.account_balance_wallet, 'UPI ID', context, amount),
            const Spacer(),
            Text('Simulating Stripe Test Mode', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _paymentItem(IconData icon, String label, BuildContext context, double amount) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(label),
      onTap: () => _processPayment(context, amount),
    );
  }

  void _processPayment(BuildContext context, double amount) async {
    Navigator.pop(context); // Close modal
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.pop(context); // Close loader

    // Success - Create Booking
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final booking = BookingModel(
      bookingId: '', // Firestore will generate
      userId: authProvider.userModel!.uid,
      carId: car.carId,
      pickupLocation: '${car.district} Office / Depot',
      pickupDateTime: pickup,
      dropLocation: '${car.district} Office / Depot',
      dropDateTime: drop,
      totalPrice: amount,
      status: 'Pending Journey',
      createdAt: DateTime.now(),
    );

    await bookingProvider.createBooking(booking);
    if (!context.mounted) return;

    // Show Success Receipt
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Booking for ${car.name} is confirmed at ${car.district} depot.'),
            const SizedBox(height: 8),
            Text('Total Paid: ₹${amount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Back to dashboard
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }
}
