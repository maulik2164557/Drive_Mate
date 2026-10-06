import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'app_logo_widget.dart';

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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              if (canPop) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
              ],
              InkWell(
                onTap: () {
                  if (user == null) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  } else if (user.role == 'admin') {
                    Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (route) => false);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(context, '/user_dashboard', (route) => false);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: AppLogoWidget(
                    isDarkBackground: true,
                    iconSize: 28,
                    fontSize: 18,
                    subtitle: title != null ? title! : 'Gujarat Premium Rentals',
                  ),
                ),
              ),
              const Spacer(),
              if (user == null) ...[
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signin'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent.shade700,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else ...[
                if (user.role == 'admin')
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 14, color: Color(0xFF1E3A8A)),
                      label: const Text('Admin Workspace', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                      onPressed: () => Navigator.pushNamed(context, '/admin_dashboard'),
                    ),
                  )
                else ...[
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/booking_history'),
                    icon: const Icon(Icons.history, color: Colors.amberAccent, size: 20),
                    label: const Text('My History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: const Icon(Icons.account_circle, size: 26, color: Colors.white),
                  tooltip: 'My Profile',
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(66.0);
}
