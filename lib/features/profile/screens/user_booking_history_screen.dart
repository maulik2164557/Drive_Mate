import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking_model.dart';
import '../../../models/car_model.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';

class UserBookingHistoryScreen extends StatefulWidget {
  const UserBookingHistoryScreen({super.key});

  @override
  State<UserBookingHistoryScreen> createState() => _UserBookingHistoryScreenState();
}

class _UserBookingHistoryScreenState extends State<UserBookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        appBar: AppNavbar(title: 'Booking History'),
        body: Center(child: Text('Please sign in to view your booking history.')),
      );
    }

    final allBookings = bookingProvider.userBookings;
    final pendingBookings = allBookings.where((b) => b.status == 'Pending Journey').toList();
    final completedBookings = allBookings.where((b) => b.status == 'Completed').toList();
    final cancelledBookings = allBookings.where((b) => b.status == 'Cancelled').toList();

    return Scaffold(
      appBar: const AppNavbar(title: 'My Booking History'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1E3A8A),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'All (${allBookings.length})'),
                  Tab(text: 'Pending (${pendingBookings.length})'),
                  Tab(text: 'Completed (${completedBookings.length})'),
                  Tab(text: 'Cancelled (${cancelledBookings.length})'),
                ],
              ),
            ),
            SizedBox(
              height: 700,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(allBookings),
                  _buildBookingList(pendingBookings),
                  _buildBookingList(completedBookings),
                  _buildBookingList(cancelledBookings),
                ],
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No bookings found in this section.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return FutureBuilder<CarModel?>(
          future: _dbService.getCarById(booking.carId),
          builder: (context, snapshot) {
            final car = snapshot.data;
            final duration = booking.dropDateTime.difference(booking.pickupDateTime);
            final hours = duration.inHours;

            Color statusColor = Colors.orange;
            IconData statusIcon = Icons.pending_actions;
            if (booking.status == 'Completed') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (booking.status == 'Cancelled') {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
            }

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Booking Ref & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A)),
                            const SizedBox(width: 8),
                            Text(
                              'Booking #${booking.bookingId.length > 8 ? booking.bookingId.substring(0, 8) : booking.bookingId}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Chip(
                          avatar: Icon(statusIcon, size: 16, color: Colors.white),
                          label: Text(
                            booking.status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: statusColor,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Vehicle Info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: car?.imageUrl != null && car!.imageUrl.isNotEmpty
                              ? Image.network(
                                  car.imageUrl,
                                  width: 90,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 90, height: 70, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                                )
                              : Container(width: 90, height: 70, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 40)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(car?.name ?? 'Car Vehicle #${booking.carId.substring(0, 5)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              if (car != null) ...[
                                const SizedBox(height: 2),
                                Text('${car.category} • ${car.fuelType} • ${car.transmission} • ${car.seatingCapacity} Seater', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text('${car.district} Office Depot', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Detailed Journey Route & Times
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Pickup: ${booking.pickupLocation.isEmpty ? "Depot Location" : booking.pickupLocation}', style: const TextStyle(fontSize: 13))),
                              Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.pickupDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Drop: ${booking.dropLocation.isEmpty ? "Depot Location" : booking.dropLocation}', style: const TextStyle(fontSize: 13))),
                              Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.dropDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary & Pricing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duration: $hours Hours (${(hours / 24).toStringAsFixed(1)} Days)', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('Booked On: ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ],
                        ),
                      ],
                    ),
                    if (booking.status == 'Cancelled' && booking.refundAmount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Text('Refund Processed: ₹${booking.refundAmount!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    // Cancellation Action
                    if (booking.status == 'Pending Journey') ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking),
                          icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                          label: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _cancelBooking(BookingModel booking) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? Refund policy will apply.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<BookingProvider>(context, listen: false).cancelBooking(
        booking.bookingId,
        booking.pickupDateTime,
        booking.totalPrice,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully.'), backgroundColor: Colors.orange),
        );
      }
    }
  }
}
