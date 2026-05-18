// FILE LOCATION: lib/features/qr/screens/qr_generator_screen.dart
// FIX: Replaced Spacer() widgets with fixed SizedBox heights and wrapped
//      the body in SingleChildScrollView to prevent bottom overflow.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/qr_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  final PantryItem item;
  const QrGeneratorScreen({super.key, required this.item});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen>
    with SingleTickerProviderStateMixin {
  String? _qrData;
  bool _loading = true;
  bool _error = false;
  bool _saving = false;
  late AnimationController _pulseController;

  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _generateToken();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateToken() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    final payload = await QrService.generateQrToken(
      itemId: widget.item.id,
      giverId: uid,
    );

    if (!mounted) return;

    if (payload == null) {
      setState(() {
        _error = true;
        _loading = false;
      });
    } else {
      setState(() {
        _qrData = payload;
        _loading = false;
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _saveToGallery() async {
    if (_qrData == null || _saving) return;
    setState(() => _saving = true);

    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null)
        throw Exception('Could not find QR render boundary.');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to convert to PNG.');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(
        pngBytes,
        name:
            'PantryShare_QR_${widget.item.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('QR code saved to your gallery! 📷'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save QR code: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(
        backgroundColor: AppColors.forestDeep,
        title: Text(
          'QR Handshake',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.cream,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.cream),
        elevation: 0,
      ),
      // SingleChildScrollView prevents overflow on small screens
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item info card
              _buildItemCard(),

              const SizedBox(height: 24),

              // QR code / loading / error
              if (_loading)
                _buildLoadingState()
              else if (_error)
                _buildErrorState()
              else
                _buildQrCode(),

              const SizedBox(height: 24),

              // Instructions
              _buildInstructions(),

              const SizedBox(height: 20),

              // Buttons — only shown when QR is ready
              if (!_loading && !_error) ...[
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveToGallery,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.forestDeep),
                        )
                      : const Icon(Icons.download_outlined,
                          size: 18, color: AppColors.forestDeep),
                  label: Text(
                    _saving ? 'Saving...' : 'Save to Gallery',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunflowerGold,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _generateToken,
                  icon: const Icon(Icons.refresh, color: AppColors.meadow),
                  label: Text(
                    'Regenerate QR',
                    style: GoogleFonts.lato(color: AppColors.meadow),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: AppColors.meadow.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lemongrass.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.sunflowerGold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.cream,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Claimed by ${widget.item.claimerName ?? "—"}',
                  style:
                      GoogleFonts.lato(color: AppColors.meadow, fontSize: 13),
                ),
                if (widget.item.meetupTime != null)
                  Text(
                    'Meetup: ${DateFormat('EEE MMM dd • h:mm a').format(widget.item.meetupTime!)}',
                    style: GoogleFonts.lato(
                        color: AppColors.sunflowerGold, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
                color: AppColors.sunflowerGold, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating secure QR code...',
            style: GoogleFonts.lato(color: AppColors.meadow, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 60),
          const SizedBox(height: 12),
          Text(
            'Failed to generate QR code',
            style: GoogleFonts.lato(
                color: AppColors.cream, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _generateToken,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunflowerGold,
                foregroundColor: AppColors.forestDeep),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    return Column(
      children: [
        // RepaintBoundary wraps the QR so we can capture it as an image
        Center(
          child: RepaintBoundary(
            key: _qrKey,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sunflowerGold
                            .withOpacity(0.15 + _pulseController.value * 0.25),
                        blurRadius: 20 + _pulseController.value * 20,
                        spreadRadius: 2 + _pulseController.value * 4,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: AppColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.forestDeep,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.forestDeep,
                ),
              ),
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.7, end: 1.3, duration: 800.ms),
            const SizedBox(width: 8),
            Text(
              'QR code is active',
              style: GoogleFonts.lato(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oliveGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lemongrass.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.sunflowerGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'How the QR Handshake works',
                style: GoogleFonts.lato(
                  color: AppColors.sunflowerGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _instructionRow(
              '1', 'Show this QR on screen — or save it to your gallery'),
          _instructionRow(
              '2', 'The receiver scans it using PantryShare at meetup'),
          _instructionRow('3', 'Exchange is marked as Completed automatically'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _instructionRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lemongrass.withOpacity(0.3),
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.meadow,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(color: AppColors.meadow, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
