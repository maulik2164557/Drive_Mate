import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/car_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/car_provider.dart';
import '../../../services/database_service.dart';
import '../../../core/utils/location_data.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';

class AdminCarBookingHistoryScreen extends StatefulWidget {
  const AdminCarBookingHistoryScreen({super.key});

  @override
  State<AdminCarBookingHistoryScreen> createState() => _AdminCarBookingHistoryScreenState();
}

class _AdminCarBookingHistoryScreenState extends State<AdminCarBookingHistoryScreen> {
  String _selectedDistrict = 'All';
  String _selectedCategory = 'All';

  final DatabaseService _dbService = DatabaseService();
  final List<String> _districts = LocationData.getAllDistricts();
  static const List<String> _categories = ['All', 'SUV', 'MUV', 'Sedan', 'Hatchback'];

  @override
  Widget build(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);

    // Apply filters
    final filteredCars = carProvider.cars.where((car) {
      if (_selectedDistrict != 'All' && car.district.toLowerCase() != _selectedDistrict.toLowerCase()) {
        return false;
      }
      if (_selectedCategory != 'All' && car.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: const AppNavbar(title: 'Fleet Booking History'),
      body: StreamBuilder<List<BookingModel>>(
        stream: _dbService.getAllBookings(),
        builder: (context, snapshot) {
          final allBookings = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildFilterHeader(filteredCars.length),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: carProvider.isLoading
                      ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                      : _buildCarGrid(filteredCars, allBookings),
                ),
                const SizedBox(height: 24),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterHeader(int carCount) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu, color: Color(0xFF1E3A8A), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Car Fleet Booking Archives',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
              Text(
                '$carCount Fleet Models Matching Filter',
                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Controls Row
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // District Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E3A8A)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    icon: const Icon(Icons.location_on, color: Color(0xFF1E3A8A), size: 20),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All District Offices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ..._districts.map((d) => DropdownMenuItem(value: d, child: Text('$d Office', style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                ),
              ),
              // Car Category Filter Chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Car Type: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1E3A8A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarGrid(List<CarModel> cars, List<BookingModel> allBookings) {
    if (cars.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No car models found matching selected filter criteria.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                _selectedDistrict = 'All';
                _selectedCategory = 'All';
              }),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        final carBookings = allBookings.where((b) => b.carId == car.carId).toList();

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            onTap: () => _openCarBookingHistoryModal(car, carBookings),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    car.imageUrl,
                    height: 145,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 145, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 50)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 12, color: Color(0xFF1E3A8A)),
                            label: Text('${car.district} Office', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            backgroundColor: const Color(0xFFEFF6FF),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${car.category} • ${car.fuelType} • ${car.transmission}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bookmark, size: 16, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 6),
                                Text('${carBookings.length} Total Bookings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1E3A8A)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCarBookingHistoryModal(CarModel car, List<BookingModel> carBookings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        car.imageUrl,
                        width: 70,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 70, height: 50, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(car.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text('${car.district} Depot • ${car.category} • ${carBookings.length} Total Journeys', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            if (carBookings.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No booking history records found for this car model.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: carBookings.length,
                  itemBuilder: (context, index) {
                    final booking = carBookings[index];
                    return FutureBuilder<UserModel?>(
                      future: _dbService.getUserById(booking.userId),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final duration = booking.dropDateTime.difference(booking.pickupDateTime);
                        final hours = duration.inHours;

                        Color statusColor = Colors.orange;
                        if (booking.status == 'Completed') statusColor = Colors.green;
                        if (booking.status == 'Cancelled') statusColor = Colors.red;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Booking #${booking.bookingId.length > 8 ? booking.bookingId.substring(0, 8) : booking.bookingId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Chip(
                                      label: Text(booking.status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      backgroundColor: statusColor,
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                // Customer Details Section
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
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
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Name: ${user?.fullName ?? "User #${booking.userId.substring(0, 5)}"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text('Phone: ${user?.mobileNumber ?? "N/A"}'),
                                        ],
                                      ),
                                      Text('Email: ${user?.email ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Journey Route & Schedule
                                Text('Pickup: ${booking.pickupLocation.isEmpty ? "Depot" : booking.pickupLocation} (${DateFormat("dd MMM, hh:mm a").format(booking.pickupDateTime)})', style: const TextStyle(fontSize: 12)),
                                Text('Drop: ${booking.dropLocation.isEmpty ? "Depot" : booking.dropLocation} (${DateFormat("dd MMM, hh:mm a").format(booking.dropDateTime)})', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Duration: $hours hrs (${(hours / 24).toStringAsFixed(1)} Days)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('Fare: ₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
                                  ],
                                ),
                                if (booking.status == 'Cancelled' && booking.refundAmount != null) ...[
                                  const SizedBox(height: 6),
                                  Text('Refund: ₹${booking.refundAmount!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
