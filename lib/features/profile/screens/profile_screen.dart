// FILE LOCATION: lib/features/profile/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pantry_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../auth/widgets/tag_chip_selector.dart';
import '../../auth/screens/login_screen.dart';
import '../../pantry/screens/item_detail_screen.dart';
import '../../home/widgets/pantry_item_card.dart';
import '../../verification/screens/verification_camera_screen.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _editingTags = false;
  List<String> _tempDietary = [];
  List<String> _tempInterests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Now opens real camera verification screen
  void _startVerification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerificationCameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;
    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.oliveGreen));
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.forestDeep,
            flexibleSpace:
                FlexibleSpaceBar(background: _buildHeader(user, auth)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.cream),
                onPressed: () => _showEditProfileSheet(context, user, auth),
              ),
              IconButton(
                icon:
                    const Icon(Icons.settings_outlined, color: AppColors.cream),
                onPressed: () => _showSettingsSheet(context, user, auth),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.sunflowerGold,
              unselectedLabelColor: AppColors.meadow.withOpacity(0.7),
              indicatorColor: AppColors.sunflowerGold,
              indicatorWeight: 3,
              labelStyle:
                  GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'My Items'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProfileTab(
              user: user,
              auth: auth,
              editingTags: _editingTags,
              tempDietary: _tempDietary,
              tempInterests: _tempInterests,
              onStartEditTags: () => setState(() {
                _editingTags = true;
                _tempDietary = List.from(user.dietaryTags);
                _tempInterests = List.from(user.interestTags);
              }),
              onSaveTags: () => _saveTags(context, user, auth),
              onCancelEdit: () => setState(() => _editingTags = false),
              onTagChanged: (tag, sel, isDietary) => setState(() {
                final list = isDietary ? _tempDietary : _tempInterests;
                if (sel) {
                  list.add(tag);
                } else {
                  list.remove(tag);
                }
              }),
              onSignOut: () => _signOut(context, auth),
              onVerify: () => _startVerification(context),
            ),
            _MyItemsTab(uid: auth.firebaseUser?.uid ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestDeep, AppColors.oliveGreen],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickAndUploadAvatar(context, user, auth),
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.sunflowerGold, width: 3),
                        color: AppColors.lemongrass.withOpacity(0.3),
                      ),
                      child: user.photoUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sunflowerGold,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: AppColors.forestDeep),
                      ),
                    ),
                    if (user.isVerified)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.forestDeep,
                          ),
                          child: const Icon(Icons.verified,
                              color: AppColors.sunflowerGold, size: 18),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.displayName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
              Text(
                user.email,
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.meadow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(
      BuildContext context, UserModel user, AuthProvider auth) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading profile photo...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final result = await CloudinaryService.uploadImage(
      File(picked.path),
      folder: 'pantryshare/avatars',
    );

    if (result != null && mounted) {
      await auth.updateProfile(user.copyWith(photoUrl: result['url']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveTags(
      BuildContext context, UserModel user, AuthProvider auth) async {
    final updated = user.copyWith(
      dietaryTags: _tempDietary,
      interestTags: _tempInterests,
    );
    final ok = await auth.updateProfile(updated);
    if (!mounted) return;
    setState(() => _editingTags = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Preferences saved!' : 'Failed to save.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, UserModel user, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(user: user, auth: auth),
    );
  }

  void _showSettingsSheet(
      BuildContext context, UserModel user, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NotificationSettingsSheet(user: user, auth: auth),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }
}

// All sub-widgets below are identical to Milestone 2 — no changes needed.

class _ProfileTab extends StatelessWidget {
  final UserModel user;
  final AuthProvider auth;
  final bool editingTags;
  final List<String> tempDietary;
  final List<String> tempInterests;
  final VoidCallback onStartEditTags;
  final VoidCallback onSaveTags;
  final VoidCallback onCancelEdit;
  final void Function(String, bool, bool) onTagChanged;
  final VoidCallback onSignOut;
  final VoidCallback onVerify;

  const _ProfileTab({
    required this.user,
    required this.auth,
    required this.editingTags,
    required this.tempDietary,
    required this.tempInterests,
    required this.onStartEditTags,
    required this.onSaveTags,
    required this.onCancelEdit,
    required this.onTagChanged,
    required this.onSignOut,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: ProfileStatCard(
                    label: 'Given',
                    value: '${user.totalGiven}',
                    icon: Icons.volunteer_activism,
                    color: AppColors.oliveGreen)),
            const SizedBox(width: 12),
            Expanded(
                child: ProfileStatCard(
                    label: 'Received',
                    value: '${user.totalReceived}',
                    icon: Icons.inbox_outlined,
                    color: AppColors.sunflowerDeep)),
            const SizedBox(width: 12),
            Expanded(
                child: ProfileStatCard(
                    label: 'Badges',
                    value: '${user.badges.length}',
                    icon: Icons.military_tech_outlined,
                    color: AppColors.lemongrass)),
          ],
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        if (!user.isVerified)
          GestureDetector(
            onTap: onVerify,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.sunflowerGold, AppColors.sunflowerDeep]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt,
                      color: AppColors.forestDeep, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify Your Identity',
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestDeep)),
                        Text('Tap to take your verification selfie',
                            style: GoogleFonts.lato(
                                fontSize: 12,
                                color: AppColors.forestDeep.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.forestDeep, size: 14),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms),
        if (!user.isVerified) const SizedBox(height: 16),
        _TagSection(
                title: '🌱 Dietary Preferences',
                tags: editingTags ? tempDietary : user.dietaryTags,
                allTags: kDietaryTags,
                editing: editingTags,
                onChanged: (t, s) => onTagChanged(t, s, true))
            .animate()
            .fadeIn(delay: 200.ms),
        const SizedBox(height: 14),
        _TagSection(
                title: '🧺 Food Interests',
                tags: editingTags ? tempInterests : user.interestTags,
                allTags: kInterestTags,
                editing: editingTags,
                onChanged: (t, s) => onTagChanged(t, s, false))
            .animate()
            .fadeIn(delay: 240.ms),
        const SizedBox(height: 14),
        editingTags
            ? Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: onCancelEdit, child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: onSaveTags, child: const Text('Save'))),
              ])
            : OutlinedButton.icon(
                onPressed: onStartEditTags,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Preferences')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout, color: AppColors.error, size: 16),
          label:
              Text('Sign Out', style: GoogleFonts.lato(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error)),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TagSection extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String> allTags;
  final bool editing;
  final void Function(String, bool) onChanged;

  const _TagSection({
    required this.title,
    required this.tags,
    required this.allTags,
    required this.editing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.lato(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.forestDeep)),
        const SizedBox(height: 8),
        editing
            ? TagChipSelector(
                tags: allTags, selected: tags, onChanged: onChanged)
            : tags.isEmpty
                ? Text('None set — tap Edit to add',
                    style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppColors.oliveGreen.withOpacity(0.7),
                        fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags
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
                        .toList()),
      ],
    );
  }
}

