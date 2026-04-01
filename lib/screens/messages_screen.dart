/// ============================================================
/// Messages Screen — Conversation List
/// ============================================================
/// Shows all DM conversations for the current user.
/// Tapping a conversation opens the ChatScreen.
/// ============================================================
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final conversations = state.conversations;
    final userId = state.firebaseUser?.uid ?? '';
    final topPadding = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your conversations',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // New message button
                GestureDetector(
                  onTap: () => _showNewMessageSheet(context, state),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TSColors.primary, TSColors.primaryDim],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: TSColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: TSColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Empty State ──
        if (conversations.isEmpty)
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
                      child: Icon(
                        Icons.forum_rounded,
                        color: TSColors.onSurfaceVariant,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Messages Yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with someone from a beacon or your notifications.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Start a Conversation',
                      icon: Icons.edit_rounded,
                      onPressed: () => _showNewMessageSheet(context, state),
                      isFullWidth: false,
                      isSmall: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Conversation List ──
        if (conversations.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final convo = conversations[index];
                return _ConversationTile(
                  conversation: convo,
                  myUserId: userId,
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => ChatScreen(
                          conversationId: convo.id,
                          otherUserName: convo.otherName(userId),
                          otherUserInitials: convo.otherInitials(userId),
                        ),
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
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    );
                  },
                );
              },
              childCount: conversations.length,
            ),
          ),

        // Bottom spacing for nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showNewMessageSheet(BuildContext context, AppState state) {
    final myId = state.firebaseUser?.uid ?? '';

    // Collect unique users from beacons and notifications
    final userMap = <String, String>{}; // userId -> userName
    for (final beacon in state.beacons) {
      if (beacon.hostUserId != myId && beacon.hostUserId.isNotEmpty) {
        userMap[beacon.hostUserId] = beacon.hostName;
      }
    }
    for (final notif in state.notifications) {
      if (notif.requesterId != null &&
          notif.requesterId!.isNotEmpty &&
          notif.requesterId != myId) {
        userMap[notif.requesterId!] = notif.requesterName ?? 'User';
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NewMessageSheet(
        state: state,
        myId: myId,
        beaconUserMap: userMap,
        parentContext: context,
      ),
    );
  }
}

class _NewMessageSheet extends StatefulWidget {
  final AppState state;
  final String myId;
  final Map<String, String> beaconUserMap;
  final BuildContext parentContext;

  const _NewMessageSheet({
    required this.state,
    required this.myId,
    required this.beaconUserMap,
    required this.parentContext,
  });

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() { _searchResults = []; _hasSearched = false; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await widget.state.firebaseService.searchUsersByUsername(query);
      final filtered = results.where((r) => r['userId'] != widget.myId).toList();
      if (mounted) setState(() { _searchResults = filtered; _hasSearched = true; _isSearching = false; });
    });
  }

  Future<void> _openChat(String userId, String userName, String initials) async {
    Navigator.pop(context);
    final convId = await widget.state.startConversation(userId);
    if (convId != null && widget.parentContext.mounted) {
      Navigator.of(widget.parentContext).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ChatScreen(
            conversationId: convId,
            otherUserName: userName,
            otherUserInitials: initials.isEmpty ? 'U' : initials,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  Widget _userTile({
    required String userId,
    required String userName,
    required String initials,
    String? username,
  }) {
    return GestureDetector(
      onTap: () => _openChat(userId, userName, initials),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TSColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            GradientAvatar(initials: initials.isEmpty ? 'U' : initials, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w600, color: TSColors.onSurface,
                    ),
                  ),
                  if (username != null && username.isNotEmpty)
                    Text(
                      '@$username',
                      style: GoogleFonts.inter(fontSize: 12, color: TSColors.primary.withOpacity(0.8)),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: TSColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBeaconUsers = widget.beaconUserMap.isNotEmpty;
    final showDivider = _searchResults.isNotEmpty && hasBeaconUsers;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: TSColors.surfaceContainer.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TSColors.outlineVariant.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: TSColors.primary.withOpacity(0.1), blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('New Message', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: TSColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Search by @username or choose a suggested person',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            autocorrect: false,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search @username...',
              prefixIcon: const Icon(Icons.search_rounded, color: TSColors.onSurfaceVariant, size: 20),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Icon(Icons.close_rounded, color: TSColors.onSurfaceVariant, size: 18),
                    )
                  : null,
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TSColors.onSurface),
          ),
          const SizedBox(height: 16),

          // Results area
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Search results
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(color: TSColors.primary, strokeWidth: 2)),
                  )
                else if (_hasSearched && _searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No users found.', style: Theme.of(context).textTheme.bodySmall),
                  )
                else
                  for (final result in _searchResults)
                    _userTile(
                      userId: result['userId'] as String,
                      userName: result['name'] as String,
                      initials: result['initials'] as String,
                      username: result['username'] as String?,
                    ),

                // Divider between search results and suggestions
                if (showDivider) ...[
                  const SizedBox(height: 8),
                  Divider(color: TSColors.outlineVariant.withOpacity(0.2)),
                  const SizedBox(height: 4),
                ],

                // Beacon suggestions
                if (hasBeaconUsers) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'From your beacons',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: TSColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final entry in widget.beaconUserMap.entries)
                    _userTile(
                      userId: entry.key,
                      userName: entry.value,
                      initials: UserProfile.computeInitials(entry.value),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single conversation tile in the list
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String myUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.myUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.otherName(myUserId);
    final otherInitials = conversation.otherInitials(myUserId);
    final isMyLastMsg = conversation.lastMessageBy == myUserId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TSColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Avatar
            GradientAvatar(
              initials: otherInitials,
              size: 48,
              colors: [],
            ),
            const SizedBox(width: 14),

            // Name + Last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TSColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TSColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage.isEmpty
                        ? 'Start chatting...'
                        : isMyLastMsg
                            ? 'You: ${conversation.lastMessage}'
                            : conversation.lastMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: TSColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
