import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking_model.dart';
import '../../../models/car_model.dart';
import '../../../models/review_model.dart';
import '../../../services/database_service.dart';
import '../../../services/receipt_pdf_service.dart';
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
    final pendingBookings = allBookings.where((b) => b.effectiveStatus == 'Pending Journey').toList();
    final completedBookings = allBookings.where((b) => b.effectiveStatus == 'Completed').toList();
    final cancelledBookings = allBookings.where((b) => b.effectiveStatus == 'Cancelled').toList();

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

            final currentStatus = booking.effectiveStatus;
            Color statusColor = Colors.orange;
            IconData statusIcon = Icons.pending_actions;
            if (currentStatus == 'Completed') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (currentStatus == 'Running Journey') {
              statusColor = Colors.blue;
              statusIcon = Icons.directions_run;
            } else if (currentStatus == 'Cancelled') {
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
                    // Header: Booking Ref, Invoice No & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 2),
                            Text(
                              'Invoice: ${booking.effectiveInvoiceNumber}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Chip(
                          avatar: Icon(statusIcon, size: 16, color: Colors.white),
                          label: Text(
                            currentStatus.toUpperCase(),
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
                    // Review & Rating Section for Completed Journeys
                    if (booking.effectiveStatus == 'Completed') ...[
                      const SizedBox(height: 16),
                      FutureBuilder<ReviewModel?>(
                        future: _dbService.getReviewForBooking(booking.bookingId),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 20, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                          }
                          final review = snap.data;
                          if (review != null) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.verified, color: Colors.green, size: 16),
                                          SizedBox(width: 4),
                                          Text('Reviewed & Rated ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          Text(' Car: ${review.carRating.toStringAsFixed(1)} ★ | Mgmt: ${review.managementRating.toStringAsFixed(1)} ★', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (review.carReviewComment.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text('Vehicle Feedback: "${review.carReviewComment}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                  if (review.managementReviewComment.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('System Mgmt Feedback: "${review.managementReviewComment}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ],
                              ),
                            );
                          } else {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showReviewModal(context, booking, car),
                                icon: const Icon(Icons.star_rate, size: 18),
                                label: const Text('Rate & Review Journey'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    // Action Buttons: Invoice PDF & Cancellation
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final userModel = Provider.of<AuthProvider>(context, listen: false).userModel;
                            ReceiptPdfService.downloadReceiptPdf(
                              bookingId: booking.bookingId,
                              invoiceNumber: booking.effectiveInvoiceNumber,
                              customerName: userModel?.fullName ?? 'Valued Customer',
                              customerEmail: userModel?.email ?? 'customer@drivemate.com',
                              mobileNumber: userModel?.mobileNumber ?? 'N/A',
                              carName: car?.name ?? 'DriveMate Vehicle',
                              category: car?.category ?? 'Standard',
                              district: car?.district ?? 'Gujarat',
                              pickupLocation: booking.pickupLocation,
                              pickupDateTime: booking.pickupDateTime,
                              dropLocation: booking.dropLocation,
                              dropDateTime: booking.dropDateTime,
                              totalPrice: booking.totalPrice,
                              paymentMethod: 'UPI / Online Card',
                              invoiceDate: booking.createdAt,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF1E3A8A)),
                          label: const Text('Invoice (PDF)', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                        if (booking.effectiveStatus == 'Pending Journey') ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _cancelBooking(booking),
                            icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                            label: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
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

  void _showReviewModal(BuildContext context, BookingModel booking, CarModel? car) {
    double carStars = 5.0;
    double mgmtStars = 5.0;
    final carCommentCtrl = TextEditingController();
    final mgmtCommentCtrl = TextEditingController();
    final authUser = Provider.of<AuthProvider>(context, listen: false).userModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.rate_review, color: Color(0xFF1E3A8A), size: 28),
                        const SizedBox(width: 8),
                        Text('Rate Your Completed Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 24),

                // 1. Car Rating Section
                Text('1. Rate Vehicle: ${car?.name ?? "Car"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return IconButton(
                      icon: Icon(
                        starVal <= carStars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setModalState(() => carStars = starVal.toDouble()),
                    );
                  }),
                ),
                TextField(
                  controller: carCommentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Write your review for this car...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // 2. System Management Rating Section
                const Text('2. Rate DriveMate System & Depot Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    final starVal = index + 1;
                    return IconButton(
                      icon: Icon(
                        starVal <= mgmtStars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setModalState(() => mgmtStars = starVal.toDouble()),
                    );
                  }),
                ),
                TextField(
                  controller: mgmtCommentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Write your review for system & depot management...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final review = ReviewModel(
                        reviewId: '',
                        bookingId: booking.bookingId,
                        userId: booking.userId,
                        userName: authUser?.fullName ?? 'Valued Customer',
                        carId: booking.carId,
                        carName: car?.name ?? 'Vehicle',
                        carRating: carStars,
                        carReviewComment: carCommentCtrl.text.trim(),
                        managementRating: mgmtStars,
                        managementReviewComment: mgmtCommentCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      await _dbService.addReview(review);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        setState(() {}); // Refresh list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you! Your rating and review have been submitted.'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Submit Review & Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
