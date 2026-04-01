import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, bottomPadding + 24),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
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
          ),
          const SizedBox(height: 48),
          Image.asset(
            'assets/logo.png',
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.explore_rounded, color: TSColors.primary, size: 80),
          ),
          const SizedBox(height: 24),
          Text('ThirdSpace', style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: TSColors.onSurface, letterSpacing: -1.0)),
          const SizedBox(height: 8),
          Text('Your Social Gravity Map', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: TSColors.onSurfaceVariant)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TSColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Icon(Icons.people_rounded, color: TSColors.primary, size: 32),
              const SizedBox(height: 16),
              Text(
                'We believe that the best connections happen in the real world. ThirdSpace empowers you to turn your current location into an active social beacon, bringing people together around shared vibes and interests.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: TSColors.onSurfaceVariant),
              ),
            ]),
          ),
          const SizedBox(height: 40),
          Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: 13, color: TSColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Text('Terms of Service', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: TSColors.primary)),
          ),
          const SizedBox(height: 20),
          Text('© 2026 ThirdSpace Inc. All rights reserved.', style: GoogleFonts.inter(fontSize: 12, color: TSColors.onSurfaceVariant.withOpacity(0.5))),
        ]),
      ),
    );
  }
}
