library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:thirdspace/screens/notifications_screen.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';
import 'venue_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _hasCenteredOnUser = false;
  Beacon? _selectedMapBeacon;

  // Fallback center if location not available
  final LatLng _fallbackCenter = const LatLng(35.6580, 139.7010);

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

  IconData _vibeIcon(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz:
        return Icons.celebration_rounded;
      case VibeTag.deepWork:
        return Icons.headphones_rounded;
      case VibeTag.creativeFlow:
        return Icons.palette_rounded;
      case VibeTag.quietContemplation:
        return Icons.spa_rounded;
    }
  }

  void _openVenueDetail(BuildContext context, Venue venue) {
    final state = context.read<AppState>();
    state.selectVenue(venue);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const VenueDetailScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _centerOnUser(AppState state) {
    if (state.userLocation != null) {
      _mapController.move(state.userLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final venues = state.filteredVenues;
    final topPadding = MediaQuery.of(context).padding.top;
    final userLoc = state.userLocation;

    // Auto-center on user location once when first available
    if (userLoc != null && !_hasCenteredOnUser) {
      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(userLoc, 15.0);
      });
    }

    final mapCenter = userLoc ?? _fallbackCenter;

    return Stack(
      children: [
        // ── Real Map (flutter_map) ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 15.0,
            onTap: (_, __) {
              if (_selectedMapBeacon != null) {
                setState(() => _selectedMapBeacon = null);
              }
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Dark Mode CartoDB Map Tiles
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.thirdspace.thirdspace',
              maxZoom: 19,
            ),

            // Neon Gravity Markers for venues
            MarkerLayer(
              markers: [
                // ── User Location "You Are Here" Marker ──
                if (userLoc != null)
                  Marker(
                    point: userLoc,
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    child: const _UserLocationMarker(),
                  ),

                // ── Beacons (Color Coded) ──
                ...state.filteredBeacons.map((beacon) {
                  final vibeColor = beacon.vibes.isNotEmpty
                      ? _vibeColor(beacon.vibes.first)
                      : TSColors.primary;
                  final vibeIcon = beacon.vibes.isNotEmpty
                      ? _vibeIcon(beacon.vibes.first)
                      : Icons.sensors_rounded;

                  return Marker(
                    point: beacon.location,
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _selectedMapBeacon = beacon);
                        _mapController.move(beacon.location, 16.0);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: vibeColor.withOpacity(0.6),
                                  blurRadius: 16,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                          ),
                          // Inner circle
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: TSColors.surface.withOpacity(0.95),
                              shape: BoxShape.circle,
                              border: Border.all(color: vibeColor, width: 2),
                            ),
                            child: Icon(vibeIcon, color: vibeColor, size: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // ── Venue Markers ──
                ...venues.map((venue) {
                  return Marker(
                    point: venue.location,
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openVenueDetail(context, venue),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GravityPulse(
                            intensity: venue.crowdDensity,
                            color: _vibeColor(venue.vibes.first),
                            size: 70,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: TSColors.surface.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              venue.name,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TSColors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // ── Top Header Bar (Glass) — No Search Bar ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TSColors.surface.withOpacity(0.95),
                  TSColors.surface.withOpacity(0.0),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_rounded, color: TSColors.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  'ThirdSpace',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TSColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Stack(
                  children: [
                    _GlassIconButton(
                      icon: Icons.notifications_rounded,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen()));
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: TSColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Vibe Filter Chips ──
        Positioned(
          top: topPadding + 68,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _VibeFilterChip(
                  label: 'All Vibes',
                  icon: Icons.blur_on_rounded,
                  isActive: state.activeVibeFilter == null,
                  onTap: () => state.setVibeFilter(null),
                ),
                ...VibeTag.values.map((vibe) => _VibeFilterChip(
                      label: vibe.label,
                      icon: _vibeIcon(vibe),
                      isActive: state.activeVibeFilter == vibe,
                      color: _vibeColor(vibe),
                      onTap: () => state.setVibeFilter(
                        state.activeVibeFilter == vibe ? null : vibe,
                      ),
                    )),
              ],
            ),
          ),
        ),

        // ── Recenter on User Location Button ──
        if (userLoc != null)
          Positioned(
            bottom: 100, // Positioned directly above the bottom-right FAB
            right: 16,
            child: GestureDetector(
              onTap: () => _centerOnUser(state),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TSColors.surfaceContainer.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TSColors.outlineVariant.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TSColors.primary.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: TSColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),

        // ── Location Loading Indicator ──
        if (state.locationLoading)
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TSColors.surfaceContainer.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(TSColors.primary),
                  ),
                ),
              ),
            ),
          ),

        // ── Map Cards (Bottom) ──
        if (_selectedMapBeacon != null)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: _MapBeaconCard(
              beacon: _selectedMapBeacon!,
              onClose: () => setState(() => _selectedMapBeacon = null),
              onJoin: () {
                state.requestJoinBeacon(_selectedMapBeacon!.id);
                setState(() => _selectedMapBeacon = null);
              },
            ),
          )
        else if (venues.isNotEmpty)
          Positioned(
            bottom: 30, // Above nav bar
            left: 16,
            right: 16,
            child: _HotZoneCard(
              venue: venues.first,
              onExplore: () {
                _mapController.move(venues.first.location, 17.0);
              },
            ),
          ),
      ],
    );
  }
}

