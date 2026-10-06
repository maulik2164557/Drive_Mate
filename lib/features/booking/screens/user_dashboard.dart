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
              Expanded(
                child: _buildTimePickerWidget(
                  label: 'Pickup Time',
                  value: _pickupDateTime,
                  onTap: _selectPickupDateTime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTimePickerWidget(
                  label: 'Drop Time',
                  value: _dropDateTime,
                  onTap: _selectDropDateTime,
                ),
              ),
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

  Future<void> _selectPickupDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initialDate = (_pickupDateTime != null && !_pickupDateTime!.isBefore(today))
        ? _pickupDateTime!
        : today;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'SELECT PICKUP DATE',
    );

    if (pickedDate != null && mounted) {
      final initialTime = _pickupDateTime != null
          ? TimeOfDay.fromDateTime(_pickupDateTime!)
          : TimeOfDay.now();

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'SELECT PICKUP TIME',
      );

      if (pickedTime != null && mounted) {
        final newPickup = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _pickupDateTime = newPickup;

          // If dropDateTime was already set and is no longer strictly after newPickup, reset it
          if (_dropDateTime != null && !_dropDateTime!.isAfter(newPickup)) {
            _dropDateTime = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Drop time was reset. Please select a drop time after pickup date & time.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _selectDropDateTime() async {
    if (_pickupDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Pickup date & time first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final pickupDateOnly = DateTime(_pickupDateTime!.year, _pickupDateTime!.month, _pickupDateTime!.day);

    final initialDate = (_dropDateTime != null && !_dropDateTime!.isBefore(pickupDateOnly))
        ? DateTime(_dropDateTime!.year, _dropDateTime!.month, _dropDateTime!.day)
        : pickupDateOnly;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: pickupDateOnly, // Strictly prevents choosing a previous calendar date
      lastDate: pickupDateOnly.add(const Duration(days: 365)),
      helpText: 'SELECT DROP DATE',
    );

    if (pickedDate != null && mounted) {
      final initialTime = _dropDateTime != null
          ? TimeOfDay.fromDateTime(_dropDateTime!)
          : TimeOfDay(
              hour: (_pickupDateTime!.hour + 2) % 24,
              minute: _pickupDateTime!.minute,
            );

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'SELECT DROP TIME',
      );

      if (pickedTime != null && mounted) {
        final newDrop = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Strict verification: Drop must be strictly greater than pickup date + time
        if (!newDrop.isAfter(_pickupDateTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid drop time! Drop date & time must be after pickup time (${DateFormat('dd/MM/yyyy, hh:mm a').format(_pickupDateTime!)}).',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          _dropDateTime = newDrop;
        });
      }
    }
  }

  Widget _buildTimePickerWidget({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule, size: 20),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          value == null ? 'Select Date/Time' : DateFormat('dd MMM, hh:mm a').format(value),
          style: TextStyle(
            fontSize: 13,
            fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
            color: value != null ? const Color(0xFF1E3A8A) : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _performDateSearch() {
    if (_pickupDateTime == null || _dropDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and drop date/time.')),
      );
      return;
    }

    if (!_dropDateTime!.isAfter(_pickupDateTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drop date & time must be after pickup date & time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _fetchAvailability();
    Provider.of<BookingProvider>(context, listen: false).searchCars(
      pickup: _pickupDateTime!,
      drop: _dropDateTime!,
      category: _selectedCategory,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking schedule availability for selected dates...'), duration: Duration(seconds: 1)),
    );
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
            // 1. Mandatory Location & Date/Time Selection Check
            if (_pickupLoc.text.trim().isEmpty ||
                _dropLoc.text.trim().isEmpty ||
                _pickupDateTime == null ||
                _dropDateTime == null) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.edit_calendar, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 8),
                      Text('Schedule & Location Required'),
                    ],
                  ),
                  content: const Text(
                    'Please specify your Pickup Location, Drop Location, Pickup Time, and Drop Time at the top before booking a car.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      child: const Text('OK, Enter Details'),
                    ),
                  ],
                ),
              );
              return;
            }

            // 1.5 Strict Validation: Drop Time must be greater than Pickup Time
            if (!_dropDateTime!.isAfter(_pickupDateTime!)) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Invalid Schedule'),
                    ],
                  ),
                  content: const Text(
                    'Drop date & time must be greater than pickup date & time. Please update your drop schedule at the top.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }

            // 2. Overlapping Inventory Availability Check
            if (isFullyBooked) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Car Not Available'),
                    ],
                  ),
                  content: Text(
                    'Sorry, ${car.name} is not available for your selected dates because all ${car.totalUnits} units are already booked.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
              return;
            }

            // 3. Validated -> Proceed to Booking Confirmation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CarDetailsScreen(
                  car: car,
                  pickup: _pickupDateTime!,
                  drop: _dropDateTime!,
                  pickupLocation: _pickupLoc.text.trim(),
                  dropLocation: _dropLoc.text.trim(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
