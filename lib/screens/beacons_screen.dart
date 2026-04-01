/// ============================================================
/// Beacons Screen (PRD 3.2)
/// ============================================================
/// Shows all active user-generated beacons, sorted by distance
/// and time (zero-algorithm feed per PRD 7).
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class BeaconsScreen extends StatelessWidget {
  const BeaconsScreen({super.key});

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

  List<Color> _avatarColors(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz:
        return [TSColors.primary, TSColors.primaryDim];
      case VibeTag.deepWork:
        return [TSColors.secondary, TSColors.secondaryDim];
      case VibeTag.creativeFlow:
        return [TSColors.creativeAmber, TSColors.vibeCreative];
      case VibeTag.quietContemplation:
        return [TSColors.tertiary, TSColors.tertiaryDim];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final beacons = state.filteredBeacons;
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: () async => await state.refreshData(),
      color: TSColors.primary,
      backgroundColor: TSColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Beacons',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Spontaneous meetups happening now',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // ── Vibe Filter ──
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: state.activeVibeFilter == null,
                  onTap: () => state.setVibeFilter(null),
                ),
                ...VibeTag.values.map((vibe) => _FilterChip(
                      label: vibe.shortLabel,
                      color: _vibeColor(vibe),
                      isActive: state.activeVibeFilter == vibe,
                      onTap: () => state.setVibeFilter(
                        state.activeVibeFilter == vibe ? null : vibe,
                      ),
                    )),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Stream Error Banner ──
        if (state.lastStreamError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TSColors.error.withOpacity(0.1),
                  border: Border.all(color: TSColors.error.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Feed Error: ${state.lastStreamError}',
                  style: GoogleFonts.inter(
                    color: TSColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

        // ── Empty State ──
        if (beacons.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.sensors_off_rounded, color: TSColors.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active beacons',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TSColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to light one up! Tap the beacon button on the map.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // ── Beacon Cards ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final beacon = beacons[index];
                return _BeaconCard(
                  beacon: beacon,
                  avatarColors: _avatarColors(beacon.vibes.isNotEmpty
                      ? beacon.vibes.first
                      : VibeTag.socialBuzz),
                  onJoin: () => _showJoinModal(context, state, beacon),
                );
              },
              childCount: beacons.length,
            ),
          ),
        ),

        // Bottom spacing for nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
      ),
    );
  }

  void _showJoinModal(BuildContext context, AppState state, Beacon beacon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _JoinRequestSheet(
        beacon: beacon,
        onSend: () {
          state.requestJoinBeacon(beacon.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ── Beacon Card — Fixed layout, no overlapping ──
class _BeaconCard extends StatelessWidget {
  final Beacon beacon;
  final List<Color> avatarColors;
  final VoidCallback onJoin;

  const _BeaconCard({
    required this.beacon,
    required this.avatarColors,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Host Info + Timer ──
          Row(
            children: [
              GradientAvatar(
                initials: beacon.hostInitials,
                size: 44,
                colors: avatarColors,
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
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: TSColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Title ──
          if (beacon.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                beacon.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Description ──
          if (beacon.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                beacon.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Location + Capacity ──
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: TSColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  beacon.locationName,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.group_rounded, color: TSColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 4),
              Text(
                '${beacon.currentCount}/${beacon.maxCapacity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Vibe Tags ──
          if (beacon.vibes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: beacon.vibes
                    .map((v) => VibeChip(vibe: v, compact: true))
                    .toList(),
              ),
            ),

          // ── Actions ──
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Map',
                  icon: Icons.map_rounded,
                  onPressed: () {},
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: beacon.isFull
                      ? 'Full'
                      : beacon.seatsLeft == 1
                          ? '1 Seat Left!'
                          : 'Request to Join',
                  icon: Icons.handshake_rounded,
                  onPressed: beacon.isFull ? () {} : onJoin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ──
class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.color,
    required this.isActive,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? c.withOpacity(0.2)
              : TSColors.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(100),
          border:
              isActive ? Border.all(color: c.withOpacity(0.4), width: 1) : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? c : TSColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Join Request Bottom Sheet (PRD 7: Handshake System) ──
class _JoinRequestSheet extends StatelessWidget {
  final Beacon beacon;
  final VoidCallback onSend;

  const _JoinRequestSheet({required this.beacon, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TSColors.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: TSColors.primary.withOpacity(0.1),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Request to Join',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: TSColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GradientAvatar(initials: beacon.hostInitials, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(beacon.hostName,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(beacon.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: "Hey! I'd love to join...",
            ),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: TSColors.onSurface),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GradientButton(
                  label: 'Send Request',
                  icon: Icons.send_rounded,
                  onPressed: onSend,
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
