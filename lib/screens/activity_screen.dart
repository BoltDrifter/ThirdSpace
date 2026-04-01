/// ============================================================
/// Activity Screen — ThirdSpace
/// ============================================================
/// Shows the activity feed distinct from the Beacons tab:
///   - Happening Now: Live status pulses from venues
///   - Trending Zones: Top venues by crowd density
///   - Your Activity: Timeline of check-ins and beacon events
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  Color _vibeColor(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz:
        return TSColors.primary;
      case VibeTag.deepWork:
        return TSColors.primary;
      case VibeTag.creativeFlow:
        return TSColors.primary;
      case VibeTag.quietContemplation:
        return TSColors.primary;
    }
  }

  IconData _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.checkin:
        return Icons.location_on_rounded;
      case ActivityType.beaconLit:
        return Icons.sensors_rounded;
      case ActivityType.beaconJoined:
        return Icons.group_add_rounded;
      case ActivityType.pulseSent:
        return Icons.favorite_rounded;
    }
  }

  Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.checkin:
        return TSColors.primary;
      case ActivityType.beaconLit:
        return TSColors.primary;
      case ActivityType.beaconJoined:
        return TSColors.primary;
      case ActivityType.pulseSent:
        return TSColors.primary;
    }
  }

  String _activityLabel(ActivityType type) {
    switch (type) {
      case ActivityType.checkin:
        return 'CHECK-IN';
      case ActivityType.beaconLit:
        return 'BEACON';
      case ActivityType.beaconJoined:
        return 'JOINED';
      case ActivityType.pulseSent:
        return 'PULSE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final feed = state.activityFeed;
    final trendingVenues = state.trendingVenues;
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
                  'Activity',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'What\'s happening in your network',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // ── Trending Zones Section ──
        if (trendingVenues.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Trending Zones 🔥'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: trendingVenues.length,
                itemBuilder: (context, index) {
                  final venue = trendingVenues[index];
                  return _TrendingZoneCard(
                    venue: venue,
                    rank: index + 1,
                    vibeColor: venue.vibes.isNotEmpty
                        ? _vibeColor(venue.vibes.first)
                        : TSColors.primary,
                  );
                },
              ),
            ),
          ),
        ],

        // ── Live Feed Header ──
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Live Feed'),
        ),

        // ── Activity Feed ──
        if (feed.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: TSColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.flash_on_rounded, color: TSColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activity yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check in to venues and light beacons\nto see activity here',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = feed[index];
                  return _ActivityCard(
                    item: item,
                    icon: _activityIcon(item.type),
                    color: item.vibe != null
                        ? _vibeColor(item.vibe!)
                        : _activityColor(item.type),
                    typeLabel: _activityLabel(item.type),
                    isLast: index == feed.length - 1,
                  );
                },
                childCount: feed.length,
              ),
            ),
          ),

        // Bottom spacing for nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Trending Zone Horizontal Card ──
class _TrendingZoneCard extends StatelessWidget {
  final Venue venue;
  final int rank;
  final Color vibeColor;

  const _TrendingZoneCard({
    required this.venue,
    required this.rank,
    required this.vibeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TSColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: vibeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: vibeColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  venue.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TSColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Energy bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: venue.crowdDensity,
              backgroundColor: TSColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(vibeColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_rounded, color: TSColors.primary),
              const SizedBox(width: 4),
              Text(
                '${venue.checkinCount} people',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: TSColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: vibeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  venue.energyLevel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: vibeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Activity Card with Timeline ──
class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final IconData icon;
  final Color color;
  final String typeLabel;
  final bool isLast;

  const _ActivityCard({
    required this.item,
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: TSColors.primary.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TSColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: TSColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TSColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TSColors.primary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
