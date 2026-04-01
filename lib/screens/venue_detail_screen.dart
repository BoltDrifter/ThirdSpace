/// ============================================================
/// Venue Detail Screen (PRD 3.1 + 3.3)
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key});
  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  final _pulseController = TextEditingController();
  VibeTag? _selectedVote;

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  Color _vibeColor(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz: return TSColors.vibeSocial;
      case VibeTag.deepWork: return TSColors.vibeDeepWork;
      case VibeTag.creativeFlow: return TSColors.vibeCreative;
      case VibeTag.quietContemplation: return TSColors.vibeQuiet;
    }
  }

  IconData _vibeIcon(VibeTag vibe) {
    switch (vibe) {
      case VibeTag.socialBuzz: return Icons.celebration_rounded;
      case VibeTag.deepWork: return Icons.headphones_rounded;
      case VibeTag.creativeFlow: return Icons.palette_rounded;
      case VibeTag.quietContemplation: return Icons.spa_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final venue = state.selectedVenue;
    if (venue == null) return const SizedBox.shrink();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _vibeColor(venue.vibes.first).withOpacity(0.15),
                    TSColors.surface,
                  ],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () { state.clearVenueSelection(); Navigator.pop(context); },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: TSColors.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.arrow_back_rounded, color: TSColors.onSurface, size: 20),
                  ),
                ),
                const SizedBox(height: 20),
                Text(venue.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on_rounded, color: TSColors.onSurfaceVariant, size: 16),
                  const SizedBox(width: 4),
                  Text(venue.address, style: Theme.of(context).textTheme.bodyMedium),
                ]),
                const SizedBox(height: 12),
                Text(venue.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TSColors.onSurfaceVariant)),
              ]),
            ),
          ),

          // ── Energy Bar ──
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: EnergyBar(value: venue.crowdDensity, label: venue.energyLevel))),

          // ── Current Vibe ──
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Current Vibe'),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Wrap(spacing: 8, children: venue.vibes.map((v) => VibeChip(vibe: v, isSelected: true)).toList())),
          ])),

          // ── Set the Vibe (Vote) ──
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Set the Vibe'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10,
                children: VibeTag.values.map((vibe) {
                  final isSelected = _selectedVote == vibe;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedVote = vibe); state.voteVibe(venue.id, vibe); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? _vibeColor(vibe).withOpacity(0.2) : TSColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: _vibeColor(vibe).withOpacity(0.4)) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_vibeIcon(vibe), color: _vibeColor(vibe), size: 20),
                        const SizedBox(height: 4),
                        Text(vibe.shortLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _vibeColor(vibe))),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ])),

          // ── Recent Pulses ──
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Recent Pulses'),
            ...venue.recentPulses.map((pulse) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GradientAvatar(initials: pulse.authorInitials, size: 38),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: TSColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                    child: Text(pulse.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TSColors.onSurface)),
                  ),
                  const SizedBox(height: 4),
                  Text(pulse.timeAgo, style: Theme.of(context).textTheme.labelSmall),
                ])),
              ]),
            )),
            // Pulse Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _pulseController, maxLength: 140,
                  decoration: const InputDecoration(hintText: 'Leave a pulse... (140 chars)', counterText: '', filled: true, fillColor: TSColors.surfaceContainerHigh),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TSColors.onSurface),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () { if (_pulseController.text.isNotEmpty) { state.sendPulse(venue.id, _pulseController.text); _pulseController.clear(); } },
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [TSColors.primary, TSColors.primaryDim]), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.send_rounded, color: TSColors.onSurface, size: 20),
                  ),
                ),
              ]),
            ),
          ])),

          // ── Active Beacons at Venue ──
          SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Active Beacons Here'),
            _VenueBeaconItem(icon: Icons.code_rounded, title: 'React Developers', desc: 'Discussing the future of RSC and building local networks.', seats: '3/5', colors: [TSColors.secondary, TSColors.secondaryDim]),
            _VenueBeaconItem(icon: Icons.draw_rounded, title: 'Urban Sketching', desc: 'Sketching the interior vibes.', seats: '2/4', colors: [TSColors.creativeAmber, TSColors.vibeCreative]),
          ])),

          // ── Check-In Button ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              GradientButton(label: 'Check In (Within 50m)', icon: Icons.my_location_rounded, onPressed: () => state.checkInToVenue(venue.id)),
              const SizedBox(height: 8),
              Text('You must be within 50 meters to verify your presence.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ]),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _VenueBeaconItem extends StatelessWidget {
  final IconData icon; final String title; final String desc; final String seats; final List<Color> colors;
  const _VenueBeaconItem({required this.icon, required this.title, required this.desc, required this.seats, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: TSColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: TSColors.onSurface, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(desc, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Row(children: [
            Icon(Icons.group_rounded, color: TSColors.onSurfaceVariant, size: 16),
            const SizedBox(width: 4),
            Text(seats, style: Theme.of(context).textTheme.labelMedium),
          ]),
        ]),
      ),
    );
  }
}
