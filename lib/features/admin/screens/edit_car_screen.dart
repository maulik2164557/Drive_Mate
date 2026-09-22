import 'dart:io';
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

class EditCarScreen extends StatefulWidget {
  final CarModel car;
  const EditCarScreen({super.key, required this.car});

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _unitsController;
  
  late String _category;
  late String _fuelType;
  late String _transmission;
  late String _district;
  XFile? _imageFile;
  bool _isUploading = false;

  final StorageService _storageService = StorageService();
  final List<String> _districts = LocationData.getAllDistricts();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.car.name);
    _priceController = TextEditingController(text: widget.car.pricePerHour.toString());
    _capacityController = TextEditingController(text: widget.car.seatingCapacity.toString());
    _unitsController = TextEditingController(text: widget.car.totalUnits.toString());
    _category = widget.car.category;
    _fuelType = widget.car.fuelType;
    _transmission = widget.car.transmission;
    _district = widget.car.district.isNotEmpty ? widget.car.district : 'Ahmedabad';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String imageUrl = widget.car.imageUrl;
      if (_imageFile != null) {
        String fileName = 'cars/${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          imageUrl = await _storageService.uploadFile(fileName, bytes: bytes);
        } else {
          imageUrl = await _storageService.uploadFile(fileName, file: File(_imageFile!.path));
        }
      }

      final updatedCar = CarModel(
        carId: widget.car.carId,
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
      await Provider.of<CarProvider>(context, listen: false).updateCar(updatedCar);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Car updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(title: 'Edit Car Record'),
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
                            const Text('Update Car Record', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 16),
                            _buildImagePicker(),
                            const SizedBox(height: 16),
                            _buildTextField('Car Name', _nameController, Icons.directions_car),
                            // District selection
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<String>(
                                initialValue: _districts.contains(_district) ? _district : 'Ahmedabad',
                                items: _districts.map((d) => DropdownMenuItem(value: d, child: Text('$d District Office'))).toList(),
                                onChanged: (v) => setState(() => _district = v!),
                                decoration: const InputDecoration(
                                  labelText: 'Gujarat District Depot',
                                  prefixIcon: Icon(Icons.location_city, color: Color(0xFF1E3A8A)),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            _buildDropdown('Category', _category, ['SUV', 'MUV', 'Sedan', 'Hatchback'], (v) => setState(() => _category = v!)),
                            _buildDropdown('Fuel Type', _fuelType, ['Petrol', 'Diesel', 'EV', 'Hybridge', 'CNG'], (v) => setState(() => _fuelType = v!)),
                            _buildTextField('Price/Hr (₹)', _priceController, Icons.currency_rupee, isNum: true),
                            _buildTextField('Capacity', _capacityController, Icons.airline_seat_recline_normal, isNum: true),
                            _buildTextField('Total Units', _unitsController, Icons.numbers, isNum: true),
                            _buildDropdown('Transmission', _transmission, ['Automatic', 'Manual'], (v) => setState(() => _transmission = v!)),
                            const SizedBox(height: 24),
                            if (_isUploading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                label: const Text('Update Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
        child: _imageFile != null 
          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb ? Image.network(_imageFile!.path) : Image.file(File(_imageFile!.path)))
          : Image.network(widget.car.imageUrl),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChange,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
