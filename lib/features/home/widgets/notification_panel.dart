// FILE LOCATION: lib/features/home/widgets/notification_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/models/notification_model.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    if (!notifProvider.panelOpen) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        // Tapping outside the panel (the dark area) closes it
        onTap: notifProvider.closePanel,
        child: Container(
          color: Colors.transparent,
          // Full screen height so the tap-outside works
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              // The actual panel — stop tap propagation
              GestureDetector(
                onTap: () {}, // absorb taps so they don't close the panel
                child: Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestDeep.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PanelHeader(uid: uid),
                      Flexible(
                        child: _NotificationList(uid: uid),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(
                      begin: -0.3,
                      end: 0,
                      duration: 280.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 200.ms),
              ),
              // The rest is the dark backdrop — tapping it closes the panel
              Expanded(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel header ─────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final String uid;
  const _PanelHeader({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              color: AppColors.forestDeep, size: 22),
          const SizedBox(width: 8),
          Text(
            'Notifications',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.forestDeep,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () =>
                context.read<NotificationProvider>().markAllRead(uid),
            child: Text(
              'Mark all read',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.oliveGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification list ────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final String uid;
  const _NotificationList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: context.read<NotificationProvider>().notificationsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.oliveGreen),
            ),
          );
        }

        final notifs = snapshot.data ?? [];

        if (notifs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none,
                    size: 48, color: AppColors.lemongrass.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(
                  'You\'re all caught up!',
                  style: GoogleFonts.lato(
                    color: AppColors.oliveGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: notifs.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            indent: 64,
            color: AppColors.lightMoss.withOpacity(0.6),
          ),
          itemBuilder: (_, i) => _NotificationTile(
            notif: notifs[i],
          ).animate(delay: (i * 30).ms).fadeIn(),
        );
      },
    );
  }
}

// ─── Single notification tile ─────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  const _NotificationTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notif.read;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withOpacity(0.1),
        child:
            const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
      ),
      onDismissed: (_) =>
          context.read<NotificationProvider>().deleteNotification(notif.id),
      child: InkWell(
        onTap: () {
          context.read<NotificationProvider>().markOneRead(notif.id);
          // Future: navigate to item or conversation
        },
        child: Container(
          color: isUnread
              ? AppColors.lemongrass.withOpacity(0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Avatar
              _NotifAvatar(notif: notif),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.forestDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notif.createdAt),
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: AppColors.barkBrown.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.barkBrown
                            .withOpacity(isUnread ? 0.85 : 0.6),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.oliveGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

class _NotifAvatar extends StatelessWidget {
  final AppNotification notif;
  const _NotifAvatar({required this.notif});

  @override
  Widget build(BuildContext context) {
    if (notif.type == NotificationType.newMessage &&
        notif.senderPhotoUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(notif.senderPhotoUrl!),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: notif.type == NotificationType.newMessage
          ? AppColors.oliveGreen.withOpacity(0.15)
          : AppColors.sunflowerGold.withOpacity(0.15),
      child: Icon(
        notif.type == NotificationType.newMessage
            ? Icons.chat_bubble_outline
            : Icons.local_florist_outlined,
        color: notif.type == NotificationType.newMessage
            ? AppColors.oliveGreen
            : AppColors.sunflowerDeep,
        size: 20,
      ),
    );
  }
}
