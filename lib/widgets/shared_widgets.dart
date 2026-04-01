// ============================================================
// Shared Widgets — ThirdSpace Design System Components
// ============================================================
// Reusable components following the "Neon Pulse" design system.
// All glassmorphism, vibe chips, gravity pulses live here.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/models.dart';

// ─────────────────────────────────────────────────────────────
// VIBE CHIP — Pill-shaped tag with vibe-specific accent color
// ─────────────────────────────────────────────────────────────
class VibeChip extends StatelessWidget {
  final VibeTag vibe;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  const VibeChip({
    super.key,
    required this.vibe,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  Color _vibeColor() {
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
    final color = _vibeColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(100),
          border: isSelected
              ? Border.all(color: color.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Text(
          vibe.label,
          style: GoogleFonts.inter(
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLASS CARD — Glassmorphic container following "Glass & Gradient" rule
// ─────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.opacity = 0.85,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TSColors.surfaceContainer.withOpacity(opacity),
          borderRadius: BorderRadius.circular(24),
          // "Ghost Border" — outline-variant at 15% opacity
          border: Border.all(
            color: TSColors.outlineVariant.withOpacity(0.08),
            width: 1,
          ),
          // Ambient shadow with primary tint per design system
          boxShadow: [
            BoxShadow(
              color: TSColors.primary.withOpacity(0.04),
              blurRadius: 40,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRADIENT BUTTON — "The Glow" primary CTA
// ─────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isFullWidth;
  final bool isSmall;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isFullWidth = true,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TSColors.primary, TSColors.primaryDim],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TSColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 16 : 24,
              vertical: isSmall ? 12 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isSmall ? 18 : 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: TSColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLASS BUTTON — "The Glass" secondary action
// ─────────────────────────────────────────────────────────────
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: TSColors.surfaceVariant.withOpacity(0.2),
          side: BorderSide(color: TSColors.outlineVariant.withOpacity(0.15)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: TSColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TSColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRAVITY PULSE — Animated map marker with pulsing halo
// ─────────────────────────────────────────────────────────────
class GravityPulse extends StatefulWidget {
  final double intensity; // 0.0 → 1.0
  final Color color;
  final double size;
  final bool isBeacon;

  const GravityPulse({
    super.key,
    required this.intensity,
    this.color = TSColors.primary,
    this.size = 60,
    this.isBeacon = false,
  });

  @override
  State<GravityPulse> createState() => _GravityPulseState();
}

class _GravityPulseState extends State<GravityPulse>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          final pulse = _pulseController.value;
          final glow = _glowController.value;
          return CustomPaint(
            painter: _GravityPulsePainter(
              pulse: pulse,
              glow: glow,
              intensity: widget.intensity,
              color: widget.color,
              isBeacon: widget.isBeacon,
            ),
          );
        },
      ),
    );
  }
}

class _GravityPulsePainter extends CustomPainter {
  final double pulse;
  final double glow;
  final double intensity;
  final Color color;
  final bool isBeacon;

  _GravityPulsePainter({
    required this.pulse,
    required this.glow,
    required this.intensity,
    required this.color,
    required this.isBeacon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer pulsing halo (10% opacity surface-tint)
    final haloRadius = maxRadius * (0.6 + 0.4 * pulse);
    final haloPaint = Paint()
      ..color = color.withOpacity(0.08 * (1 - pulse) * intensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, haloRadius, haloPaint);

    // Second ring
    final ring2Radius = maxRadius * (0.4 + 0.3 * pulse);
    final ring2Paint = Paint()
      ..color = color.withOpacity(0.12 * (1 - pulse * 0.5) * intensity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, ring2Radius, ring2Paint);

    // Glow aura
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.3 * intensity),
          color.withOpacity(0.05 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 0.5));
    canvas.drawCircle(center, maxRadius * 0.5, glowPaint);

    // Core dot
    final coreRadius = 6.0 + 2.0 * glow;
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, corePaint);

    // Bright center
    canvas.drawCircle(
      center,
      coreRadius * 0.4,
      Paint()..color = TSColors.onSurface.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _GravityPulsePainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────
// ENERGY BAR — Live crowd density indicator
// ─────────────────────────────────────────────────────────────
class EnergyBar extends StatelessWidget {
  final double value; // 0.0 → 1.0
  final String label;

  const EnergyBar({super.key, required this.value, required this.label});

  Color _barColor() {
    if (value >= 0.7) return TSColors.tertiary;
    if (value >= 0.4) return TSColors.creativeAmber;
    return TSColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: _barColor(), size: 20),
          const SizedBox(width: 8),
          Text('Live Energy',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: TSColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _barColor(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION HEADER — Consistent section titles
// ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TSColors.onSurfaceVariant,
                ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AVATAR — Gradient initials avatar
// ─────────────────────────────────────────────────────────────
class GradientAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final List<Color>? colors;

  const GradientAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [TSColors.primary, TSColors.primaryDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: TSColors.onSurface,
          ),
        ),
      ),
    );
  }
}
