import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_model.dart';
import '../../../models/car_model.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';

class AdminCompletedJourneysScreen extends StatelessWidget {
  const AdminCompletedJourneysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: const AppNavbar(title: 'Completed Journeys'),
      body: StreamBuilder<List<BookingModel>>(
        stream: dbService.getAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = snapshot.data ?? [];
          final completedBookings = allBookings.where((b) => b.effectiveStatus == 'Completed').toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Page Header Banner
                Container(
                  width: double.infinity,
                  color: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 32),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Completed Journeys Archives',
                                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Full record of concluded car rentals, customer details, and total fares',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Chip(
                            avatar: const Icon(Icons.verified, size: 16, color: Colors.green),
                            label: Text(
                              '${completedBookings.length} Concluded Trips',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: completedBookings.isEmpty
                          ? Container(
                              height: 350,
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No completed journeys found in database.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: completedBookings.length,
                              itemBuilder: (context, index) {
                                final booking = completedBookings[index];
                                return FutureBuilder<Map<String, dynamic>>(
                                  future: _fetchDetails(booking, dbService),
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
                                    }

                                    final car = snap.data!['car'] as CarModel?;
                                    final user = snap.data!['user'] as UserModel?;
                                    final duration = booking.dropDateTime.difference(booking.pickupDateTime);
                                    final hours = duration.inHours;

                                    return Card(
                                      elevation: 3,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header Row: Vehicle + Status Badge
                                            Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: car?.imageUrl != null && car!.imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          car.imageUrl,
                                                          width: 90,
                                                          height: 65,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(width: 90, height: 65, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                                                        )
                                                      : Container(width: 90, height: 65, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 40)),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(car?.name ?? "Car ID: ${booking.carId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                      Text('${car?.category ?? "N/A"} • ${car?.fuelType ?? "N/A"} • ${car?.transmission ?? "N/A"} • ${car?.seatingCapacity ?? 0} Seater', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                      const SizedBox(height: 2),
                                                      Text('District Depot: ${car?.district ?? "Gujarat"} Office', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                                Chip(
                                                  avatar: const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                                  label: const Text('COMPLETED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  backgroundColor: Colors.green.shade700,
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 24),

                                            // Customer Details Container
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.person, size: 16, color: Color(0xFF1E3A8A)),
                                                      SizedBox(width: 6),
                                                      Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('Name: ${user?.fullName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                      Text('Mobile: ${user?.mobileNumber ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text('Email: ${user?.email ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                      Text('KYC Status: ${user?.kycStatus ?? "Pending"}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: user?.kycStatus == 'Verified' ? Colors.green : Colors.orange)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Route & Schedule Container
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.route, size: 16, color: Color(0xFF1E3A8A)),
                                                      SizedBox(width: 6),
                                                      Text('Journey Schedule & Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.trip_origin, size: 14, color: Colors.green),
                                                      const SizedBox(width: 6),
                                                      Expanded(child: Text('Pickup: ${booking.pickupLocation}', style: const TextStyle(fontSize: 13))),
                                                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.pickupDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 14, color: Colors.red),
                                                      const SizedBox(width: 6),
                                                      Expanded(child: Text('Drop: ${booking.dropLocation}', style: const TextStyle(fontSize: 13))),
                                                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.dropDateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Fare & Duration Summary
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Duration: $hours Hours (${(hours / 24).toStringAsFixed(1)} Days)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                                Text('Total Fare Paid: ₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchDetails(BookingModel booking, DatabaseService dbService) async {
    final user = await dbService.getUserById(booking.userId);
    final car = await dbService.getCarById(booking.carId);
    return {'user': user, 'car': car};
  }
}
