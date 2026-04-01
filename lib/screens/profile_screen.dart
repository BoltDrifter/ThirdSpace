/// ============================================================
/// Profile Screen
/// ============================================================
/// User profile with stats, vibe identity breakdown,
/// ghost score (reliability metric from PRD 7), and
/// user photo from Firebase Auth.
/// ============================================================
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';
import 'beacon_requests_screen.dart';
import 'notifications_screen.dart';
import 'privacy_safety_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _vibeColor(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz:
        return TSColors.vibeSocial;
      case VibeTag.deepWork:
        return TSColors.vibeDeepWork;
      case VibeTag.creativeFlow:
        return TSColors.vibeCreative;
      case VibeTag.quietContemplation:
        return TSColors.vibeQuiet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.userProfile;
    final user = state.firebaseUser;

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: TSColors.primary,
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your presence in the ThirdSpace',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // ── Profile Card ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: TSColors.surfaceContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar — Wrap with GestureDetector for editing
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, state),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              profile.photoUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => GradientAvatar(
                                initials: profile.initials,
                                size: 72,
                                colors: [],
                              ),
                            ),
                          )
                        else
                          GradientAvatar(
                            initials: profile.initials,
                            size: 72,
                            colors: [],
                          ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: TSColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: TSColors.surfaceContainer, width: 2),
                            ),
                            child: Icon(Icons.edit_rounded, color: TSColors.onSurface, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username — With Edit Icon
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, state),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_rounded, color: TSColors.onSurfaceVariant, size: 16),
                      ],
                    ),
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.email!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatColumn(
                        value: '${profile.checkinCount}',
                        label: 'Check-ins',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: TSColors.outlineVariant.withOpacity(0.15),
                      ),
                      _StatColumn(
                        value: '${profile.beaconsLit}',
                        label: 'Beacons Lit',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: TSColors.outlineVariant.withOpacity(0.15),
                      ),
                      _StatColumn(
                        value: '${profile.beaconsJoined}',
                        label: 'Joined',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Vibe Identity ──
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(title: 'Your Vibe Identity'),
              ...profile.vibeIdentity.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.key.label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _vibeColor(entry.key),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(entry.value * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _vibeColor(entry.key).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: TSColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _vibeColor(entry.key)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Ghost Score ──
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(title: 'Ghost Score'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: TSColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: _GhostScorePainter(
                            score: profile.ghostScore,
                          ),
                          child: Center(
                            child: Text(
                              '${(profile.ghostScore * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: TSColors.tertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reliability Score',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.eventsSignedUpFor == 0
                                  ? 'Start joining events to build your score!'
                                  : profile.ghostScore >= 0.8
                                      ? 'You show up! People trust you.'
                                      : profile.ghostScore >= 0.5
                                          ? 'Getting there — keep showing up!'
                                          : 'Try to keep your commitments.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Settings ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                _SettingsItem(
                  icon: Icons.handshake_rounded,
                  label: 'Beacon Requests',
                  subtitle: 'Manage who joins your beacons',
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const BeaconRequestsScreen(),
                        transitionsBuilder: (_, anim, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  subtitle: state.unreadNotificationCount > 0
                      ? '${state.unreadNotificationCount} unread'
                      : null,
                  badgeCount: state.unreadNotificationCount,
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const NotificationsScreen(),
                        transitionsBuilder: (_, anim, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy & Safety',
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            const PrivacySafetyScreen(),
                        transitionsBuilder: (_, anim, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Citizen Subscription',
                  subtitle: 'Priority beacons & community pass',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About ThirdSpace',
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AboutScreen(),
                        transitionsBuilder: (_, anim, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration:
                            const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SettingsItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: TSColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        title: Text(
                          'Sign Out',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        content: Text(
                          'Are you sure you want to sign out?',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: TSColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              state.signOut();
                            },
                            child: Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                color: TSColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController(text: state.userProfile?.name ?? '');
    final photoUrlController = TextEditingController(text: state.userProfile?.photoUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TSColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(ctx).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Display Name', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: TextStyle(color: TSColors.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: TSColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text('Profile Picture URL', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: photoUrlController,
              style: TextStyle(color: TSColors.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: TSColors.surfaceContainerHigh,
                hintText: 'https://example.com/photo.png',
                hintStyle: TextStyle(color: TSColors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: TSColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              state.updateProfile(
                name: nameController.text.trim(),
                photoUrl: photoUrlController.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: TSColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: TSColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final int badgeCount;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive ? TSColors.error : TSColors.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDestructive
              ? TSColors.error.withOpacity(0.08)
              : TSColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isDestructive ? TSColors.error : null,
                          )),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TSColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TSColors.error,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded,
                color: itemColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GhostScorePainter extends CustomPainter {
  final double score;

  _GhostScorePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = TSColors.surfaceContainerHighest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * score,
      false,
      Paint()
        ..color = TSColors.tertiary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostScorePainter oldDelegate) =>
      oldDelegate.score != score;
}
