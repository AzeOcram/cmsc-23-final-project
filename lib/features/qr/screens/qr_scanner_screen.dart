// FILE LOCATION: lib/features/qr/screens/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/qr_service.dart';
import '../../../core/models/pantry_item_model.dart';
import 'qr_confirmation_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;

  // _handled prevents any second onDetect from firing during async work
  bool _handled = false;
  bool _processing = false;
  bool _failed = false;
  String? _failureMessage;

  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  // Camera scan handler

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    // Lock immediately and stop camera before any async work
    _handled = true;
    _controller?.stop();
    _processQrValue(barcode!.rawValue!);
  }

  // Gallery upload handler

  Future<void> _pickFromGallery() async {
    if (_handled) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    _handled = true;
    _controller?.stop();
    setState(() => _processing = true);

    final result = await _controller?.analyzeImage(picked.path);

    if (!mounted) return;

    if (result == null || result.barcodes.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _processing = false;
        _failed = true;
        _failureMessage =
            'No QR code found in the selected image.\nPlease choose a clearer photo.';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _handled = false;
      setState(() {
        _failed = false;
        _failureMessage = null;
      });
      await _controller?.start();
      return;
    }

    final rawValue = result.barcodes.first.rawValue;
    if (rawValue == null) {
      _handled = false;
      setState(() => _processing = false);
      await _controller?.start();
      return;
    }

    setState(() => _processing = false);
    await _processQrValue(rawValue);
  }

  // Shared processing logic

  Future<void> _processQrValue(String rawValue) async {
    if (!mounted) return;
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';

    // Validate — now returns PantryItem on success, null on failure
    final PantryItem? item = await QrService.validateQrPayload(
      rawPayload: rawValue,
      scannerId: uid,
    );

    if (!mounted) return;

    if (item == null) {
      // Invalid QR — show error and let user retry
      HapticFeedback.heavyImpact();
      setState(() {
        _processing = false;
        _failed = true;
        _failureMessage =
            'Invalid or expired QR code.\nMake sure the giver shows you the correct code.';
      });
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      _handled = false;
      setState(() {
        _failed = false;
        _failureMessage = null;
      });
      await _controller?.start();
      return;
    }

    // QR is valid — navigate to confirmation screen
    // Status is NOT updated yet — only on Finalize tap
    setState(() => _processing = false);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrConfirmationScreen(item: item),
      ),
    );

    // If confirmation screen returned true (Finalize was tapped and succeeded),
    // pop this scanner screen too and signal success to the caller
    if (result == true && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      // User cancelled on confirmation — unlock so they can try again
      _handled = false;
      await _controller?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),

          // Dark overlay with animated scan line
          _ScanOverlay(scanLineAnimation: _scanLineController),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Scan QR Code',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _controller?.toggleTorch(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flashlight_on_outlined,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom — instructions + upload button
          if (!_processing && !_failed)
            Positioned(
              bottom: 48,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point your camera at the giver\'s QR code\nor upload a saved QR image',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined,
                        size: 18, color: AppColors.forestDeep),
                    label: Text(
                      'Upload from Gallery',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDeep,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunflowerGold,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ).animate().fadeIn(),
                ],
              ),
            ),

          // Processing overlay
          if (_processing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.sunflowerGold),
                    const SizedBox(height: 20),
                    Text(
                      'Verifying QR code...',
                      style:
                          GoogleFonts.lato(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Failure overlay
          if (_failed)
            _FailureOverlay(message: _failureMessage ?? 'Invalid QR code'),
        ],
      ),
    );
  }
}

// Scan Overlay

class _ScanOverlay extends StatelessWidget {
  final AnimationController scanLineAnimation;
  const _ScanOverlay({required this.scanLineAnimation});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const cutout = 260.0;
    final cutoutTop = (size.height - cutout) / 2 - 60;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(cutoutSize: cutout, cutoutTop: cutoutTop),
        ),
        Positioned(
          left: (size.width - cutout) / 2,
          top: cutoutTop,
          child: SizedBox(
            width: cutout,
            height: cutout,
            child: AnimatedBuilder(
              animation: scanLineAnimation,
              builder: (_, __) {
                return Stack(
                  children: [
                    ..._buildCorners(cutout),
                    Positioned(
                      top: scanLineAnimation.value * (cutout - 4),
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.sunflowerGold,
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunflowerGold.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners(double size) {
    const cornerSize = 24.0;
    const thickness = 3.0;
    const color = AppColors.sunflowerGold;

    Widget corner({required bool top, required bool left}) => Positioned(
          top: top ? 0 : null,
          bottom: top ? null : 0,
          left: left ? 0 : null,
          right: left ? null : 0,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: _CornerPainter(
                  color: color, top: top, left: left, thickness: thickness),
            ),
          ),
        );

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }
}

class _OverlayPainter extends CustomPainter {
  final double cutoutSize;
  final double cutoutTop;
  _OverlayPainter({required this.cutoutSize, required this.cutoutTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  final double thickness;
  _CornerPainter(
      {required this.color,
      required this.top,
      required this.left,
      required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Failure overlay

class _FailureOverlay extends StatelessWidget {
  final String message;
  const _FailureOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.15),
              ),
              child: const Icon(Icons.close, color: AppColors.error, size: 60),
            ).animate().scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 20),
            Text(
              'Invalid QR Code',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Resuming scanner...',
              style: GoogleFonts.lato(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
