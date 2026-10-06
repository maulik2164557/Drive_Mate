import 'package:flutter/material.dart';
import 'app_logo_widget.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      width: double.infinity,
      child: Column(
        children: [
          const Center(
            child: AppLogoWidget(
              isDarkBackground: true,
              iconSize: 42,
              fontSize: 26,
              subtitle: 'Gujarat\'s Premier Car Rental Network',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore Gujarat state like never before. 33 District Depots • 24/7 Roadside Assistance • Unlimited Kilometers',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, indent: 40, endIndent: 40),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerBadge(Icons.security, '100% Insured Fleet'),
              const SizedBox(width: 24),
              _footerBadge(Icons.verified, 'Instant Verified KYC'),
              const SizedBox(width: 24),
              _footerBadge(Icons.payment, 'Secure Stripe Payments'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2026 DriveMate Rentals. All rights reserved. Made for Gujarat Operations.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _footerBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.amberAccent, size: 16),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
