import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isGuest;
  final String? title;
  final bool? showBackButton;

  const AppNavbar({
    super.key,
    this.isGuest = false,
    this.title,
    this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final canPop = showBackButton ?? Navigator.canPop(context);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: InkWell(
        onTap: () {
          // If logged in as admin, go to admin_dashboard; if regular, go to user_dashboard; if guest, root
          if (user == null) {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          } else if (user.role == 'admin') {
            Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/user_dashboard', (route) => false);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Color(0xFF1E3A8A), size: 28),
            const SizedBox(width: 8),
            Text(
              title != null ? 'DriveMate • $title' : 'DriveMate',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (user == null) ...[
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signin'),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Up'),
          ),
        ] else ...[
          if (user.role == 'admin')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: const Text('Admin', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFE0E7FF),
                onPressed: () => Navigator.pushNamed(context, '/admin_dashboard'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28, color: Color(0xFF1E3A8A)),
            tooltip: 'My Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
