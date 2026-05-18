// FILE LOCATION: lib/features/verification/screens/verification_camera_screen.dart
//
// CHANGES FROM ORIGINAL:
//   • Added two-step liveness flow (neutral face → smile).
//   • Calls FaceVerificationService before uploading to Cloudinary.
//   • Shows animated status UI (pass / fail / instructions).
//   • Everything else (camera init, Cloudinary upload, AuthProvider update)
//     is identical to the original file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/face_verification_service.dart';

// ── Liveness steps ───────────────────────────────────────────────────────────
enum _LivenessStep {
  neutral, // Step 1: face the camera normally
  smile,   // Step 2: smile
  done,    // Both steps passed
}

class VerificationCameraScreen extends StatefulWidget {
  const VerificationCameraScreen({super.key});

  @override
  State<VerificationCameraScreen> createState() =>
      _VerificationCameraScreenState();
}

class _VerificationCameraScreenState extends State<VerificationCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _initialized = false;
  bool _capturing = false;
  File? _capturedImage; // used for step 1 selfie (uploaded at the end)
  bool _uploading = false;
  bool _error = false;
  String? _errorMessage;

  // ML Kit liveness state
  _LivenessStep _step = _LivenessStep.neutral;
  bool _verifying = false;
  String? _verifyMessage;
  bool _stepPassed = false; // true briefly between steps

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    FaceVerificationService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Camera init ─────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    setState(() {
      _initialized = false;
      _error = false;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = true;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      // Always use front camera for selfie verification.
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  // ── Capture + verify step ────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturing || _verifying) return;

    setState(() {
      _capturing = true;
      _verifyMessage = null;
    });

    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);

      setState(() {
        _capturing = false;
        _verifying = true;
        _verifyMessage = 'Analyzing…';
      });

      final result = await FaceVerificationService.instance.verifyFace(
        file,
        requireSmile: _step == _LivenessStep.smile,
      );

      if (!mounted) return;

      if (!result.passed) {
        // Step failed — show reason and let user retry.
        setState(() {
          _verifying = false;
          _verifyMessage = result.failReason;
          _stepPassed = false;
        });
        return;
      }

      // Step passed.
      if (_step == _LivenessStep.neutral) {
        // Save the neutral selfie for upload later.
        _capturedImage = file;

        setState(() {
          _verifying = false;
          _stepPassed = true;
          _verifyMessage = '✓ Face detected! Now smile for the camera 😊';
        });

        // Brief pause so user sees the success message, then advance.
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _step = _LivenessStep.smile;
          _stepPassed = false;
          _verifyMessage = null;
        });
      } else {
        // Both steps done — upload & mark verified.
        setState(() {
          _step = _LivenessStep.done;
          _verifying = false;
          _verifyMessage = '✓ Liveness confirmed! Uploading…';
        });
        await _uploadAndFinish();
      }
    } catch (e) {
      setState(() {
        _capturing = false;
        _verifying = false;
        _verifyMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  // ── Upload selfie to Cloudinary + update user profile ────────────────────

  Future<void> _uploadAndFinish() async {
    if (_capturedImage == null) return;
    setState(() => _uploading = true);

    try {
      final upload = await CloudinaryService.uploadImage(
        _capturedImage!,
        folder: 'pantryshare/verification',
      );

      if (upload == null) throw Exception('Upload returned null');

      final authProvider = context.read<AuthProvider>();
      final user = authProvider.userModel;
      if (user == null) throw Exception('User not found');

      final updated = user.copyWith(
        photoUrl: upload['url'],
        isVerified: true,
      );
      await authProvider.updateProfile(updated);

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() {
        _uploading = false;
        _step = _LivenessStep.neutral; // reset so user can retry
        _verifyMessage = 'Upload failed. Please try again.';
      });
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🌻 Verified!'),
        content: const Text(
          'Your identity has been verified. A verified badge will appear on your profile and listings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // go back to profile
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _error ? _buildError() : _buildCamera(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Camera unavailable.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera() {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      children: [
        // ── Step indicator ──────────────────────────────────────────────
        _StepIndicator(step: _step),

        // ── Camera preview ──────────────────────────────────────────────
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Preview fills available space
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),

              // Oval face guide overlay
              CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: _OvalOverlayPainter(
                  passed: _stepPassed,
                  color: _stepPassed
                      ? AppColors.oliveGreen
                      : Colors.white.withOpacity(0.7),
                ),
              ),

              // Status message
              if (_verifyMessage != null)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: _StatusBanner(
                    message: _verifyMessage!,
                    passed: _stepPassed,
                  ).animate().fadeIn(),
                ),

              // Uploading overlay
              if (_uploading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Uploading verification…',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Instruction + capture button ────────────────────────────────
        _BottomControls(
          step: _step,
          verifying: _verifying || _capturing || _uploading,
          onCapture: _capture,
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final _LivenessStep step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          _Dot(active: true, done: step != _LivenessStep.neutral, label: '1'),
          Expanded(
            child: Container(
              height: 2,
              color: step != _LivenessStep.neutral
                  ? AppColors.oliveGreen
                  : Colors.white24,
            ),
          ),
          _Dot(
            active: step != _LivenessStep.neutral,
            done: step == _LivenessStep.done,
            label: '2',
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;
  const _Dot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.oliveGreen
            : active
                ? Colors.white
                : Colors.white24,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.black : Colors.white54,
                ),
              ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool passed;
  const _StatusBanner({required this.message, required this.passed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: passed
            ? AppColors.oliveGreen.withOpacity(0.9)
            : Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final _LivenessStep step;
  final bool verifying;
  final VoidCallback onCapture;
  const _BottomControls({
    required this.step,
    required this.verifying,
    required this.onCapture,
  });

  String get _instruction {
    switch (step) {
      case _LivenessStep.neutral:
        return 'Look straight at the camera,\nthen tap the button.';
      case _LivenessStep.smile:
        return 'Great! Now give us a big smile 😊\nand tap the button.';
      case _LivenessStep.done:
        return 'All done!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          Text(
            _instruction,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: verifying ? null : onCapture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: verifying ? Colors.white24 : Colors.white,
                border: Border.all(color: Colors.white54, width: 3),
              ),
              child: verifying
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a semi-transparent overlay with a clear oval in the centre.
class _OvalOverlayPainter extends CustomPainter {
  final Color color;
  final bool passed;
  const _OvalOverlayPainter({required this.color, required this.passed});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.65,
      height: size.height * 0.45,
    );

    // Dark overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // Oval border
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) =>
      old.color != color || old.passed != passed;
}