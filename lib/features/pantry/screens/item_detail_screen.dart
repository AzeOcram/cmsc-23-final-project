// FILE LOCATION: lib/features/pantry/screens/item_detail_screen.dart
// FIX: _openChat() no longer calls getConversation() after getOrCreateConversation().
//      getOrCreateConversation() now returns the full Conversation object directly,
//      so navigation can never silently fail due to a null return from a second read.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pantry_provider.dart';
import '../../../core/providers/messaging_provider.dart';
import '../../qr/screens/qr_generator_screen.dart';
import '../../qr/screens/qr_scanner_screen.dart';
import '../../messages/screens/chat_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final PantryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late PantryItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _refreshItem();
  }

  Future<void> _refreshItem() async {
    final fresh = await context.read<PantryProvider>().getItemById(_item.id);
    if (fresh != null && mounted) setState(() => _item = fresh);
  }

  /// Opens or creates a conversation, then navigates to ChatScreen.
  /// Uses the Conversation object returned directly — no second read.
  Future<void> _openChat(BuildContext context, String currentUid) async {
    final auth = context.read<AuthProvider>();
    final user = auth.userModel!;

    final conv =
        await context.read<MessagingProvider>().getOrCreateConversation(
              giverId: _item.giverId,
              giverName: _item.giverName,
              giverPhotoUrl: _item.giverPhotoUrl,
              claimerId: currentUid,
              claimerName: user.displayName,
              claimerPhotoUrl: user.photoUrl,
              itemId: _item.id,
              itemTitle: _item.title,
              itemPhotoUrl: _item.photoUrl,
            );

    if (conv == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open chat. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conv, currentUid: currentUid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    final isOwner = _item.giverId == uid;
    final isClaimer = _item.claimerId == uid;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.forestDeep,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _item.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.lightMoss,
                      child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.oliveGreen)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.lightMoss,
                      child: const Icon(Icons.broken_image_outlined,
                          size: 60, color: AppColors.lemongrass),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.forestDeep.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.forestDeep.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.cream, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(_item.title,
                                style: Theme.of(context).textTheme.displaySmall)
                            .animate()
                            .fadeIn(),
                      ),
                      const SizedBox(width: 10),
                      _StatusPill(status: _item.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lemongrass.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_item.category,
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            color: AppColors.oliveGreen,
                            fontWeight: FontWeight.w700)),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 14),
                  Text(_item.description,
                          style: GoogleFonts.lato(
                              fontSize: 15,
                              color: AppColors.barkBrown,
                              height: 1.5))
                      .animate()
                      .fadeIn(delay: 150.ms),
                  const SizedBox(height: 20),
                  _InfoGrid(item: _item).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),
                  if (_item.dietaryTags.isNotEmpty) ...[
                    Text('Dietary Tags',
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDeep,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _item.dietaryTags
                          .map((t) => Chip(
                                label: Text(t),
                                backgroundColor: AppColors.oliveGreen,
                                labelStyle: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppColors.cream,
                                    fontWeight: FontWeight.w600),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ))
                          .toList(),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 20),
                  ],
                  _GiverCard(item: _item).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                  if (_item.meetupTime != null &&
                      _item.status == ItemStatus.reserved)
                    _MeetupCard(item: _item, isClaimer: isClaimer)
                        .animate()
                        .fadeIn(delay: 350.ms),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: uid != null
          ? _buildBottomAction(context, uid, isOwner, isClaimer)
          : null,
    );
  }

  Widget _buildBottomAction(
      BuildContext context, String uid, bool isOwner, bool isClaimer) {
    if (isOwner) {
      return _OwnerActions(
          item: _item,
          onDeleted: () => Navigator.pop(context),
          onRefresh: _refreshItem);
    }
    if (isClaimer) {
      return _ClaimerActions(
          item: _item,
          onRefresh: _refreshItem,
          onMessage: () => _openChat(context, uid));
    }
    if (_item.isAvailable) {
      return _RequestButton(
        item: _item,
        userId: uid,
        userName: context.read<AuthProvider>().userModel?.displayName ?? '',
        onRequested: _refreshItem,
        onMessage: () => _openChat(context, uid),
      );
    }
    return const SizedBox.shrink();
  }
}

// Sub-widgets

