/// ============================================================
/// Beacon Requests Screen
/// ============================================================
/// Shows all beacons created by the current user with their
/// pending join requests. Allows accepting or declining.
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class BeaconRequestsScreen extends StatelessWidget {
  const BeaconRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myBeacons = state.myBeacons;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: RefreshIndicator(
        color: TSColors.primary,
        backgroundColor: TSColors.surface,
        onRefresh: () async {
          await context.read<AppState>().refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: TSColors.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back_rounded, color: TSColors.onSurface, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beacon Requests',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Manage who joins your beacons',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Empty State ──
            if (myBeacons.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: TSColors.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(Icons.sensors_off_rounded, color: TSColors.onSurfaceVariant,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Active Beacons',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Light a beacon on the map to start receiving join requests from nearby people.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Beacon Cards with Requests ──
            if (myBeacons.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final beacon = myBeacons[index];
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _BeaconRequestCard(beacon: beacon),
                    );
                  },
                  childCount: myBeacons.length,
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

/// A card showing a beacon and its join requests
class _BeaconRequestCard extends StatelessWidget {
  final Beacon beacon;

  const _BeaconRequestCard({required this.beacon});

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
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: TSColors.outlineVariant.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Beacon Info Header ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TSColors.primary, TSColors.primaryDim],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: TSColors.onSurface,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beacon.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: TSColors.creativeAmber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                beacon.timeRemaining,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: TSColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.people_rounded, color: TSColors.onSurfaceVariant, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${beacon.currentCount}/${beacon.maxCapacity}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: TSColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Vibe chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: beacon.vibes.map((v) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _vibeColor(v).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        v.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _vibeColor(v),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Container(
            height: 0.5,
            color: TSColors.outlineVariant.withOpacity(0.1),
          ),

          // ── Join Requests List ──
          _JoinRequestsList(beaconId: beacon.id),
        ],
      ),
    );
  }
}

/// Streams and displays join requests for a specific beacon
class _JoinRequestsList extends StatefulWidget {
  final String beaconId;

  const _JoinRequestsList({required this.beaconId});

  @override
  State<_JoinRequestsList> createState() => _JoinRequestsListState();
}

class _JoinRequestsListState extends State<_JoinRequestsList> {
  late Stream<List<Map<String, dynamic>>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream =
        context.read<AppState>().firebaseService.streamJoinRequests(widget.beaconId);
  }

  @override
  void didUpdateWidget(_JoinRequestsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beaconId != widget.beaconId) {
      _requestsStream =
          context.read<AppState>().firebaseService.streamJoinRequests(widget.beaconId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TSColors.primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error streaming join requests: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error loading requests: ${snapshot.error}',
              style: TextStyle(color: TSColors.error),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.inbox_rounded, color: TSColors.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(width: 10),
                Text(
                  'No join requests yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: TSColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        // Separate pending from resolved
        final pending =
            requests.where((r) => r['status'] == 'pending').toList();
        final resolved =
            requests.where((r) => r['status'] != 'pending').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TSColors.creativeAmber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pending (${pending.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TSColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              ...pending.map((req) => _RequestTile(
                    beaconId: widget.beaconId,
                    request: req,
                    isPending: true,
                  )),
            ],
            if (resolved.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Resolved (${resolved.length})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TSColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
              ...resolved.map((req) => _RequestTile(
                    beaconId: widget.beaconId,
                    request: req,
                    isPending: false,
                  )),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

/// A single join request tile with accept/decline actions
class _RequestTile extends StatelessWidget {
  final String beaconId;
  final Map<String, dynamic> request;
  final bool isPending;

  const _RequestTile({
    required this.beaconId,
    required this.request,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final userName = request['userName']?.toString() ?? 'Unknown';
    final status = request['status']?.toString() ?? 'pending';
    
    final initials = userName.isNotEmpty && userName.trim().isNotEmpty
        ? userName
            .trim()
            .split(RegExp(r'\s+'))
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    final isAccepted = status == 'accepted';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPending
              ? TSColors.surfaceContainerHigh
              : TSColors.surfaceContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            GradientAvatar(
              initials: initials,
              size: 38,
              colors: isPending
                  ? []
                  : isAccepted
                      ? [TSColors.tertiary, TSColors.tertiaryDim]
                      : [TSColors.onSurfaceVariant.withOpacity(0.7), TSColors.onSurfaceVariant],
            ),
            const SizedBox(width: 12),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TSColors.onSurface,
                    ),
                  ),
                  if (!isPending)
                    Text(
                      isAccepted ? '✓ Accepted' : '✗ Declined',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isAccepted
                            ? TSColors.tertiary
                            : TSColors.error.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons (only for pending)
            if (isPending) ...[
              // Decline
              GestureDetector(
                onTap: () {
                  final state = context.read<AppState>();
                  state.declineJoinRequest(
                    beaconId: beaconId,
                    userId: request['userId']?.toString() ?? '',
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: TSColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close_rounded, color: TSColors.error.withOpacity(0.8), size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Accept
              GestureDetector(
                onTap: () {
                  final state = context.read<AppState>();
                  state.acceptJoinRequest(
                    beaconId: beaconId,
                    userId: request['userId']?.toString() ?? '',
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TSColors.primary, TSColors.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: TSColors.onSurface, size: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