// ── User Location "You Are Here" Marker ──
class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();

  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _controller.value;
        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Container(
                width: 40 + 30 * pulse,
                height: 40 + 30 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TSColors.primary.withOpacity(0.12 * (1 - pulse)),
                ),
              ),
              // Inner ring
              Container(
                width: 28 + 12 * pulse,
                height: 28 + 12 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TSColors.primary.withOpacity(0.2 * (1 - pulse * 0.5)),
                ),
              ),
              // Core dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TSColors.primary,
                  border: Border.all(color: TSColors.onSurface, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: TSColors.primary.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: TSColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: TSColors.onSurface, size: 20),
      ),
    );
  }
}

class _VibeFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _VibeFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? TSColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isActive ? c.withOpacity(0.2) : TSColors.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(100),
          border:
              isActive ? Border.all(color: c.withOpacity(0.4), width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? c : TSColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? c : TSColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotZoneCard extends StatelessWidget {
  final Venue venue;
  final VoidCallback onExplore;

  const _HotZoneCard({required this.venue, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TSColors.outlineVariant.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: TSColors.primary.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Nearest Hot Zone',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TSColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: TSColors.tertiary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TSColors.tertiary.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            venue.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Active right now in your circle',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(Icons.group_rounded, '${venue.checkinCount} people'),
              const SizedBox(width: 12),
              _StatChip(
                  Icons.sensors_rounded, '${venue.activeBeaconCount} beacons'),
              const SizedBox(width: 12),
              _StatChip(Icons.near_me_rounded, '${venue.distanceKm} km'),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Locate Zone',
            icon: Icons.navigation_rounded,
            onPressed: onExplore,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: TSColors.onSurfaceVariant, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: TSColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Map Beacon Card Overlay ──
class _MapBeaconCard extends StatelessWidget {
  final Beacon beacon;
  final VoidCallback onClose;
  final VoidCallback onJoin;

  const _MapBeaconCard({
    required this.beacon,
    required this.onClose,
    required this.onJoin,
  });

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TSColors.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: TSColors.primary.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GradientAvatar(
                initials: beacon.hostInitials,
                size: 40,
                colors: beacon.vibes.isNotEmpty
                    ? [
                        _vibeColor(beacon.vibes.first),
                        _vibeColor(beacon.vibes.first).withOpacity(0.6)
                      ]
                    : [TSColors.primary, TSColors.primaryDim],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      beacon.hostName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Host • ${beacon.hostLevel}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: TSColors.surfaceContainerHighest.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: TSColors.onSurfaceVariant, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (beacon.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                beacon.title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: TSColors.creativeAmber, size: 14),
              const SizedBox(width: 4),
              Text(
                beacon.timeRemaining,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TSColors.creativeAmber,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.group_rounded, color: TSColors.onSurfaceVariant, size: 14),
              const SizedBox(width: 4),
              Text(
                '${beacon.currentCount}/${beacon.maxCapacity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: beacon.isFull ? 'Full' : 'Request to Join',
            icon: Icons.handshake_rounded,
            onPressed: beacon.isFull ? () {} : onJoin,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
