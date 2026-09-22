import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../../../models/car_model.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import 'package:intl/intl.dart';

class JourneyOperationsScreen extends StatelessWidget {
  const JourneyOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: const AppNavbar(),
      body: StreamBuilder<List<BookingModel>>(
        stream: dbService.getAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text('No journey records found.', style: TextStyle(fontSize: 18)),
              ),
            );
          }

          final allBookings = snapshot.data!;
          final now = DateTime.now();

          final activeJourneys = allBookings.where((b) => 
            b.status == 'Pending Journey' && 
            b.pickupDateTime.isBefore(now) && 
            b.dropDateTime.isAfter(now)
          ).toList();
          
          final pendingJourneys = allBookings.where((b) => 
            b.status == 'Pending Journey' && 
            b.pickupDateTime.isAfter(now)
          ).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFF1E3A8A),
                  child: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.amber,
                    tabs: [
                      Tab(icon: Icon(Icons.directions_run), text: 'Currently Running Journeys'),
                      Tab(icon: Icon(Icons.schedule), text: 'Pending & Upcoming Journeys'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildJourneyList(activeJourneys, dbService, isRunning: true),
                      _buildJourneyList(pendingJourneys, dbService, isRunning: false),
                    ],
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

  Widget _buildJourneyList(List<BookingModel> bookings, DatabaseService dbService, {required bool isRunning}) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isRunning ? Icons.no_crash : Icons.event_available, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                isRunning ? 'No currently running journeys at this time.' : 'No pending or upcoming journeys scheduled.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return FutureBuilder<Map<String, dynamic>>(
          future: _getJourneyDetails(booking, dbService),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            final user = snapshot.data!['user'] as UserModel?;
            final car = snapshot.data!['car'] as CarModel?;
            final duration = booking.dropDateTime.difference(booking.pickupDateTime);
            final hours = duration.inHours;

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: CircleAvatar(
                  backgroundColor: isRunning ? Colors.orange[100] : Colors.blue[100],
                  child: Icon(isRunning ? Icons.directions_car : Icons.access_time, color: isRunning ? Colors.orange[900] : Colors.blue[900]),
                ),
                title: Text(
                  '${car?.name ?? "Car ID: ${booking.carId}"}  —  Customer: ${user?.fullName ?? "User ID: ${booking.userId}"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  'Duration: $hours hrs (${DateFormat('dd MMM hh:mm a').format(booking.pickupDateTime)} to ${DateFormat('dd MMM hh:mm a').format(booking.dropDateTime)}) • Total: ₹${booking.totalPrice}',
                  style: const TextStyle(fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        // Car Details Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (car?.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  car!.imageUrl,
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(width: 100, height: 80, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Complete Car Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 15)),
                                  Text('Model: ${car?.name ?? "N/A"} (${car?.category ?? "N/A"})'),
                                  Text('Depot: ${car?.district ?? "Gujarat"} Office'),
                                  Text('Fuel Type: ${car?.fuelType ?? "N/A"} | Transmission: ${car?.transmission ?? "N/A"}'),
                                  Text('Seating: ${car?.seatingCapacity ?? "N/A"} Seater | Rate: ₹${car?.pricePerHour ?? 0}/hr'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        // Customer Details Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Complete Customer Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Customer Name: ${user?.fullName ?? "N/A"}'),
                            Text('Email Address: ${user?.email ?? "N/A"}'),
                            Text('Mobile Number: ${user?.mobileNumber ?? "N/A"}'),
                            Row(
                              children: [
                                const Text('KYC Verification Status: '),
                                Chip(
                                  label: Text(user?.kycStatus ?? 'Pending'),
                                  backgroundColor: user?.kycStatus == 'Verified' ? Colors.green[100] : Colors.orange[100],
                                  labelStyle: TextStyle(color: user?.kycStatus == 'Verified' ? Colors.green[800] : Colors.orange[800], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        // Journey Schedule & Locations Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Journey Schedule & Locations', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Pickup Location: ${booking.pickupLocation.isEmpty ? "Main Depot / Office" : booking.pickupLocation}'),
                            Text('Pickup Time: ${DateFormat('EEE, dd MMM yyyy, hh:mm a').format(booking.pickupDateTime)}'),
                            const SizedBox(height: 4),
                            Text('Drop Location: ${booking.dropLocation.isEmpty ? "Main Depot / Office" : booking.dropLocation}'),
                            Text('Drop Time: ${DateFormat('EEE, dd MMM yyyy, hh:mm a').format(booking.dropDateTime)}'),
                            const SizedBox(height: 4),
                            Text('Total Time Duration: $hours Hours (${(hours / 24).toStringAsFixed(1)} Days)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text('Total Booking Cost: ₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getJourneyDetails(BookingModel booking, DatabaseService dbService) async {
    final user = await dbService.getUserById(booking.userId);
    final car = await dbService.getCarById(booking.carId);
    return {'user': user, 'car': car};
  }
}

