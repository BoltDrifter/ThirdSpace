/// ============================================================
/// Chat Screen — Individual Conversation
/// ============================================================
/// Real-time chat between two users with message bubbles,
/// timestamps, and input field.
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/shared_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserInitials;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserInitials,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = context
        .read<AppState>()
        .firebaseService
        .streamMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AppState>().sendChatMessage(
          conversationId: widget.conversationId,
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myUserId = state.firebaseUser?.uid ?? '';
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: TSColors.surface,
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.fromLTRB(12, topPadding + 8, 16, 12),
            decoration: BoxDecoration(
              color: TSColors.surface.withOpacity(0.92),
              border: Border(
                bottom: BorderSide(
                  color: TSColors.outlineVariant.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
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
                const SizedBox(width: 12),
                GradientAvatar(
                  initials: widget.otherUserInitials,
                  size: 38,
                  colors: [],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUserName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: TSColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ThirdSpace Chat',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: TSColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Messages List ──
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: TSColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: TSColors.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded, color: TSColors.onSurfaceVariant,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Say hello! 👋',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start the conversation with ${widget.otherUserName}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Auto-scroll when new messages arrive
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myUserId;
                    final showAvatar = index == 0 ||
                        messages[index - 1].senderId != msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showAvatar: showAvatar,
                      otherInitials: widget.otherUserInitials,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input Bar ──
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, keyboardHeight > 0 ? 10 : bottomPadding + 10),
            decoration: BoxDecoration(
              color: TSColors.surface.withOpacity(0.92),
              border: Border(
                top: BorderSide(
                  color: TSColors.outlineVariant.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: TSColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: TSColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: TSColors.onSurfaceVariant.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TSColors.primary, TSColors.primaryDim],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: TSColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: TSColors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single message bubble
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final String otherInitials;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.otherInitials,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showAvatar ? 12 : 4,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user's avatar
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GradientAvatar(
                initials: otherInitials,
                size: 28,
                colors: [],
              ),
            )
          else if (!isMe)
            const SizedBox(width: 36),

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? TSColors.primary.withOpacity(0.2)
                    : TSColors.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: isMe
                    ? Border.all(
                        color: TSColors.primary.withOpacity(0.15), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: TSColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: TSColors.onSurfaceVariant.withOpacity(0.6),
                    ),
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
