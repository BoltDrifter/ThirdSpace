import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: TSColors.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.arrow_back_rounded, color: TSColors.onSurface, size: 22),
              ),
            ),
            const SizedBox(height: 28),
            Text('Privacy & Safety', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: TSColors.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Your safety is our priority in the ThirdSpace.', style: GoogleFonts.inter(fontSize: 15, color: TSColors.onSurfaceVariant)),
            const SizedBox(height: 32),
            _Section(title: 'Location Privacy', icon: Icons.location_off_rounded, content: 'We use location-fuzzing technology to ensure your exact coordinates are never broadcast publicly. Beacons show an approximate area until you explicitly accept a join request.'),
            const SizedBox(height: 24),
            _Section(title: 'Data Control', icon: Icons.admin_panel_settings_rounded, content: 'You own your data. You can delete your beacons, messages, and profile at any time. We do not sell your personal data to third parties.'),
            const SizedBox(height: 24),
            _Section(title: 'Community Guidelines', icon: Icons.groups_rounded, content: 'Respect is the core of ThirdSpace. Any harassment, hate speech, or inappropriate behavior at our physical beacon meetups will result in immediate bans. Please report any unsafe behavior.'),
            const SizedBox(height: 24),
            _Section(title: 'Ghost Score Rating', icon: Icons.speed_rounded, content: 'Your Ghost Score holds you accountable. If you consistently fail to show up for beacons you commit to, your score drops, signaling unreliability to the community.'),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  const _Section({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TSColors.outlineVariant.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: TSColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: TSColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: TSColors.onSurface))),
        ]),
        const SizedBox(height: 16),
        Text(content, style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: TSColors.onSurfaceVariant)),
      ]),
    );
  }
}
