import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/car_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/car_model.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import '../../../core/utils/location_data.dart';
import '../widgets/car_card.dart';
import 'car_details_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  // Filters: 3 Partitions
  String _selectedCategory = 'All'; // "All", "SUVs", "MUVs", "Hatchbacks", "Sedans"
  String _selectedFuelType = 'All'; // "All", "Petrol", "Diesel", "EV", "Hybridge", "CNG"
  String _selectedTransmission = 'All'; // "All", "Automatic", "Manual"
  String _selectedDistrict = 'All'; // Gujarat district filter

  DateTime? _pickupDateTime;
  DateTime? _dropDateTime;
  final TextEditingController _pickupLoc = TextEditingController();
  final TextEditingController _dropLoc = TextEditingController();

  final List<String> _allLocations = LocationData.getAllPlaces();
  final List<String> _districts = LocationData.getAllDistricts();

  // Filter partitions data
  static const List<String> _categoryOptions = ['SUVs', 'MUVs', 'Hatchbacks', 'Sedans'];
  static const List<String> _fuelOptions = ['Petrol', 'Diesel', 'EV', 'Hybridge', 'CNG'];
  static const List<String> _transmissionOptions = ['Automatic', 'Manual'];

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_selectedFuelType != 'All') count++;
    if (_selectedTransmission != 'All') count++;
    if (_selectedDistrict != 'All') count++;
    return count;
  }

  Map<String, int> _bookedUnitsMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        Provider.of<BookingProvider>(context, listen: false).fetchUserBookings(user.uid);
      }
    });
  }

  void _fetchAvailability() async {
    final start = _pickupDateTime ?? DateTime.now().add(const Duration(hours: 2));
    final end = _dropDateTime ?? DateTime.now().add(const Duration(days: 1, hours: 2));
    try {
      final bookings = await DatabaseService().getBookingsInRange(start, end);
      Map<String, int> map = {};
      for (var b in bookings) {
        map[b.carId] = (map[b.carId] ?? 0) + 1;
      }
      if (mounted) {
        setState(() {
          _bookedUnitsMap = map;
        });
      }
    } catch (e) {
      debugPrint('Error fetching availability: $e');
    }
  }

  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String && args.isNotEmpty) {
        _pickupLoc.text = args;
        _onPickupLocationChanged();
      }
    }
  }

  void _onPickupLocationChanged() {
    final text = _pickupLoc.text;
    final derivedDistrict = LocationData.getDistrictFromLocation(text);
    if (derivedDistrict != null) {
      if (_selectedDistrict != derivedDistrict) {
        setState(() {
          _selectedDistrict = derivedDistrict;
        });
      }
    } else if (text.trim().isEmpty && _selectedDistrict != 'All') {
      setState(() {
        _selectedDistrict = 'All';
      });
    }
  }

  void _clearAllFilters() {
    setState(() {
      _pickupLoc.clear();
      _dropLoc.clear();
      _selectedCategory = 'All';
      _selectedFuelType = 'All';
      _selectedTransmission = 'All';
      _selectedDistrict = 'All';
    });
  }

  bool _matchesCategory(String carCategory, String filterCategory) {
    if (filterCategory == 'All') return true;
    final cat = carCategory.toLowerCase().trim();
    final filter = filterCategory.toLowerCase().trim();
    if (filter == 'suvs') return cat == 'suv' || cat == 'suvs';
    if (filter == 'muvs') return cat == 'muv' || cat == 'muvs';
    if (filter == 'hatchbacks') return cat == 'hatchback' || cat == 'hatchbacks';
    if (filter == 'sedans') return cat == 'sedan' || cat == 'sedans';
    return cat == filter;
  }

  bool _matchesFuel(String carFuel, String filterFuel) {
    if (filterFuel == 'All') return true;
    final car = carFuel.toLowerCase().trim();
    final filter = filterFuel.toLowerCase().trim();
    if (filter == 'hybridge' || filter == 'hybrid') {
      return car.contains('hybr');
    }
    if (filter == 'ev') {
      return car == 'ev' || car == 'electric';
    }
    return car == filter;
  }

  bool _matchesTransmission(String carTrans, String filterTrans) {
    if (filterTrans == 'All') return true;
    return carTrans.toLowerCase().trim() == filterTrans.toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    final carProvider = Provider.of<CarProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    // Apply filtering to all cars
    final allCars = carProvider.cars;
    final filteredCars = allCars.where((car) {
      if (!_matchesCategory(car.category, _selectedCategory)) return false;
      if (!_matchesFuel(car.fuelType, _selectedFuelType)) return false;
      if (!_matchesTransmission(car.transmission, _selectedTransmission)) return false;
      if (_selectedDistrict != 'All' && car.district.toLowerCase() != _selectedDistrict.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: const AppNavbar(title: 'Available Fleets'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchInputs(context),
            _buildFilterToolbar(context, filteredCars.length, allCars.length),
            if (_activeFilterCount > 0) _buildActiveFilterChips(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: carProvider.isLoading || bookingProvider.isLoading
                  ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                  : _buildCarGrid(filteredCars),
            ),
            const SizedBox(height: 24),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterToolbar(BuildContext context, int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // The single "Filter" option requested by user
              ElevatedButton.icon(
                onPressed: () => _openFilterModal(context),
                icon: const Icon(Icons.tune_rounded, size: 20),
                label: Text(
                  _activeFilterCount > 0 ? 'Filter ($_activeFilterCount)' : 'Filter',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeFilterCount > 0 ? const Color(0xFF1E3A8A) : Colors.white,
                  foregroundColor: _activeFilterCount > 0 ? Colors.white : const Color(0xFF1E3A8A),
                  elevation: 2,
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              // District Quick Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    icon: const Icon(Icons.location_on, size: 16, color: Color(0xFF1E3A8A)),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Gujarat Offices', style: TextStyle(fontSize: 13))),
                      ..._districts.map((d) => DropdownMenuItem(value: d, child: Text('$d Office', style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDistrict = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$filteredCount of $totalCount cars available',
            style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          const Text('Active Filters: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCategory != 'All')
                    _activeChip('Category: $_selectedCategory', () => setState(() => _selectedCategory = 'All')),
                  if (_selectedFuelType != 'All')
                    _activeChip('Fuel: $_selectedFuelType', () => setState(() => _selectedFuelType = 'All')),
                  if (_selectedTransmission != 'All')
                    _activeChip('Trans: $_selectedTransmission', () => setState(() => _selectedTransmission = 'All')),
                  if (_selectedDistrict != 'All')
                    _activeChip('Depot: $_selectedDistrict', () => setState(() => _selectedDistrict = 'All')),
                  TextButton(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeChip(String text, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A))),
        backgroundColor: const Color(0xFFE0E7FF),
        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF1E3A8A)),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // 3-PARTITION FILTER MODAL
  void _openFilterModal(BuildContext context) {
    String tempCategory = _selectedCategory;
    String tempFuel = _selectedFuelType;
    String tempTransmission = _selectedTransmission;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: Color(0xFF1E3A8A), size: 26),
                      SizedBox(width: 8),
                      Text('Filter Fleets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        tempCategory = 'All';
                        tempFuel = 'All';
                        tempTransmission = 'All';
                      });
                    },
                    child: const Text('Reset All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PARTITION 1: CATEGORY
                      _buildPartitionHeader('1. Vehicle Category', Icons.directions_car),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _filterChoiceChip('All Categories', tempCategory == 'All', () => setModalState(() => tempCategory = 'All')),
                          ..._categoryOptions.map(
                            (cat) => _filterChoiceChip(
                              cat,
                              tempCategory == cat,
                              () => setModalState(() => tempCategory = (tempCategory == cat ? 'All' : cat)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      // PARTITION 2: FUEL TYPE
                      _buildPartitionHeader('2. Fuel Type', Icons.local_gas_station),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _filterChoiceChip('All Fuels', tempFuel == 'All', () => setModalState(() => tempFuel = 'All')),
                          ..._fuelOptions.map(
                            (fuel) => _filterChoiceChip(
                              fuel,
                              tempFuel == fuel,
                              () => setModalState(() => tempFuel = (tempFuel == fuel ? 'All' : fuel)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),

                      // PARTITION 3: TRANSMISSION TYPE
                      _buildPartitionHeader('3. Transmission Type', Icons.settings),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _filterChoiceChip('All Transmissions', tempTransmission == 'All', () => setModalState(() => tempTransmission = 'All')),
                          ..._transmissionOptions.map(
                            (trans) => _filterChoiceChip(
                              trans,
                              tempTransmission == trans,
                              () => setModalState(() => tempTransmission = (tempTransmission == trans ? 'All' : trans)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCategory;
                          _selectedFuelType = tempFuel;
                          _selectedTransmission = tempTransmission;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildPartitionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _filterChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildSearchInputs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildLocationAutocomplete('Pickup Depot', _pickupLoc, Icons.location_on)),
              const SizedBox(width: 8),
              Expanded(child: _buildLocationAutocomplete('Drop Depot', _dropLoc, Icons.location_on_outlined)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTimePicker('Pickup Time', _pickupDateTime, (dt) => setState(() => _pickupDateTime = dt))),
              const SizedBox(width: 8),
              Expanded(child: _buildTimePicker('Drop Time', _dropDateTime, (dt) => setState(() => _dropDateTime = dt))),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performDateSearch,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Check Dates'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAutocomplete(String label, TextEditingController controller, IconData icon) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return _allLocations.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (controller == _pickupLoc) {
          _onPickupLocationChanged();
        }
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (controller.text.isNotEmpty && textController.text != controller.text) {
          textController.text = controller.text;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (val) {
            controller.text = val;
            if (controller == _pickupLoc) {
              _onPickupLocationChanged();
            }
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker(String label, DateTime? value, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (time != null) {
            onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(value == null ? 'Select Date/Time' : DateFormat('dd/MM HH:mm').format(value)),
      ),
    );
  }

  void _performDateSearch() {
    if (_pickupDateTime != null && _dropDateTime != null) {
      _fetchAvailability();
      Provider.of<BookingProvider>(context, listen: false).searchCars(
        pickup: _pickupDateTime!,
        drop: _dropDateTime!,
        category: _selectedCategory,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking schedule availability for selected dates...'), duration: Duration(seconds: 1)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and drop date/time.')),
      );
    }
  }

  Widget _buildCarGrid(List<CarModel> cars) {
    if (cars.isEmpty) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.car_rental, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No cars match your applied filters.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Try modifying category, fuel type, or district depot.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    final defaultPickup = _pickupDateTime ?? DateTime.now().add(const Duration(hours: 2));
    final defaultDrop = _dropDateTime ?? DateTime.now().add(const Duration(days: 1, hours: 2));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 0.82,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        final car = cars[index];
        int booked = _bookedUnitsMap[car.carId] ?? 0;
        int available = (car.totalUnits - booked).clamp(0, car.totalUnits);
        bool isFullyBooked = available <= 0;

        return CarCard(
          car: car,
          availableUnits: available,
          isFullyBooked: isFullyBooked,
          onTap: () {
            if (isFullyBooked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All units of this car are fully booked for your selected schedule.')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarDetailsScreen(
                  car: car,
                  pickup: defaultPickup,
                  drop: defaultDrop,
                  pickupLocation: _pickupLoc.text.trim().isNotEmpty ? _pickupLoc.text.trim() : '${car.district} Office / Depot',
                  dropLocation: _dropLoc.text.trim().isNotEmpty ? _dropLoc.text.trim() : '${car.district} Office / Depot',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