class _MyItemsTab extends StatelessWidget {
  final String uid;
  const _MyItemsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    return StreamBuilder<List<PantryItem>>(
      stream: pantry.myItemsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.oliveGreen));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_florist_outlined,
                    size: 60, color: AppColors.lemongrass),
                const SizedBox(height: 12),
                Text('Nothing posted yet',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18, color: AppColors.forestDeep)),
                Text('Share your first item using the + button',
                    style: GoogleFonts.lato(color: AppColors.oliveGreen)),
              ],
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: items.length,
          itemBuilder: (_, i) => PantryItemCard(
            item: items[i],
            currentUserId: uid,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(item: items[i])),
            ),
          ).animate(delay: (i * 50).ms).fadeIn(),
        );
      },
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final AuthProvider auth;
  const _EditProfileSheet({required this.user, required this.auth});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lemongrass.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.oliveGreen))
              : ElevatedButton(
                  onPressed: () async {
                    if (_nameCtrl.text.trim().isEmpty) return;
                    setState(() => _loading = true);
                    final ok = await widget.auth.updateProfile(widget.user
                        .copyWith(displayName: _nameCtrl.text.trim()));
                    if (mounted) {
                      setState(() => _loading = false);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(ok ? 'Profile updated!' : 'Failed to update.'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Save Changes'),
                ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  final UserModel user;
  final AuthProvider auth;
  const _NotificationSettingsSheet({required this.user, required this.auth});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late bool _notifNewItems;
  late bool _notifPickup;
  late bool _notifMessages;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _notifNewItems = widget.user.notifNewItems;
    _notifPickup = widget.user.notifPickupReminders;
    _notifMessages = widget.user.notifMessages;
    _radius = widget.user.discoveryRadiusKm;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.lemongrass.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SettingsTile(
              title: 'New items nearby',
              subtitle: 'Alert when matching items are posted',
              value: _notifNewItems,
              onChanged: (v) => setState(() => _notifNewItems = v)),
          SettingsTile(
              title: 'Pick-up reminders',
              subtitle: 'Notify 1 hour before meetup time',
              value: _notifPickup,
              onChanged: (v) => setState(() => _notifPickup = v)),
          SettingsTile(
              title: 'Messages',
              subtitle: 'New message notifications',
              value: _notifMessages,
              onChanged: (v) => setState(() => _notifMessages = v)),
          const SizedBox(height: 8),
          Text('Discovery Radius: ${_radius.toStringAsFixed(0)} km',
              style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600, color: AppColors.forestDeep)),
          Slider(
              value: _radius,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: AppColors.oliveGreen,
              inactiveColor: AppColors.lightMoss,
              onChanged: (v) => setState(() => _radius = v)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await widget.auth.updateProfile(widget.user.copyWith(
                notifNewItems: _notifNewItems,
                notifPickupReminders: _notifPickup,
                notifMessages: _notifMessages,
                discoveryRadiusKm: _radius,
              ));
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
