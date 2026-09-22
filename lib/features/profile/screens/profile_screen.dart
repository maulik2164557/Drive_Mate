import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  void _showDocumentSourceSheet(String type) {
    final title = type == 'aadhar' ? 'Aadhaar Card' : 'Driving Licence';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 6),
              const Text('Select your preferred document format (PDF, JPG, or PNG):', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.picture_as_pdf, color: Colors.red)),
                title: const Text('Upload PDF Document'),
                subtitle: const Text('Pick official PDF document file'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPdf(type);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.photo_library, color: Colors.blue)),
                title: const Text('Choose Photo from Gallery'),
                subtitle: const Text('Select JPG or PNG image of document'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2F1), child: Icon(Icons.camera_alt, color: Colors.teal)),
                title: const Text('Capture with Camera'),
                subtitle: const Text('Take clear photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(type, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPdf(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        await _processUpload(type, bytes: bytes, path: file.path, ext: 'pdf');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF selection failed: $e')));
      }
    }
  }

  Future<void> _pickAndUploadImage(String type, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'jpg';
        await _processUpload(type, bytes: bytes, path: image.path, ext: ext);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image selection failed: $e')));
      }
    }
  }

  Future<void> _processUpload(String type, {Uint8List? bytes, String? path, required String ext}) async {
    setState(() => _isUploading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel!;
      final docLabel = type == 'aadhar' ? 'Aadhaar Card' : 'Driving Licence';
      final fileName = '${user.uid}_$type.$ext';

      String url;
      if (bytes != null) {
        url = await _storageService.uploadFile('kyc/$fileName', bytes: bytes);
      } else if (path != null) {
        url = await _storageService.uploadFile('kyc/$fileName', file: File(path));
      } else {
        throw Exception('File data not available.');
      }

      // Update Firestore
      Map<String, dynamic> data = type == 'aadhar'
          ? {'aadharDocumentUrl': url}
          : {'drivingLicenceUrl': url};

      bool hasAadhar = type == 'aadhar' ? true : (user.aadharDocumentUrl != null && user.aadharDocumentUrl!.isNotEmpty);
      bool hasLicense = type == 'license' ? true : (user.drivingLicenceUrl != null && user.drivingLicenceUrl!.isNotEmpty);

      if (hasAadhar && hasLicense) {
        data['kycStatus'] = 'Verified';
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docLabel uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final bookingProvider = Provider.of<BookingProvider>(context);

    if (user == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return Scaffold(
      appBar: const AppNavbar(title: 'My Profile'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      _buildProfileHeader(user),
                      const SizedBox(height: 32),
                      _buildKYCSection(user),
                      const SizedBox(height: 32),
                      _buildBookingHistory(bookingProvider),
                    ],
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

  Widget _buildProfileHeader(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user.email),
                Text(user.mobileNumber),
                const SizedBox(height: 4),
                Chip(
                  label: Text(user.kycStatus),
                  backgroundColor: user.kycStatus == 'Verified' ? Colors.green[100] : Colors.orange[100],
                  labelStyle: TextStyle(color: user.kycStatus == 'Verified' ? Colors.green[800] : Colors.orange[800]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKYCSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('KYC Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Supports PDF, JPG, PNG', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        _buildDocItem('Aadhaar Card', user.aadharDocumentUrl, () => _showDocumentSourceSheet('aadhar')),
        const SizedBox(height: 8),
        _buildDocItem('Driving Licence', user.drivingLicenceUrl, () => _showDocumentSourceSheet('license')),
      ],
    );
  }

  Widget _buildDocItem(String label, String? url, VoidCallback onUpload) {
    bool isUploaded = url != null && url.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.verified : Icons.upload_file,
          color: isUploaded ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(isUploaded ? 'Document Uploaded & Attached' : 'PDF or Image document required'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : onUpload,
              icon: Icon(_isUploading ? Icons.hourglass_empty : Icons.file_upload, size: 16),
              label: Text(isUploaded ? 'Re-upload Doc' : 'Upload Doc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUploaded ? Colors.blueGrey : const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHistory(BookingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (provider.userBookings.isEmpty)
          const Text('No bookings found.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.userBookings.length,
            itemBuilder: (context, index) {
              final booking = provider.userBookings[index];
              return Card(
                child: ListTile(
                  title: Text('Booking #${booking.bookingId.substring(0, 8)}'),
                  subtitle: Text('Status: ${booking.status}\nTotal: ₹${booking.totalPrice}'),
                  trailing: booking.status == 'Pending Journey'
                      ? ElevatedButton(
                          onPressed: () => _cancelBooking(booking),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Cancel'),
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }

  void _cancelBooking(dynamic booking) async {
    // Show confirmation dialog then call provider
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? Refund policy will apply.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Provider.of<BookingProvider>(context, listen: false).cancelBooking(
        booking.bookingId, 
        booking.pickupDateTime, 
        booking.totalPrice
      );
    }
  }
}
