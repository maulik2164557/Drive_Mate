import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../services/database_service.dart';
import '../../../core/widgets/app_navbar.dart';
import '../../../core/widgets/app_footer.dart';

class AdminDirectoryScreen extends StatelessWidget {
  const AdminDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: const AppNavbar(title: 'Admin Directory & Approvals'),
      body: StreamBuilder<List<UserModel>>(
        stream: dbService.getAdminUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAdmins = snapshot.data ?? [];
          final pendingAdmins = allAdmins.where((a) => !a.adminApproved).toList();
          final approvedAdmins = allAdmins.where((a) => a.adminApproved).toList();

          return DefaultTabController(
            length: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Tab Bar Header
                  Container(
                    color: const Color(0xFF1E3A8A),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.amber,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.pending_actions),
                          text: 'Pending Approvals (${pendingAdmins.length})',
                        ),
                        Tab(
                          icon: const Icon(Icons.verified_user),
                          text: 'Active Admin Directory (${approvedAdmins.length})',
                        ),
                      ],
                    ),
                  ),

                  // Tab Contents
                  SizedBox(
                    height: 650,
                    child: TabBarView(
                      children: [
                        _buildPendingTab(context, pendingAdmins, dbService),
                        _buildDirectoryTab(approvedAdmins),
                      ],
                    ),
                  ),

                  const AppFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTab(BuildContext context, List<UserModel> pendingAdmins, DatabaseService dbService) {
    if (pendingAdmins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'No pending admin approval requests.',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: pendingAdmins.length,
      itemBuilder: (context, index) {
        final admin = pendingAdmins[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.person_add, color: Colors.orange, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(admin.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          Chip(
                            label: const Text('Pending Approval', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.orange.shade50,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Email: ${admin.email}', style: const TextStyle(color: Colors.grey)),
                      Text('Mobile: ${admin.mobileNumber}', style: const TextStyle(color: Colors.grey)),
                      Text('Signed Up: ${DateFormat('dd MMM yyyy, hh:mm a').format(admin.createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await dbService.approveAdminUser(admin.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${admin.fullName} has been approved as Administrator!'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Approve Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectoryTab(List<UserModel> approvedAdmins) {
    if (approvedAdmins.isEmpty) {
      return const Center(child: Text('No active administrators found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: approvedAdmins.length,
      itemBuilder: (context, index) {
        final admin = approvedAdmins[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.admin_panel_settings, color: Color(0xFF1E3A8A), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(admin.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.verified, size: 12, color: Colors.green),
                            label: const Text('Approved Admin ✓', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.green.shade50,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('System Email: ${admin.email}', style: const TextStyle(color: Colors.grey)),
                      Text('Contact Phone: ${admin.mobileNumber}', style: const TextStyle(color: Colors.grey)),
                      Text('Account Created: ${DateFormat('dd MMM yyyy').format(admin.createdAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
}
