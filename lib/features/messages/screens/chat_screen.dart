// FILE LOCATION: lib/features/messages/screens/chat_screen.dart
// FIX: sendMessage() now receives recipientId (the other participant).
//      markConversationRead() now receives currentUid so it only resets
//      the current user's own unread count.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../../core/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUid;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  /// The UID of the other participant — messages sent go to them.
  String get _recipientId => widget.conversation.otherId(widget.currentUid);

  @override
  void initState() {
    super.initState();
    // Reset only THIS user's unread count when they open the chat.
    context
        .read<MessagingProvider>()
        .markConversationRead(widget.conversation.id, widget.currentUid);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _textCtrl.clear();
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;

    await context.read<MessagingProvider>().sendMessage(
          conversationId: widget.conversation.id,
          senderId: widget.currentUid,
          senderName: user?.displayName ?? '',
          senderPhotoUrl: user?.photoUrl,
          recipientId: _recipientId,
          text: text,
        );

    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final otherName = conv.otherName(widget.currentUid);
    final otherPhoto = conv.otherPhotoUrl(widget.currentUid);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestDeep,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.cream, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.lemongrass.withOpacity(0.3),
              backgroundImage: otherPhoto != null
                  ? CachedNetworkImageProvider(otherPhoto)
                  : null,
              child: otherPhoto == null
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    conv.itemTitle,
                    style:
                        GoogleFonts.lato(fontSize: 11, color: AppColors.meadow),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ItemContextBanner(conv: conv),
          Expanded(
            child: StreamBuilder<List<AppMessage>>(
              stream: context.read<MessagingProvider>().messagesStream(conv.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.oliveGreen),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyChat(otherName);
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == widget.currentUid;
                    final showDate =
                        i == 0 || !_sameDay(messages[i - 1].sentAt, msg.sentAt);

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.sentAt),
                        _MessageBubble(message: msg, isMe: isMe)
                            .animate(delay: (i * 20).ms)
                            .fadeIn()
                            .slideY(begin: 0.05),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _ChatInputBar(
            controller: _textCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(String otherName) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waving_hand_outlined,
                  size: 52, color: AppColors.sunflowerGold)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.1, end: 0.1, duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Say hello to $otherName!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              color: AppColors.forestDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coordinate your meetup here.',
            style: GoogleFonts.lato(color: AppColors.oliveGreen, fontSize: 13),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// Item context banner

class _ItemContextBanner extends StatelessWidget {
  final Conversation conv;
  const _ItemContextBanner({required this.conv});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightMoss.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
              color: AppColors.lemongrass.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (conv.itemPhotoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: conv.itemPhotoUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lemongrass.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 18, color: AppColors.oliveGreen),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About: ${conv.itemTitle}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tap to coordinate your food exchange',
                  style: GoogleFonts.lato(
                      fontSize: 11, color: AppColors.oliveGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Message Bubble

class _MessageBubble extends StatelessWidget {
  final AppMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.lemongrass.withOpacity(0.3),
              backgroundImage: message.senderPhotoUrl != null
                  ? CachedNetworkImageProvider(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestDeep),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.oliveGreen : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.oliveGreen.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: isMe ? AppColors.cream : AppColors.barkBrown,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('h:mm a').format(message.sentAt),
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: AppColors.barkBrown.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// Date Divider

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
                color: AppColors.lemongrass.withOpacity(0.3), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: AppColors.oliveGreen.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(
                color: AppColors.lemongrass.withOpacity(0.3), height: 1),
          ),
        ],
      ),
    );
  }
}

// Input Bar

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top:
              BorderSide(color: AppColors.lightMoss.withOpacity(0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestDeep.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.lato(
                    fontSize: 14, color: AppColors.oliveGreen.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.lightMoss.withOpacity(0.4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppColors.lemongrass, width: 1.5),
                ),
              ),
              style: GoogleFonts.lato(fontSize: 14, color: AppColors.barkBrown),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sending
                    ? AppColors.lemongrass.withOpacity(0.5)
                    : AppColors.oliveGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.oliveGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: sending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.cream),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: AppColors.cream, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
