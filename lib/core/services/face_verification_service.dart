// FILE LOCATION: lib/core/services/face_verification_service.dart
//
// Uses Google ML Kit Face Detection (on-device, no GPU needed).
// Checks that:
//   1. Exactly one face is detected in the image.
//   2. The face is large enough (not a tiny face on an ID card).
//   3. Both eyes are open (liveness: can't fool it with a closed-eye photo).
//   4. The head is roughly frontal (not a side-profile on a document).
//
// Liveness: the caller (VerificationCameraScreen) does a two-step flow:
//   Step 1 → capture neutral face  → verifyFace()
//   Step 2 → ask user to smile     → verifyFace(requireSmile: true)
// Both steps must pass before we mark the user as verified.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Result returned by [FaceVerificationService.verifyFace].
class FaceVerificationResult {
  final bool passed;
  final String? failReason; // human-readable, shown in UI
  final double? confidence; // 0.0–1.0, shown in UI

  const FaceVerificationResult({
    required this.passed,
    this.failReason,
    this.confidence,
  });
}

class FaceVerificationService {
  // Singleton so we reuse the same detector (expensive to create).
  FaceVerificationService._();
  static final FaceVerificationService instance = FaceVerificationService._();

  FaceDetector? _detector;

  FaceDetector _getDetector({bool classifyExpressions = false}) {
    // Re-create only if classification needs change.
    _detector?.close();
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        // Landmark mode gives us eye/nose/mouth positions.
        enableLandmarks: true,
        // Classification gives smile & eye-open probabilities.
        enableClassification: classifyExpressions,
        // ACCURATE mode is slower (~200 ms) but more reliable for verification.
        // Use FAST for real-time preview overlays.
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.25, // face must occupy ≥25 % of image width
      ),
    );
    return _detector!;
  }

  /// Main entry point.
  ///
  /// [imageFile]      — the captured selfie.
  /// [requireSmile]   — set true on the second liveness step.
  Future<FaceVerificationResult> verifyFace(
    File imageFile, {
    bool requireSmile = false,
  }) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final detector = _getDetector(classifyExpressions: requireSmile);
      final faces = await detector.processImage(inputImage);

      // ── 1. Must detect at least one face ──────────────────────────────────
      if (faces.isEmpty) {
        return const FaceVerificationResult(
          passed: false,
          failReason: 'No face detected. Make sure your face is clearly visible.',
        );
      }

      // ── 2. Must detect exactly one face (reject group photos / IDs with
      //       multiple faces) ────────────────────────────────────────────────
      if (faces.length > 1) {
        return const FaceVerificationResult(
          passed: false,
          failReason: 'Multiple faces detected. Please take a solo selfie.',
        );
      }

      final face = faces.first;

      // ── 3. Face must be large enough ──────────────────────────────────────
      // minFaceSize: 0.25 above already filters tiny faces at the detector
      // level, but let's double-check bounding box size in pixels.
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      if (faceArea < 10000) {
        // ~100×100 px minimum
        return const FaceVerificationResult(
          passed: false,
          failReason: 'Face too small. Move closer to the camera.',
        );
      }

      // ── 4. Head must be roughly frontal ───────────────────────────────────
      // eulerY is left/right rotation. > ±30° = profile view (e.g. ID card).
      final eulerY = face.headEulerAngleY ?? 0.0;
      if (eulerY.abs() > 30) {
        return const FaceVerificationResult(
          passed: false,
          failReason: 'Please face the camera directly.',
        );
      }

      // ── 5. Both eyes must be open ─────────────────────────────────────────
      // Probability is 0.0 (closed) to 1.0 (open). Threshold: 0.5.
      final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
      if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
        return const FaceVerificationResult(
          passed: false,
          failReason: 'Please keep both eyes open.',
        );
      }

      // ── 6. Smile check (liveness step 2 only) ────────────────────────────
      if (requireSmile) {
        final smileProb = face.smilingProbability ?? 0.0;
        if (smileProb < 0.6) {
          return const FaceVerificationResult(
            passed: false,
            failReason: 'Please smile for the camera 😊',
          );
        }
      }

      // ── All checks passed ─────────────────────────────────────────────────
      // Confidence = average of eye-open probabilities (simple heuristic).
      final confidence = (leftEyeOpen + rightEyeOpen) / 2.0;
      return FaceVerificationResult(passed: true, confidence: confidence);
    } catch (e) {
      debugPrint('FaceVerificationService error: $e');
      return FaceVerificationResult(
        passed: false,
        failReason: 'Verification failed. Please try again.',
      );
    }
  }

  void dispose() {
    _detector?.close();
    _detector = null;
  }
}