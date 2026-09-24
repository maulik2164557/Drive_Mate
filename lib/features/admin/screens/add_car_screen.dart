import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/car_model.dart';
import '../../../providers/car_provider.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/location_data.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _unitsController = TextEditingController();
  
  String _category = 'SUV';
  String _fuelType = 'Petrol';
  String _transmission = 'Automatic';
  String _district = 'Ahmedabad';
  XFile? _imageFile;
  bool _isUploading = false;

  final StorageService _storageService = StorageService();
  final List<String> _districts = LocationData.getAllDistricts();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a car image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String imageUrl;
      final bytes = await _imageFile!.readAsBytes();
      String fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      try {
        imageUrl = await _storageService
            .uploadFile(fileName, bytes: bytes)
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        final base64Str = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64Str';
      }

      final car = CarModel(
        carId: '',
        name: _nameController.text.trim(),
        category: _category,
        fuelType: _fuelType,
        seatingCapacity: int.parse(_capacityController.text.trim()),
        transmission: _transmission,
        pricePerHour: double.parse(_priceController.text.trim()),
        totalUnits: int.parse(_unitsController.text.trim()),
        imageUrl: imageUrl,
        district: _district,
      );

      if (!mounted) return;
      await Provider.of<CarProvider>(context, listen: false).addCar(car);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Car added successfully to $_district office!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add car: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(title: 'Add New Car'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Add Vehicle to Gujarat Fleet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 8),
                            const Text('Specify district depot and technical specifications for the new car.', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 20),
                            _buildImagePicker(),
                            const SizedBox(height: 24),
                            _buildTextField('Car Model Name', _nameController, Icons.directions_car),
                            const SizedBox(height: 16),
                            // District field (Required for Gujarat state office management)
                            DropdownButtonFormField<String>(
                              initialValue: _district,
                              decoration: const InputDecoration(
                                labelText: 'Gujarat District Depot (Office Location) *',
                                prefixIcon: Icon(Icons.location_city, color: Color(0xFF1E3A8A)),
                                border: OutlineInputBorder(),
                                helperText: 'Select which Gujarat district depot this car belongs to',
                              ),
                              items: _districts.map((d) => DropdownMenuItem(value: d, child: Text('$d District Office'))).toList(),
                              onChanged: (val) => setState(() => _district = val!),
                              validator: (val) => (val == null || val.isEmpty) ? 'District is required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildDropdown('Category', _category, ['SUV', 'MUV', 'Sedan', 'Hatchback'], (val) => setState(() => _category = val!))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown('Fuel Type', _fuelType, ['Petrol', 'Diesel', 'EV', 'Hybridge', 'CNG'], (val) => setState(() => _fuelType = val!))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Price Per Hour (₹)', _priceController, Icons.currency_rupee, isNumber: true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Seating Capacity', _capacityController, Icons.airline_seat_recline_normal, isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Total Units (Stock)', _unitsController, Icons.numbers, isNumber: true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown('Transmission', _transmission, ['Automatic', 'Manual'], (val) => setState(() => _transmission = val!))),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (_isUploading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.add),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                label: const Text('Add Car to Fleet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ),
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

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List>(
                  future: _imageFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Upload Car Image', style: TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
