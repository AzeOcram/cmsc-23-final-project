// FILE LOCATION: lib/features/home/screens/home_screen.dart
// CHANGE: Bell button now toggles NotificationPanel open/closed.
//         Bell shows a red unread badge when there are unread notifications.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pantry_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/models/pantry_item_model.dart';
import '../widgets/feed_filter_bar.dart';
import '../widgets/pantry_item_card.dart';
import '../widgets/notification_panel.dart';
import '../../pantry/screens/item_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pantry = context.watch<PantryProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final uid = auth.firebaseUser?.uid ?? '';
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.forestDeep,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(
                    user?.displayName ?? 'Friend',
                    user?.isVerified ?? false,
                  ),
                  // title: Text(
                  //   'PantryShare',
                  //   style: GoogleFonts.playfairDisplay(
                  //     color: AppColors.cream,
                  //     fontWeight: FontWeight.w700,
                  //     fontSize: 18,
                  //   ),
                  // ),
                  // centerTitle: true,
                ),
                actions: [
                  // Bell button with unread badge
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StreamBuilder<int>(
                      stream: context
                          .read<NotificationProvider>()
                          .unreadCountStream(uid),
                      builder: (_, snap) {
                        final count = snap.data ?? 0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  notifProvider.panelOpen
                                      ? Icons.notifications
                                      : Icons.notifications_outlined,
                                  key: ValueKey(notifProvider.panelOpen),
                                  color: notifProvider.panelOpen
                                      ? AppColors.sunflowerGold
                                      : AppColors.cream,
                                ),
                              ),
                              onPressed: notifProvider.togglePanel,
                            ),
                            if (count > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: GoogleFonts.lato(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: TextField(
                    onChanged: pantry.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Search the pantry...',
                      prefixIcon: const Icon(Icons.search_outlined),
                      suffixIcon: pantry.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => pantry.setSearch(''),
                            )
                          : null,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                ),
              ),

              // Filter bar
              SliverToBoxAdapter(
                child: FeedFilterBar(
                  selectedCategories: pantry.selectedCategories,
                  selectedDietary: pantry.selectedDietary,
                  sortBy: pantry.sortBy,
                  onCategoryToggle: pantry.toggleCategory,
                  onDietaryToggle: pantry.toggleDietary,
                  onSortChanged: pantry.setSortBy,
                  onClearAll: pantry.clearFilters,
                ).animate().fadeIn(delay: 150.ms),
              ),

              // Feed
              StreamBuilder<List<PantryItem>>(
                stream: pantry.feedStream(interestTags: user?.interestTags),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.oliveGreen),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Something went wrong.\nPlease try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(color: AppColors.oliveGreen),
                        ),
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => PantryItemCard(
                          item: items[i],
                          currentUserId: uid,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: items[i]),
                            ),
                          ),
                        )
                            .animate(delay: (i * 60).ms)
                            .fadeIn()
                            .slideY(begin: 0.08),
                        childCount: items.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // Notification panel overlay
          // Rendered on top of everything so it slides over the feed
          const NotificationPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, bool verified) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestDeep, AppColors.oliveGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 0,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(Icons.eco, size: 160, color: AppColors.meadow),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style:
                      GoogleFonts.lato(color: AppColors.meadow, fontSize: 13),
                ),
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.cream,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (verified)
                  Row(
                    children: [
                      const Icon(Icons.verified,
                          color: AppColors.sunflowerGold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Member',
                        style: GoogleFonts.lato(
                            color: AppColors.sunflowerGold, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_florist, size: 72, color: AppColors.lemongrass)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.08,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 16),
          Text(
            'The pantry is empty!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.forestDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something.',
            style: GoogleFonts.lato(fontSize: 14, color: AppColors.oliveGreen),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
