// FILE LOCATION: lib/features/verification/screens/verification_camera_screen.dart

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
  bool _frontCamera = true;
  bool _capturing = false;
  File? _capturedImage;
  bool _uploading = false;
  bool _error = false;
  String? _errorMessage;

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

      final camera = _frontCamera
          ? _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras!.first,
            )
          : _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras!.first,
            );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = 'Camera access failed: ${e.toString()}';
      });
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturing) return;

    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();

    try {
      final xFile = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(xFile.path);
        _capturing = false;
      });
    } catch (e) {
      setState(() => _capturing = false);
    }
  }

  void _retake() {
    setState(() => _capturedImage = null);
  }

  Future<void> _submit() async {
    if (_capturedImage == null) return;

    setState(() => _uploading = true);

    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user == null) return;

    final result = await CloudinaryService.uploadImage(
      _capturedImage!,
      folder: 'pantryshare/verifications',
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save selfie URL and mark user as verified
    final updated = user.copyWith(
      verificationSelfieUrl: result['url'],
      isVerified: true,
    );

    final ok = await auth.updateProfile(updated);

    if (!mounted) return;
    setState(() => _uploading = false);

    if (ok) {
      await HapticFeedback.heavyImpact();
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sunflowerGold.withOpacity(0.15),
                ),
                child: const Icon(Icons.verified,
                    color: AppColors.sunflowerGold, size: 52),
              ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),
              Text(
                'You\'re Verified!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestDeep,
                ),
              ).animate(delay: 200.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                'Your account is now verified. Other members can trust your listings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    color: AppColors.barkBrown, fontSize: 14, height: 1.5),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close camera screen
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.oliveGreen,
                ),
                child: const Text('Awesome!'),
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _flipCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    await _controller?.dispose();
    _controller = null;
    await _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Step: preview or captured
            _capturedImage != null ? _buildPreviewStep() : _buildCameraStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraStep() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text(
                'Verify Identity',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flip_camera_ios_outlined,
                    color: Colors.white),
                onPressed: _flipCamera,
              ),
            ],
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Take a clear selfie to verify your identity.\nYour photo will be stored securely.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
                color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Camera preview
        Expanded(
          child: _error
              ? _buildErrorState()
              : !_initialized
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.sunflowerGold),
                    )
                  : _buildCameraPreview(),
        ),

        // Shutter
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildShutterButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CameraPreview(_controller!),
            // Oval face guide
            CustomPaint(
              size: Size(
                MediaQuery.of(context).size.width - 40,
                (MediaQuery.of(context).size.width - 40) * 1.1,
              ),
              painter: _FaceGuidePainter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _capturing ? null : _capture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _capturing ? 70 : 76,
        height: _capturing ? 70 : 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _capturing
              ? AppColors.sunflowerGold.withOpacity(0.6)
              : AppColors.sunflowerGold,
          boxShadow: [
            BoxShadow(
              color: AppColors.sunflowerGold.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: _capturing
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
            : const Icon(Icons.camera_alt,
                color: AppColors.forestDeep, size: 32),
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _uploading ? null : _retake,
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.meadow, size: 18),
                label: Text('Retake',
                    style: GoogleFonts.lato(color: AppColors.meadow)),
              ),
              const Spacer(),
              Text(
                'Confirm Selfie',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 80),
            ],
          ),
        ),

        // Preview image
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _capturedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),

        // Confirmation text
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Looking good! Ready to verify.',
                    style:
                        GoogleFonts.lato(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _uploading
                  ? Column(
                      children: [
                        const LinearProgressIndicator(
                          color: AppColors.sunflowerGold,
                          backgroundColor: AppColors.oliveGreen,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Uploading verification selfie...',
                          style: GoogleFonts.lato(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.verified_outlined, size: 20),
                      label: const Text('Submit for Verification'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.oliveGreen,
                      ),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: AppColors.error, size: 52),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Camera error',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initCamera,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunflowerGold,
                  foregroundColor: AppColors.forestDeep),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Face guide painter

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.sunflowerGold.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width * 0.36;
    final ry = size.height * 0.42;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
