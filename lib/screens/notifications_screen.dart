/// ============================================================
/// Notifications Screen
/// ============================================================
/// Shows all in-app notifications for the current user:
///   - Beacon join requests (with accept/reject actions)
///   - Request accepted/declined responses
///   - Message notifications
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final notifications = state.notifications;
    final topPadding = MediaQuery.of(context).padding.top;

    // Separate unread and read
    final unread = notifications.where((n) => !n.read).toList();
    final read = notifications.where((n) => n.read).toList();

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: CustomScrollView(
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
                          'Notifications',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${unread.length} unread',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: unread.isNotEmpty
                                    ? TSColors.primary
                                    : TSColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (unread.isNotEmpty)
                    GestureDetector(
                      onTap: () => state.markAllNotificationsRead(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: TSColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TSColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Empty State ──
          if (notifications.isEmpty)
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
                        child: Icon(Icons.notifications_none_rounded, color: TSColors.onSurfaceVariant,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'All Caught Up!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll see notifications here when someone wants to join your beacons or responds to your requests.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Unread Notifications ──
          if (unread.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: TSColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'New (${unread.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TSColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _NotificationTile(
                  notification: unread[index],
                  isUnread: true,
                ),
                childCount: unread.length,
              ),
            ),
          ],

          // ── Read Notifications ──
          if (read.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Earlier',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TSColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _NotificationTile(
                  notification: read[index],
                  isUnread: false,
                ),
                childCount: read.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

/// Individual notification tile with contextual actions
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isUnread;

  const _NotificationTile({
    required this.notification,
    required this.isUnread,
  });

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.joinRequest:
        return Icons.person_add_rounded;
      case NotificationType.requestAccepted:
        return Icons.check_circle_rounded;
      case NotificationType.requestDeclined:
        return Icons.cancel_rounded;
      case NotificationType.newMessage:
        return Icons.chat_bubble_rounded;
    }
  }

  List<Color> _iconColors() {
    switch (notification.type) {
      case NotificationType.joinRequest:
        return [TSColors.creativeAmber, TSColors.vibeCreative];
      case NotificationType.requestAccepted:
        return [TSColors.tertiary, TSColors.tertiaryDim];
      case NotificationType.requestDeclined:
        return [TSColors.error, TSColors.error.withOpacity(0.7)];
      case NotificationType.newMessage:
        return [TSColors.primary, TSColors.primaryDim];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final colors = _iconColors();
    final isJoinRequest = notification.type == NotificationType.joinRequest;
    final canAct = isJoinRequest && !notification.actionTaken;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? TSColors.surfaceContainerHigh
            : TSColors.surfaceContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: isUnread
            ? Border.all(
                color: TSColors.outlineVariant.withOpacity(0.1),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon(), color: TSColors.onSurface, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: TSColors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          notification.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isUnread
                                ? TSColors.onSurfaceVariant
                                : TSColors.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: TSColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Action Buttons for Join Requests ──
          if (canAct) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
                // Decline
                GestureDetector(
                  onTap: () {
                    if (notification.beaconId != null &&
                        notification.requesterId != null) {
                      state.declineJoinRequest(
                        beaconId: notification.beaconId!,
                        userId: notification.requesterId!,
                        notificationId: notification.id,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: TSColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, color: TSColors.error.withOpacity(0.8), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Decline',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TSColors.error.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Accept
                GestureDetector(
                  onTap: () {
                    if (notification.beaconId != null &&
                        notification.requesterId != null) {
                      state.acceptJoinRequest(
                        beaconId: notification.beaconId!,
                        userId: notification.requesterId!,
                        notificationId: notification.id,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TSColors.primary, TSColors.primaryDim],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            color: TSColors.onSurface, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Accept',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TSColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Resolved badge for already-actioned requests ──
          if (isJoinRequest && notification.actionTaken) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: TSColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓ Responded',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TSColors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
