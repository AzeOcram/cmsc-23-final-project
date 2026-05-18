// FILE LOCATION: lib/features/messages/screens/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../../core/models/message_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final messaging = context.watch<MessagingProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          StreamBuilder<int>(
            stream: messaging.totalUnreadStream(uid),
            builder: (_, snap) {
              final count = snap.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sunflowerGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDeep,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: messaging.conversationsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.oliveGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load messages.',
                style: GoogleFonts.lato(color: AppColors.oliveGreen),
              ),
            );
          }

          final convs = snapshot.data ?? [];

          if (convs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 80,
              color: AppColors.lightMoss.withOpacity(0.6),
            ),
            itemBuilder: (_, i) => _ConversationTile(
              conv: convs[i],
              currentUid: uid,
            ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: AppColors.lemongrass)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.06, duration: 1400.ms),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Request an item to start chatting\nwith the giver.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: AppColors.oliveGreen,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Conversation Tile

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final String currentUid;

  const _ConversationTile({
    required this.conv,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    // Only show unread indicator for messages THIS user received
    final unread = conv.unreadCountFor(currentUid);
    final hasUnread = unread > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversation: conv,
              currentUid: currentUid,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _OtherAvatar(
              name: conv.otherName(currentUid),
              photoUrl: conv.otherPhotoUrl(currentUid),
              hasUnread: hasUnread,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherName(currentUid),
                          style: GoogleFonts.lato(
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.forestDeep,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageAt != null)
                        Text(
                          _formatTime(conv.lastMessageAt!),
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: hasUnread
                                ? AppColors.oliveGreen
                                : AppColors.barkBrown.withOpacity(0.5),
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 11, color: AppColors.lemongrass),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          conv.itemTitle,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.lemongrass,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: hasUnread
                                ? AppColors.barkBrown
                                : AppColors.barkBrown.withOpacity(0.55),
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.oliveGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: AppColors.cream,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

class _OtherAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool hasUnread;

  const _OtherAvatar({
    required this.name,
    this.photoUrl,
    required this.hasUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.lemongrass.withOpacity(0.3),
          backgroundImage:
              photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestDeep,
                  ),
                )
              : null,
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.oliveGreen,
                border: Border.all(color: AppColors.cream, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
