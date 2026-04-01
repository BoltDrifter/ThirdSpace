/// ============================================================
/// Drop a Beacon Screen (PRD 3.2)
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class DropBeaconScreen extends StatefulWidget {
  const DropBeaconScreen({super.key});
  @override
  State<DropBeaconScreen> createState() => _DropBeaconScreenState();
}

class _DropBeaconScreenState extends State<DropBeaconScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final Set<VibeTag> _selectedVibes = {};
  int _tableSize = 3;
  int _durationHours = 2;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  void _submit() {
    if (_titleController.text.isEmpty || _selectedVibes.isEmpty) return;
    final state = context.read<AppState>();
    state.dropBeacon(
      title: _titleController.text,
      description: _descController.text,
      vibes: _selectedVibes.toList(),
      tableSize: _tableSize,
      durationHours: _durationHours,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: TSColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 8),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: TSColors.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: TSColors.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Drop a Beacon', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Signal your presence to the world', style: Theme.of(context).textTheme.bodySmall),
                ])),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _FormLabel('Beacon Title'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController, maxLength: 60,
                  decoration: const InputDecoration(hintText: "e.g., Reading at the park...", counterText: ''),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TSColors.onSurface),
                ),
                const SizedBox(height: 20),
                const _FormLabel("What's the vibe?"),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController, maxLength: 200, maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Describe your activity...', counterText: ''),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TSColors.onSurface),
                ),
                const SizedBox(height: 24),
                const _FormLabel('Select Vibe Tags'),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: VibeTag.values.map((vibe) {
                  final sel = _selectedVibes.contains(vibe);
                  return GestureDetector(
                    onTap: () => setState(() { sel ? _selectedVibes.remove(vibe) : _selectedVibes.add(vibe); }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _vibeColor(vibe).withOpacity(0.2) : TSColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: sel ? Border.all(color: _vibeColor(vibe).withOpacity(0.4)) : null,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_vibeIcon(vibe), size: 18, color: sel ? _vibeColor(vibe) : TSColors.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(vibe.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? _vibeColor(vibe) : TSColors.onSurfaceVariant)),
                      ]),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 28),
                const _FormLabel('Table Size'),
                const SizedBox(height: 4),
                Text('Keep it intimate. How many people can join?', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(children: List.generate(5, (i) {
                  final size = i + 2; final isActive = _tableSize == size;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _tableSize = size),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive ? TSColors.primary.withOpacity(0.15) : TSColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: isActive ? Border.all(color: TSColors.primary.withOpacity(0.4)) : null,
                      ),
                      child: Center(child: Text('$size', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: isActive ? TSColors.primary : TSColors.onSurfaceVariant))),
                    ),
                  ));
                })),
                const SizedBox(height: 28),
                const _FormLabel('Duration'),
                const SizedBox(height: 4),
                Text('Beacons auto-expire to keep the map fresh.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(children: [1, 2, 3].asMap().entries.map((e) {
                  final i = e.key; final hrs = e.value; final isActive = _durationHours == hrs;
                  return Expanded(child: GestureDetector(
                    onTap: () => setState(() => _durationHours = hrs),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive ? TSColors.primary.withOpacity(0.15) : TSColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: isActive ? Border.all(color: TSColors.primary.withOpacity(0.4)) : null,
                      ),
                      child: Center(child: Text('$hrs hr${hrs > 1 ? 's' : ''}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? TSColors.primary : TSColors.onSurfaceVariant))),
                    ),
                  ));
                }).toList()),
                const SizedBox(height: 28),
                const _NoticeCard(icon: Icons.verified_user_rounded, iconColor: TSColors.tertiary, title: 'The Handshake System', description: "Acceptance Required — You'll review and approve each join request based on minimal profiles."),
                const SizedBox(height: 12),
                const _NoticeCard(icon: Icons.warning_rounded, iconColor: TSColors.creativeAmber, title: 'Anti-Ghosting Rule', description: 'If you leave the area for more than 10 minutes, your Beacon will auto-extinguish.'),
                const SizedBox(height: 28),
                GradientButton(label: 'Light Your Beacon', icon: Icons.sensors_rounded, onPressed: _submit),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleSmall);
}

class _NoticeCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title; final String description;
  const _NoticeCard({required this.icon, required this.iconColor, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TSColors.surfaceContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    );
  }
}
