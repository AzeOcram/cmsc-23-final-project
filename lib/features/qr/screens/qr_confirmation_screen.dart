// FILE LOCATION: lib/features/qr/screens/qr_confirmation_screen.dart
// NEW FILE: Shown after a successful QR scan/upload.
// Displays a summary of the item and lets the receiver tap "Finalize"
// to complete the exchange. Status is only updated on that tap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/services/qr_service.dart';

class QrConfirmationScreen extends StatefulWidget {
  final PantryItem item;

  const QrConfirmationScreen({super.key, required this.item});

  @override
  State<QrConfirmationScreen> createState() => _QrConfirmationScreenState();
}

class _QrConfirmationScreenState extends State<QrConfirmationScreen> {
  bool _finalizing = false;
  bool _completed = false;

  Future<void> _finalize() async {
    if (_finalizing) return;
    setState(() => _finalizing = true);
    HapticFeedback.mediumImpact();

    final success = await QrService.completeExchange(itemId: widget.item.id);

    if (!mounted) return;

    if (!success) {
      setState(() => _finalizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete exchange. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _completed = true;
      _finalizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _completed ? _buildSuccessView() : _buildConfirmationView(),
    );
  }

  // Confirmation view

  Widget _buildConfirmationView() {
    final item = widget.item;
    final daysLeft = item.expirationDate.difference(DateTime.now()).inDays;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.forestDeep, AppColors.oliveGreen],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: AppColors.cream, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confirm Exchange',
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.cream,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.sunflowerGold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'QR code verified successfully',
                      style: GoogleFonts.lato(
                        color: AppColors.sunflowerGold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Item details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: item.photoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppColors.lightMoss,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.oliveGreen),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppColors.lightMoss,
                        child: const Icon(Icons.broken_image_outlined,
                            size: 50, color: AppColors.lemongrass),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

                  const SizedBox(height: 16),

                  // Item name + category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDeep,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lemongrass.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.category,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: AppColors.oliveGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 150.ms).fadeIn(),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    item.description,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.barkBrown.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ).animate(delay: 180.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // Info grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightMoss.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.lemongrass.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _InfoCell(
                          icon: Icons.shopping_basket_outlined,
                          label: 'Quantity',
                          value:
                              '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                        ),
                        _divider(),
                        _InfoCell(
                          icon: Icons.event_outlined,
                          label: 'Expires',
                          value: DateFormat('MMM dd, yyyy')
                              .format(item.expirationDate),
                          valueColor: daysLeft <= 2 ? AppColors.error : null,
                        ),
                        _divider(),
                        _InfoCell(
                          icon: Icons.person_outline,
                          label: 'From',
                          value: item.giverName,
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 16),

                  // Dietary tags
                  if (item.dietaryTags.isNotEmpty) ...[
                    Text(
                      'Dietary Tags',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDeep,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.dietaryTags
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
                    ).animate(delay: 220.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  // Meetup time if set
                  if (item.meetupTime != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sunflowerGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.sunflowerGold.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available,
                              color: AppColors.sunflowerDeep, size: 24),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Meetup',
                                style: GoogleFonts.lato(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.barkBrown,
                                    fontSize: 13),
                              ),
                              Text(
                                DateFormat('EEE, MMM dd • h:mm a')
                                    .format(item.meetupTime!),
                                style: GoogleFonts.lato(
                                    fontSize: 13, color: AppColors.barkBrown),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 240.ms).fadeIn(),
                    const SizedBox(height: 16),
                  ],

                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.oliveGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.oliveGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.oliveGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tapping "Finalize Exchange" confirms that you have physically received this item. This cannot be undone.',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.oliveGreen,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 260.ms).fadeIn(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestDeep.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Finalize button
                ElevatedButton.icon(
                  onPressed: _finalizing ? null : _finalize,
                  icon: _finalizing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream),
                        )
                      : const Icon(Icons.handshake_outlined,
                          size: 20, color: AppColors.cream),
                  label: Text(
                    _finalizing
                        ? 'Completing exchange...'
                        : 'Finalize Exchange',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oliveGreen,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 10),

                // Cancel button
                OutlinedButton(
                  onPressed: _finalizing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side:
                        BorderSide(color: AppColors.barkBrown.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Cancel — Go Back to Scanner',
                    style: GoogleFonts.lato(
                      color: AppColors.barkBrown.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Success view

  Widget _buildSuccessView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestDeep, AppColors.oliveGreen],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sunflowerGold.withOpacity(0.2),
                    border:
                        Border.all(color: AppColors.sunflowerGold, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.sunflowerGold, size: 72),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(),
                const SizedBox(height: 28),
                Text(
                  'Exchange Complete!',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.cream,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 10),
                Text(
                  '"${widget.item.title}" has been\nsuccessfully exchanged 🌻',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: AppColors.meadow,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ).animate(delay: 400.ms).fadeIn(),
                const SizedBox(height: 12),
                Text(
                  'Thank you for using PantryShare!',
                  style: GoogleFonts.lato(
                    color: AppColors.lemongrass.withOpacity(0.7),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ).animate(delay: 500.ms).fadeIn(),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Pop both this screen and the scanner screen
                    Navigator.of(context)
                      ..pop(true) // pop confirmation
                      ..pop(true); // pop scanner
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunflowerGold,
                    foregroundColor: AppColors.forestDeep,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Back to Feed',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppColors.lemongrass.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.oliveGreen),
          const SizedBox(height: 4),
          Text(label,
              style:
                  GoogleFonts.lato(fontSize: 10, color: AppColors.oliveGreen)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.forestDeep,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
