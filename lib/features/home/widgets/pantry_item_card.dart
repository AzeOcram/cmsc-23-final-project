// FILE LOCATION: lib/features/home/widgets/pantry_item_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/pantry_item_model.dart';

class PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final String? currentUserId;
  final VoidCallback onTap;

  const PantryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.expirationDate.difference(DateTime.now()).inDays;
    final isOwner = item.giverId == currentUserId;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.oliveGreen.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: item.photoUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 180,
                      color: AppColors.lightMoss,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.lemongrass, size: 40),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.lightMoss,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.lemongrass, size: 40),
                      ),
                    ),
                  ),
                ),
                // Status badge
                if (item.status != ItemStatus.available)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusBadge(status: item.status),
                  ),
                // Expiry badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: _ExpiryBadge(daysLeft: daysLeft),
                ),
                // Own item badge
                if (isOwner)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.forestDeep.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Your item',
                        style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.cream,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDeep,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lemongrass.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.oliveGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Description
                  Text(
                    item.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.barkBrown.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Quantity + Dietary tags
                  Row(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 14, color: AppColors.oliveGreen),
                      const SizedBox(width: 4),
                      Text(
                        '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.oliveGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...item.dietaryTags.take(2).map(
                            (t) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.sunflowerGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t,
                                style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: AppColors.barkBrown,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      if (item.dietaryTags.length > 2)
                        Text(
                          '+${item.dietaryTags.length - 2}',
                          style: GoogleFonts.lato(
                              fontSize: 10, color: AppColors.oliveGreen),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Divider(height: 1, color: AppColors.lightMoss),

                  const SizedBox(height: 10),

                  // Giver info + location
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forestDeep),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              item.giverName,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.barkBrown,
                              ),
                            ),
                            if (item.giverVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 3),
                                child: Icon(Icons.verified,
                                    color: AppColors.sunflowerGold, size: 13),
                              ),
                          ],
                        ),
                      ),
                      if (item.address != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.oliveGreen),
                            const SizedBox(width: 2),
                            Text(
                              item.address!.length > 20
                                  ? '${item.address!.substring(0, 20)}...'
                                  : item.address!,
                              style: GoogleFonts.lato(
                                  fontSize: 11, color: AppColors.oliveGreen),
                            ),
                          ],
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
}

class _StatusBadge extends StatelessWidget {
  final ItemStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ItemStatus.reserved:
        color = AppColors.sunflowerDeep;
        label = 'Reserved';
        break;
      case ItemStatus.completed:
        color = AppColors.success;
        label = 'Completed';
        break;
      default:
        color = AppColors.oliveGreen;
        label = 'Available';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
            fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final int daysLeft;
  const _ExpiryBadge({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final urgent = daysLeft <= 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent
            ? AppColors.error.withOpacity(0.9)
            : AppColors.forestDeep.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            urgent ? Icons.warning_amber_rounded : Icons.access_time,
            size: 11,
            color: AppColors.white,
          ),
          const SizedBox(width: 3),
          Text(
            daysLeft <= 0
                ? 'Expires today'
                : daysLeft == 1
                    ? '1 day left'
                    : '$daysLeft days left',
            style: GoogleFonts.lato(
                fontSize: 10,
                color: AppColors.white,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
