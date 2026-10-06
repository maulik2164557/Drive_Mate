import 'package:flutter/material.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import '../../../core/utils/location_data.dart';
import 'package:intl/intl.dart';

class GuestDashboard extends StatefulWidget {
  const GuestDashboard({super.key});

  @override
  State<GuestDashboard> createState() => _GuestDashboardState();
}

class _GuestDashboardState extends State<GuestDashboard> {
  final TextEditingController _pickupLocController = TextEditingController();
  final TextEditingController _dropLocController = TextEditingController();
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _dropDate;
  TimeOfDay? _dropTime;

  final List<String> _allLocations = LocationData.getAllPlaces();

  Future<void> _selectDateTime(BuildContext context, bool isPickup) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!isPickup && (_pickupDate == null || _pickupTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Pickup Date & Time first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pickupDT = (_pickupDate != null && _pickupTime != null)
        ? DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day, _pickupTime!.hour, _pickupTime!.minute)
        : null;

    final firstDate = (!isPickup && pickupDT != null)
        ? DateTime(pickupDT.year, pickupDT.month, pickupDT.day)
        : today;

    final initialDate = isPickup
        ? (_pickupDate != null && !_pickupDate!.isBefore(today) ? _pickupDate! : today)
        : (_dropDate != null && !_dropDate!.isBefore(firstDate) ? _dropDate! : firstDate);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
      helpText: isPickup ? 'SELECT PICKUP DATE' : 'SELECT DROP DATE',
    );

    if (pickedDate != null && context.mounted) {
      final initialTime = isPickup
          ? (_pickupTime ?? TimeOfDay.now())
          : (_dropTime ??
              (_pickupTime != null
                  ? TimeOfDay(hour: (_pickupTime!.hour + 2) % 24, minute: _pickupTime!.minute)
                  : TimeOfDay.now()));

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: isPickup ? 'SELECT PICKUP TIME' : 'SELECT DROP TIME',
      );

      if (pickedTime != null && context.mounted) {
        final selectedDT = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (!isPickup) {
          if (pickupDT != null && !selectedDT.isAfter(pickupDT)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Invalid drop time! Drop date & time must be after pickup time (${DateFormat('dd/MM/yyyy, hh:mm a').format(pickupDT)}).',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
          setState(() {
            _dropDate = pickedDate;
            _dropTime = pickedTime;
          });
        } else {
          setState(() {
            _pickupDate = pickedDate;
            _pickupTime = pickedTime;

            if (_dropDate != null && _dropTime != null) {
              final currentDropDT = DateTime(
                _dropDate!.year,
                _dropDate!.month,
                _dropDate!.day,
                _dropTime!.hour,
                _dropTime!.minute,
              );
              if (!currentDropDT.isAfter(selectedDT)) {
                _dropDate = null;
                _dropTime = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Drop time was reset. Please select a drop time after pickup date & time.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(isGuest: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildSearchForm(context),
            _buildReviewSection(),
            _buildFAQSection(),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF1E3A8A).withValues(alpha: 0.9),
            const Color(0xFF1D4ED8).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=2070'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'GUJARAT\'S NO.1 CAR RENTAL NETWORK',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Drive Your Dreams Across Gujarat',
                style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Flexible, Affordable & Insured Self-Drive Fleets Across All 33 Districts',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _heroPill(Icons.headset_mic, '24/7 Roadside Support'),
                  _heroPill(Icons.verified_user, 'Zero Security Deposit'),
                  _heroPill(Icons.speed, 'Unlimited Kilometers'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amberAccent, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildLocationAutocomplete('Pickup Location', _pickupLocController, Icons.location_on)),
              const SizedBox(width: 16),
              Expanded(child: _buildLocationAutocomplete('Drop Location', _dropLocController, Icons.location_on_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  'Pickup Date & Time',
                  _pickupDate == null ? 'Select' : '${DateFormat('dd/MM/yyyy').format(_pickupDate!)} ${_pickupTime!.format(context)}',
                  () => _selectDateTime(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateTimePicker(
                  'Drop Date & Time',
                  _dropDate == null ? 'Select' : '${DateFormat('dd/MM/yyyy').format(_dropDate!)} ${_dropTime!.format(context)}',
                  () => _selectDateTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_pickupDate != null && _pickupTime != null && _dropDate != null && _dropTime != null) {
                  final pickupDT = DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day, _pickupTime!.hour, _pickupTime!.minute);
                  final dropDT = DateTime(_dropDate!.year, _dropDate!.month, _dropDate!.day, _dropTime!.hour, _dropTime!.minute);
                  if (!dropDT.isAfter(pickupDT)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Drop date & time must be after pickup date & time.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }
                final pickupText = _pickupLocController.text.trim();
                Navigator.pushNamed(context, '/signup', arguments: pickupText);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              child: const Text('Search Available Cars', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAutocomplete(String label, TextEditingController controller, IconData icon) {
    return Autocomplete<String>(
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
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
    );
  }

  Widget _buildDateTimePicker(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Text('What Our Customers Say', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildReviewCard('Rahul Sharma', 5, 'Amazing service! The car was in great condition and the booking process was seamless.'),
                _buildReviewCard('Anjali Gupta', 4, 'Very affordable prices compared to others. Highly recommended for long trips.'),
                _buildReviewCard('Vikram Singh', 5, 'Prompt customer support and very professional staff. Will book again!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, int rating, String review) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(children: List.generate(5, (i) => Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey, size: 20))),
          const SizedBox(height: 8),
          Text(review, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Text('Frequently Asked Questions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ExpansionTile(title: const Text('What documents are required for KYC?'), children: [const Padding(padding: EdgeInsets.all(16), child: Text('You need to upload your Aadhaar Card and a valid Driving Licence.'))]),
          ExpansionTile(title: const Text('Is there a cancellation fee?'), children: [const Padding(padding: EdgeInsets.all(16), child: Text('Cancellations made 24 hours before the pickup time are fully refundable. After that, a 10% penalty applies.'))]),
        ],
      ),
    );
  }
}
