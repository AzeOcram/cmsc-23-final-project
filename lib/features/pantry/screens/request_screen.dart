// FILE LOCATION: lib/features/pantry/screens/request_screen.dart
// REPLACES: Milestone 1 placeholder

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pantry_provider.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../home/widgets/pantry_item_card.dart';
import 'item_detail_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Browse & My Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.sunflowerGold,
          unselectedLabelColor: AppColors.meadow.withOpacity(0.7),
          indicatorColor: AppColors.sunflowerGold,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Browse All'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BrowseTab(uid: uid),
          _MyRequestsTab(uid: uid),
        ],
      ),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  final String uid;
  const _BrowseTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: pantry.setSearch,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: pantry.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => pantry.setSearch(''),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PantryItem>>(
            stream: pantry.feedStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.oliveGreen),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 60, color: AppColors.lemongrass),
                      const SizedBox(height: 12),
                      Text('No items available',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 18, color: AppColors.forestDeep)),
                      Text('Check back later!',
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
                      builder: (_) => ItemDetailScreen(item: items[i]),
                    ),
                  ),
                ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.06),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  final String uid;
  const _MyRequestsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();

    return StreamBuilder<List<PantryItem>>(
      stream: pantry.myRequestsStream(uid),
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
                Icon(Icons.volunteer_activism_outlined,
                    size: 60, color: AppColors.lemongrass),
                const SizedBox(height: 12),
                Text(
                  'No requests yet',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 18, color: AppColors.forestDeep),
                ),
                Text(
                  'Browse and request items from the pantry.',
                  style: GoogleFonts.lato(color: AppColors.oliveGreen),
                ),
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
                builder: (_) => ItemDetailScreen(item: items[i]),
              ),
            ),
          ).animate(delay: (i * 50).ms).fadeIn(),
        );
      },
    );
  }
}
