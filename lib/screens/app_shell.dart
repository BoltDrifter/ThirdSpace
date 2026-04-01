/// ============================================================
/// App Shell — Bottom Navigation & View Routing
/// ============================================================
/// The main scaffold with glassmorphic bottom nav bar.
/// Routes between: Map, Beacons, Messages, Profile
/// Includes notification badge on Messages tab.
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'map_screen.dart';
import 'beacons_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'drop_beacon_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: TSColors.surface,
          body: Stack(
            children: [
              // ── Main Content ──
              IndexedStack(
                index: state.currentTabIndex,
                children: const [
                  MapScreen(),
                  BeaconsScreen(),
                  MessagesScreen(),
                  ProfileScreen(),
                ],
              ),

              // ── Toast Overlay ──
              if (state.toastMessage != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  child: _ToastBanner(message: state.toastMessage!),
                ),
            ],
          ),

          // ── Glassmorphic Bottom Nav ──
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: TSColors.surface.withOpacity(0.92),
              border: Border(
                top: BorderSide(
                  color: TSColors.outlineVariant.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.map_rounded,
                      label: 'Map',
                      isActive: state.currentTabIndex == 0,
                      onTap: () => state.setTab(0),
                    ),
                    _NavItem(
                      icon: Icons.sensors_rounded,
                      label: 'Beacons',
                      isActive: state.currentTabIndex == 1,
                      onTap: () => state.setTab(1),
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      isActive: state.currentTabIndex == 2,
                      onTap: () => state.setTab(2),
                      badgeCount: state.unreadConversationCount,
                    ),
                    _NavItemWithBadge(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isActive: state.currentTabIndex == 3,
                      onTap: () => state.setTab(3),
                      badgeCount: state.unreadNotificationCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FAB: Drop a Beacon ──
          floatingActionButton: state.currentTabIndex == 0
              ? Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TSColors.primary, TSColors.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: TSColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const DropBeaconScreen(),
                          transitionsBuilder: (_, anim, __, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(Icons.sensors_rounded, size: 28),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ── Bottom Nav Item ──
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? TSColors.primary : TSColors.onSurfaceVariant,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: TSColors.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: TSColors.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: TSColors.onSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? TSColors.primary : TSColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Nav Item with Badge (for Profile/Notifications) ──
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? TSColors.primary : TSColors.onSurfaceVariant,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TSColors.error, TSColors.creativeAmber],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: TSColors.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: TSColors.onSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? TSColors.primary : TSColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toast Banner ──
class _ToastBanner extends StatelessWidget {
  final String message;

  const _ToastBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: TSColors.surfaceContainerHighest.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TSColors.outlineVariant.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: TSColors.primary.withOpacity(0.1),
              blurRadius: 24,
            ),
          ],
        ),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TSColors.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
