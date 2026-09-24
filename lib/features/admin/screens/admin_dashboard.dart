import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/car_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/car_model.dart';
import '../../../models/booking_model.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../core/utils/location_data.dart';
import '../../../core/widgets/app_footer.dart';
import '../../../core/widgets/app_navbar.dart';
import 'add_car_screen.dart';
import 'edit_car_screen.dart';
import 'journey_operations_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  String _selectedDistrict = 'All';
  final DatabaseService _dbService = DatabaseService();
  final List<String> _districts = LocationData.getAllDistricts();

  @override
  Widget build(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const AppNavbar(title: 'Admin Dashboard'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAdminMenuBar(context),
            _currentIndex == 0 
                ? _buildFleetView(carProvider)
                : _buildAdminProfile(authProvider),
            const AppFooter(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Fleet Management'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Admin Profile'),
        ],
      ),
    );
  }

  Widget _buildAdminMenuBar(BuildContext context) {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(
                'Gujarat State Operations Workspace',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JourneyOperationsScreen())),
            icon: const Icon(Icons.analytics, size: 18),
            label: const Text('Live Journey Operations Screen'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetView(CarProvider carProvider) {
    return StreamBuilder<List<BookingModel>>(
      stream: _dbService.getAllBookings(),
      builder: (context, snapshot) {
        final allBookings = snapshot.data ?? [];
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

        // District filtering for cars
        final filteredCars = _selectedDistrict == 'All'
            ? carProvider.cars
            : carProvider.cars.where((c) => c.district.toLowerCase() == _selectedDistrict.toLowerCase()).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDistrictFilterHeader(),
              const SizedBox(height: 20),
              _buildMetricsGrid(filteredCars, activeJourneys, pendingJourneys),
              const SizedBox(height: 32),
              _buildFleetHeader(context, filteredCars.length),
              const SizedBox(height: 16),
              _buildFleetList(carProvider, filteredCars, activeJourneys),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistrictFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF1E3A8A), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Gujarat District Office',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                ),
                Text(
                  _selectedDistrict == 'All' 
                      ? 'Viewing cars across all 33 districts of Gujarat state'
                      : 'Displaying fleet mounted at $_selectedDistrict District Office depot',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1E3A8A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDistrict,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All Gujarat (All Districts)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ..._districts.map((d) => DropdownMenuItem(value: d, child: Text('$d District Office'))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDistrict = val);
                },
              ),
            ),
          ),
          if (_selectedDistrict != 'All') ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              tooltip: 'Reset to All Districts',
              onPressed: () => setState(() => _selectedDistrict = 'All'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(List<CarModel> cars, List<BookingModel> activeJourneys, List<BookingModel> pendingJourneys) {
    int totalUnits = cars.fold(0, (sum, car) => sum + car.totalUnits);
    final carIds = cars.map((c) => c.carId).toSet();
    final activeForDistrict = activeJourneys.where((b) => carIds.contains(b.carId)).toList();
    final pendingForDistrict = pendingJourneys.where((b) => carIds.contains(b.carId)).toList();

    int activeCount = activeForDistrict.length;
    int pendingCount = pendingForDistrict.length;
    int inGarage = (totalUnits - activeCount).clamp(0, 9999);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _metricCard(
          'Total Fleet Units',
          totalUnits.toString(),
          Colors.blue.shade700,
          Icons.directions_car_filled,
          subtitle: 'Mounted in ${_selectedDistrict == "All" ? "Gujarat" : _selectedDistrict}',
        ),
        _metricCard(
          'Units On Journey',
          activeCount.toString(),
          Colors.orange.shade800,
          Icons.directions_run,
          subtitle: 'Click to view full details',
          isClickable: true,
          onTap: () => _showActiveJourneysModal(context, activeForDistrict),
        ),
        _metricCard(
          'Future Reserved',
          pendingCount.toString(),
          Colors.teal.shade700,
          Icons.event_available,
          subtitle: 'Click to view reservations',
          isClickable: true,
          onTap: () => _showPendingJourneysModal(context, pendingForDistrict),
        ),
        _metricCard(
          'Units In Garage',
          inGarage.toString(),
          Colors.indigo.shade700,
          Icons.garage,
          subtitle: 'Click for garage vehicles',
          isClickable: true,
          onTap: () => _showGarageCarsModal(context, cars, activeJourneys, pendingJourneys),
        ),
      ],
    );
  }

  Widget _metricCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    String? subtitle,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: isClickable ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isClickable ? BorderSide(color: color.withOpacity(0.4), width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: 8),
                  Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isClickable ? color : Colors.grey,
                    fontWeight: isClickable ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFleetHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fleet Inventory ($count Models)', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(
              _selectedDistrict == 'All' 
                  ? 'Click on any car to edit, delete or view distribution'
                  : 'Filtered to cars in $_selectedDistrict District depot',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCarScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Add New Car'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFleetList(CarProvider provider, List<CarModel> cars, List<BookingModel> activeJourneys) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cars.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.car_repair, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _selectedDistrict == 'All' ? 'No cars present in fleet' : 'No cars currently mounted in $_selectedDistrict district',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Click "Add New Car" to mount vehicles in this Gujarat district.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCarScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add New Car'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        int activeForCar = activeJourneys.where((b) => b.carId == car.carId).length;
        int inGarageForCar = (car.totalUnits - activeForCar).clamp(0, 9999);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showCarDetailsModal(context, provider, car, activeForCar, inGarageForCar),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      car.imageUrl, 
                      width: 90, 
                      height: 90, 
                      fit: BoxFit.cover, 
                      errorBuilder: (_, _, _) => Container(
                        width: 90, 
                        height: 90, 
                        color: Colors.grey[200], 
                        child: const Icon(Icons.directions_car, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: Color(0xFF1E3A8A)),
                                  const SizedBox(width: 2),
                                  Text('${car.district} Office', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${car.category} • ${car.fuelType} • ${car.transmission} • ${car.seatingCapacity} Seater'),
                        const SizedBox(height: 4),
                        Text('Price: ₹${car.pricePerHour}/hr', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text('Total: ${car.totalUnits}'),
                              backgroundColor: Colors.blue[50],
                              padding: EdgeInsets.zero,
                              labelStyle: const TextStyle(fontSize: 11),
                            ),
                            Chip(
                              label: Text('In Garage: $inGarageForCar'),
                              backgroundColor: Colors.green[50],
                              padding: EdgeInsets.zero,
                              labelStyle: TextStyle(fontSize: 11, color: Colors.green[800]),
                            ),
                            Chip(
                              label: Text('On Journey: $activeForCar'),
                              backgroundColor: Colors.orange[50],
                              padding: EdgeInsets.zero,
                              labelStyle: TextStyle(fontSize: 11, color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue), 
                        tooltip: 'Update Car',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditCarScreen(car: car))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), 
                        tooltip: 'Delete Car',
                        onPressed: () => _confirmDelete(context, provider, car),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // MODAL 1: Complete details of cars currently on journey
  void _showActiveJourneysModal(BuildContext context, List<BookingModel> activeJourneys) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run, color: Colors.orange, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Cars Currently On Journey (${activeJourneys.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete car details, customer details, and live trip journey schedules',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            if (activeJourneys.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No cars are currently on a journey for this district selection.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: activeJourneys.length,
                  itemBuilder: (context, index) {
                    final booking = activeJourneys[index];
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchJourneyDetails(booking),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
                        }

                        final car = snapshot.data!['car'] as CarModel?;
                        final user = snapshot.data!['user'] as UserModel?;
                        final duration = booking.dropDateTime.difference(booking.pickupDateTime);
                        final hours = duration.inHours;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Car Header Row
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        car?.imageUrl ?? '',
                                        width: 80,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(width: 80, height: 60, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(car?.name ?? 'Car ID: ${booking.carId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                          Text('${car?.category ?? "N/A"} • ${car?.fuelType ?? "N/A"} • ${car?.transmission ?? "N/A"} • ${car?.seatingCapacity ?? 0} Seater', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(height: 2),
                                          Text('Depot: ${car?.district ?? "Gujarat"} Office', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      avatar: const Icon(Icons.directions_car, size: 14, color: Colors.white),
                                      label: const Text('ON JOURNEY', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      backgroundColor: Colors.orange.shade700,
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                // Complete Customer Details
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.person, size: 18, color: Color(0xFF1E3A8A)),
                                          SizedBox(width: 6),
                                          Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Name: ${user?.fullName ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text('Mobile: ${user?.mobileNumber ?? "N/A"}'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Email: ${user?.email ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          Row(
                                            children: [
                                              const Text('KYC: ', style: TextStyle(fontSize: 12)),
                                              Text(
                                                user?.kycStatus ?? 'Pending',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: user?.kycStatus == 'Verified' ? Colors.green : Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Journey Schedule & Locations
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.route, size: 18, color: Color(0xFF1E3A8A)),
                                          SizedBox(width: 6),
                                          Text('Journey Duration & Route Locations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A))),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.trip_origin, size: 16, color: Colors.green),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text('Pickup: ${booking.pickupLocation.isEmpty ? "Main Depot" : booking.pickupLocation}')),
                                          Text(DateFormat('dd MMM hh:mm a').format(booking.pickupDateTime), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text('Drop: ${booking.dropLocation.isEmpty ? "Main Depot" : booking.dropLocation}')),
                                          Text(DateFormat('dd MMM hh:mm a').format(booking.dropDateTime), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Duration: $hours Hours (${(hours / 24).toStringAsFixed(1)} Days)', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                          Text('Total Booking Cost: ₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                        ],
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
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // MODAL 2: Complete details of cars currently in garage with future booking status
  void _showGarageCarsModal(BuildContext context, List<CarModel> cars, List<BookingModel> activeJourneys, List<BookingModel> pendingJourneys) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.garage, color: Color(0xFF1E3A8A), size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Cars Currently In Garage',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live garage inventory and upcoming future reserved bookings',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  final car = cars[index];
                  int activeForCar = activeJourneys.where((b) => b.carId == car.carId).length;
                  int inGarageForCar = (car.totalUnits - activeForCar).clamp(0, 9999);
                  final futureBookings = pendingJourneys.where((b) => b.carId == car.carId).toList();
                  bool isBookedForFuture = futureBookings.isNotEmpty;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  car.imageUrl,
                                  width: 85,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(width: 85, height: 65, color: Colors.grey[200], child: const Icon(Icons.directions_car)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                    Text('${car.category} • ${car.fuelType} • ${car.transmission} • ${car.seatingCapacity} Seater', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text('Office Depot: ${car.district}, Gujarat', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                                    Text('Units in Garage: $inGarageForCar / ${car.totalUnits}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              // Prominent Status Chip
                              if (isBookedForFuture)
                                Chip(
                                  avatar: const Icon(Icons.event_seat, size: 14, color: Colors.white),
                                  label: const Text('Booked for future journey', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.amber.shade800,
                                )
                              else
                                Chip(
                                  avatar: const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                  label: const Text('Available in Garage', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.green.shade700,
                                ),
                            ],
                          ),
                          // If booked for future journey, show the future journey details
                          if (isBookedForFuture) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.amber.shade900),
                                      const SizedBox(width: 6),
                                      Text('Upcoming Future Journey Details (${futureBookings.length} Scheduled)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...futureBookings.map((b) {
                                    final dur = b.dropDateTime.difference(b.pickupDateTime);
                                    return FutureBuilder<UserModel?>(
                                      future: _dbService.getUserById(b.userId),
                                      builder: (context, userSnap) {
                                        final user = userSnap.data;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Booked by: ${user?.fullName ?? "User #${b.userId.substring(0, 5)}"} (${user?.mobileNumber ?? "N/A"})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                                  Text('₹${b.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text('Schedule: ${DateFormat("dd MMM, hh:mm a").format(b.pickupDateTime)} to ${DateFormat("dd MMM, hh:mm a").format(b.dropDateTime)} (${dur.inHours} hrs)', style: const TextStyle(fontSize: 12)),
                                              Text('Route: ${b.pickupLocation.isEmpty ? "Depot" : b.pickupLocation} ➔ ${b.dropLocation.isEmpty ? "Depot" : b.dropLocation}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              const Divider(height: 12),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODAL 3: Pending/Upcoming Journeys
  void _showPendingJourneysModal(BuildContext context, List<BookingModel> pendingJourneys) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event_seat, color: Colors.teal, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Future Reserved Journeys',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All upcoming booked reservations waiting for pickup',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            if (pendingJourneys.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No future reservations found for this district.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: pendingJourneys.length,
                  itemBuilder: (context, index) {
                    final booking = pendingJourneys[index];
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchJourneyDetails(booking),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
                        }
                        final car = snapshot.data!['car'] as CarModel?;
                        final user = snapshot.data!['user'] as UserModel?;
                        final hours = booking.dropDateTime.difference(booking.pickupDateTime).inHours;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(car?.name ?? "Car ID: ${booking.carId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Chip(
                                      label: const Text('Booked for future journey', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: Colors.teal,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Office Depot: ${car?.district ?? "Gujarat"} | Customer: ${user?.fullName ?? "N/A"} (${user?.mobileNumber ?? "N/A"})'),
                                Text('Schedule: ${DateFormat("dd MMM, hh:mm a").format(booking.pickupDateTime)} to ${DateFormat("dd MMM, hh:mm a").format(booking.dropDateTime)} ($hours hrs)'),
                                Text('Pickup: ${booking.pickupLocation} ➔ Drop: ${booking.dropLocation}'),
                                const SizedBox(height: 4),
                                Text('Total Fare: ₹${booking.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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

  Future<Map<String, dynamic>> _fetchJourneyDetails(BookingModel booking) async {
    final user = await _dbService.getUserById(booking.userId);
    final car = await _dbService.getCarById(booking.carId);
    return {'user': user, 'car': car};
  }

  void _showCarDetailsModal(BuildContext context, CarProvider provider, CarModel car, int activeForCar, int inGarageForCar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                car.imageUrl, 
                height: 180, 
                width: double.infinity, 
                fit: BoxFit.cover, 
                errorBuilder: (_, _, _) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.directions_car, size: 60)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(car.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Chip(
                  avatar: const Icon(Icons.location_on, size: 14, color: Color(0xFF1E3A8A)),
                  label: Text('${car.district} Office', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
              ],
            ),
            Text('${car.category} | ${car.fuelType} | ${car.transmission} | ${car.seatingCapacity} Seater', style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailTile('Price/Hr', '₹${car.pricePerHour}'),
                _detailTile('Total Units', '${car.totalUnits}'),
                _detailTile('In Garage', '$inGarageForCar'),
                _detailTile('On Journey', '$activeForCar'),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditCarScreen(car: car)));
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, provider, car);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Record'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, CarProvider provider, CarModel car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Car?'),
        content: Text('Are you sure you want to remove ${car.name} from the fleet?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async { 
              await provider.deleteCar(car.carId); 
              if (context.mounted) Navigator.pop(context); 
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProfile(AuthProvider provider) {
    final user = provider.userModel;
    if (user == null) return const Center(child: Text('Not Logged In'));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 50, child: Icon(Icons.admin_panel_settings, size: 50)),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(user.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(user.mobileNumber, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: const Text('ADMINISTRATOR'),
                    backgroundColor: const Color(0xFFEFF6FF),
                    labelStyle: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditAdminProfileModal(context, user),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAdminProfileModal(BuildContext context, dynamic user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final mobileCtrl = TextEditingController(text: user.mobileNumber);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, color: Color(0xFF1E3A8A), size: 28),
                  SizedBox(width: 8),
                  Text('Update Admin Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email Address (System ID)', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx);
                          await Provider.of<AuthProvider>(context, listen: false).updateProfile(
                            fullName: nameCtrl.text.trim(),
                            mobileNumber: mobileCtrl.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Admin profile details updated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