class _StatusPill extends StatelessWidget {
  final ItemStatus status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case ItemStatus.reserved:
        bg = AppColors.sunflowerDeep;
        label = 'Reserved';
        break;
      case ItemStatus.completed:
        bg = AppColors.success;
        label = 'Completed';
        break;
      case ItemStatus.expired:
        bg = AppColors.error;
        label = 'Expired';
        break;
      default:
        bg = AppColors.oliveGreen;
        label = 'Available';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.lato(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final PantryItem item;
  const _InfoGrid({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightMoss.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lemongrass.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _InfoCell(
              icon: Icons.shopping_basket_outlined,
              label: 'Quantity',
              value:
                  '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}'),
          _vDivider(),
          _InfoCell(
              icon: Icons.event_outlined,
              label: 'Expires',
              value: DateFormat('MMM dd, yyyy').format(item.expirationDate),
              valueColor:
                  item.expirationDate.difference(DateTime.now()).inDays <= 2
                      ? AppColors.error
                      : null),
          _vDivider(),
          _InfoCell(
              icon: Icons.access_time_outlined,
              label: 'Posted',
              value: _timeAgo(item.postedAt)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1,
      height: 40,
      color: AppColors.lemongrass.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 12));

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoCell(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 20, color: AppColors.oliveGreen),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.lato(fontSize: 10, color: AppColors.oliveGreen)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.forestDeep),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _GiverCard extends StatelessWidget {
  final PantryItem item;
  const _GiverCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lemongrass.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AppColors.oliveGreen.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.lemongrass.withOpacity(0.3),
          backgroundImage: item.giverPhotoUrl != null
              ? CachedNetworkImageProvider(item.giverPhotoUrl!)
              : null,
          child: item.giverPhotoUrl == null
              ? Text(
                  item.giverName.isNotEmpty
                      ? item.giverName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(item.giverName,
                style: GoogleFonts.lato(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.forestDeep)),
            if (item.giverVerified)
              const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.verified,
                      color: AppColors.sunflowerGold, size: 16)),
          ]),
          Text('Sharing from pantry',
              style:
                  GoogleFonts.lato(fontSize: 12, color: AppColors.oliveGreen)),
        ])),
        if (item.address != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.oliveGreen),
            const SizedBox(height: 2),
            SizedBox(
                width: 90,
                child: Text(item.address!,
                    style: GoogleFonts.lato(
                        fontSize: 11, color: AppColors.oliveGreen),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
          ]),
      ]),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final PantryItem item;
  final bool isClaimer;
  const _MeetupCard({required this.item, required this.isClaimer});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sunflowerGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sunflowerGold.withOpacity(0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.event_available,
            color: AppColors.sunflowerDeep, size: 28),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Meetup Scheduled',
              style: GoogleFonts.lato(
                  fontWeight: FontWeight.w700, color: AppColors.barkBrown)),
          Text(DateFormat('EEE, MMM dd • h:mm a').format(item.meetupTime!),
              style:
                  GoogleFonts.lato(fontSize: 13, color: AppColors.barkBrown)),
          if (isClaimer)
            Text('Picking up from ${item.giverName}',
                style: GoogleFonts.lato(
                    fontSize: 12, color: AppColors.oliveGreen)),
        ])),
      ]),
    );
  }
}

// Action bars

class _RequestButton extends StatefulWidget {
  final PantryItem item;
  final String userId;
  final String userName;
  final VoidCallback onRequested;
  final VoidCallback onMessage;
  const _RequestButton(
      {required this.item,
      required this.userId,
      required this.userName,
      required this.onRequested,
      required this.onMessage});
  @override
  State<_RequestButton> createState() => _RequestButtonState();
}

class _RequestButtonState extends State<_RequestButton> {
  bool _loading = false;

  void _showMeetupPicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: widget.item.expirationDate,
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.oliveGreen,
                  onSurface: AppColors.barkBrown)),
          child: child!),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppColors.oliveGreen)),
          child: child!),
    );
    if (time == null || !mounted) return;
    final meetup =
        DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    setState(() => _loading = true);
    final ok = await context.read<PantryProvider>().requestItem(
        itemId: widget.item.id,
        claimerId: widget.userId,
        claimerName: widget.userName,
        meetupTime: meetup);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      widget.onRequested();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Request sent! Meetup scheduled.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: AppColors.forestDeep.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(children: [
        OutlinedButton.icon(
          onPressed: widget.onMessage,
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: const Text('Message'),
          style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _showMeetupPicker,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.oliveGreen),
            child: _loading
                ? const CircularProgressIndicator(color: AppColors.cream)
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.volunteer_activism,
                        color: AppColors.cream, size: 20),
                    const SizedBox(width: 8),
                    Text('Request Item',
                        style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream)),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _ClaimerActions extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onRefresh;
  final VoidCallback onMessage;
  const _ClaimerActions(
      {required this.item, required this.onRefresh, required this.onMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: AppColors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('You have requested this item',
            style: GoogleFonts.lato(
                color: AppColors.oliveGreen, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          OutlinedButton(
            onPressed: () async {
              final ok =
                  await context.read<PantryProvider>().cancelRequest(item.id);
              if (ok) onRefresh();
            },
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.chat_bubble_outline, size: 15),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                if (result == true) onRefresh();
              },
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan QR'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onDeleted;
  final VoidCallback onRefresh;
  const _OwnerActions(
      {required this.item, required this.onDeleted, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: AppColors.white,
      child: Row(children: [
        if (item.status == ItemStatus.reserved)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => QrGeneratorScreen(item: item)));
                onRefresh();
              },
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Generate QR'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunflowerGold,
                  foregroundColor: AppColors.forestDeep),
            ),
          )
        else
          Expanded(
              child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.people_outline, size: 18),
            label: Text(item.status == ItemStatus.available
                ? 'Waiting for requests'
                : 'Completed'),
          )),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => _confirmDelete(context),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              foregroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          child: const Icon(Icons.delete_outline),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item'),
        content: const Text('Remove this item from the pantry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await context.read<PantryProvider>().deleteItem(item.id);
    if (ok && context.mounted) onDeleted();
  }
}
