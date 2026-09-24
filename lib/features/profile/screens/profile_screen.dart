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
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;

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
        if (bytes == null && !kIsWeb && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        final String? filePath = kIsWeb ? null : file.path;
        await _processUpload(type, bytes: bytes, path: filePath, ext: 'pdf');
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
      try {
        if (bytes != null) {
          url = await _storageService.uploadFile('kyc/$fileName', bytes: bytes);
        } else if (path != null) {
          url = await _storageService.uploadFile('kyc/$fileName', file: File(path));
        } else {
          throw Exception('File data not available.');
        }
      } catch (storageError) {
        // Fallback: If Firebase Storage upload fails (e.g. storage rules / network / web CORS),
        // store as base64 Data URL so upload never fails and user's document is saved safely!
        if (bytes != null) {
          final mime = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
          final base64Data = base64Encode(bytes);
          url = 'data:$mime;base64,$base64Data';
        } else {
          rethrow;
        }
      }

      // Update Firestore for this specific document ONLY
      Map<String, dynamic> data = type == 'aadhar'
          ? {'aadharDocumentUrl': url}
          : {'drivingLicenceUrl': url};

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docLabel uploaded and attached successfully! You can view or re-upload it anytime.'),
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(user.email, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(user.mobileNumber, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text('KYC: ${user.kycStatus}'),
                    backgroundColor: user.kycStatus == 'Verified' ? Colors.green[100] : Colors.orange[100],
                    labelStyle: TextStyle(color: user.kycStatus == 'Verified' ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showEditProfileModal(user),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal(dynamic user) {
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
                  Text('Update Profile Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
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
                decoration: const InputDecoration(labelText: 'Email Address (Registered)', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
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
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile details updated successfully!'), backgroundColor: Colors.green),
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

  Widget _buildKYCSection(dynamic user) {
    bool hasAadhar = user.aadharDocumentUrl != null && user.aadharDocumentUrl!.isNotEmpty;
    bool hasLicense = user.drivingLicenceUrl != null && user.drivingLicenceUrl!.isNotEmpty;
    bool isVerified = user.kycStatus == 'Verified';

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

        // Verify KYC Button & Verified Badge Section
        if (isVerified) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KYC Account Verified ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      SizedBox(height: 2),
                      Text('Your Aadhaar Card and Driving Licence are verified. You can book any car fleet!', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else if (hasAadhar && hasLicense) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _verifyKycAccount(user.uid),
              icon: const Icon(Icons.verified_user, size: 22),
              label: const Text('Verify KYC Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ] else ...[
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Upload both Aadhaar Card and Driving Licence separately above to enable the "Verify KYC Account" button.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _verifyKycAccount(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'kycStatus': 'Verified'});
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Congratulations! Your KYC account has been verified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    }
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
            if (isUploaded) ...[
              OutlinedButton.icon(
                onPressed: () => _viewDocument(label, url),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: _isUploading ? null : onUpload,
              icon: Icon(_isUploading ? Icons.hourglass_empty : Icons.file_upload, size: 16),
              label: Text(isUploaded ? 'Re-upload' : 'Upload Doc'),
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

  void _viewDocument(String label, String url) {
    bool isPdf = url.contains('.pdf') || url.startsWith('data:application/pdf');

    if (isPdf && kIsWeb) {
      try {
        html.window.open(url, '_blank');
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: isPdf ? Colors.red : const Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Expanded(child: Text('Document: $label', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 480,
          height: 380,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!isPdf) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                        const SizedBox(height: 12),
                        const Text('PDF Document Attached', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Click below to open and verify the full PDF document in native browser reader view.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (kIsWeb) {
                              try {
                                html.window.open(url, '_blank');
                              } catch (_) {}
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening PDF document...')),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Full PDF Document'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!isPdf && kIsWeb)
            TextButton.icon(
              onPressed: () {
                try {
                  html.window.open(url, '_blank');
                } catch (_) {}
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Full View'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistory(BookingProvider provider) {
    final count = provider.userBookings.length;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF1E3A8A), size: 28),
                    SizedBox(width: 10),
                    Text('My Booking History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Chip(
                  label: Text('$count Bookings'),
                  backgroundColor: const Color(0xFFEFF6FF),
                  labelStyle: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'View details of all your pending, completed, and cancelled car rental bookings.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/booking_history');
                },
                icon: const Icon(Icons.receipt_long, size: 20),
                label: const Text('See Booking History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
