// FILE LOCATION: lib/features/auth/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/tag_chip_selector.dart';
import '../../../core/models/user_model.dart';
import '../../home/screens/main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  int _step = 0; // 0 = credentials, 1 = tags

  final List<String> _selectedDietary = [];
  final List<String> _selectedInterests = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      // Update tags
      final updated = auth.userModel!.copyWith(
        dietaryTags: _selectedDietary,
        interestTags: _selectedInterests,
      );
      await auth.updateProfile(updated);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.forestDeep, Color(0xFF3D5A20), AppColors.cream],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestDeep.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child:
                        _step == 0 ? _buildCredentialsStep() : _buildTagsStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.cream),
            onPressed: () {
              if (_step == 1) {
                setState(() => _step = 0);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const Spacer(),
          Text(
            'Elbigayan',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCredentialsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Join the Pantry',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 4),

          Text(
            'Create your community account',
            style: GoogleFonts.lato(color: AppColors.oliveGreen, fontSize: 14),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Step indicator
          _StepIndicator(currentStep: 0).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),

          AuthTextField(
            controller: _nameCtrl,
            label: 'Display Name',
            hint: 'Your name in the community',
            icon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Name is required';
              if (v.length < 2) return 'Name must be at least 2 characters';
              return null;
            },
          ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 14),

          AuthTextField(
            controller: _emailCtrl,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ).animate(delay: 350.ms).fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 14),

          AuthTextField(
            controller: _passCtrl,
            label: 'Password',
            hint: 'Min. 6 characters',
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.oliveGreen,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 14),

          AuthTextField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.oliveGreen,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ).animate(delay: 450.ms).fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() => _step = 1);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.oliveGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.cream,
                  size: 18,
                ),
              ],
            ),
          ).animate(delay: 500.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildTagsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Preferences',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(),
        const SizedBox(height: 4),
        Text(
          'Help us personalize your feed',
          style: GoogleFonts.lato(color: AppColors.oliveGreen, fontSize: 14),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        _StepIndicator(currentStep: 1).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 24),
        Text(
          '🌱 Dietary Preferences',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.forestDeep,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 10),
        TagChipSelector(
          tags: kDietaryTags,
          selected: _selectedDietary,
          onChanged: (tag, selected) {
            setState(() {
              if (selected) {
                _selectedDietary.add(tag);
              } else {
                _selectedDietary.remove(tag);
              }
            });
          },
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 20),
        Text(
          '🧺 Food Interests',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.forestDeep,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 10),
        TagChipSelector(
          tags: kInterestTags,
          selected: _selectedInterests,
          onChanged: (tag, selected) {
            setState(() {
              if (selected) {
                _selectedInterests.add(tag);
              } else {
                _selectedInterests.remove(tag);
              }
            });
          },
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 28),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.oliveGreen),
              )
            : ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunflowerGold,
                  foregroundColor: AppColors.forestDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDeep,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.local_florist,
                      color: AppColors.forestDeep,
                      size: 18,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: Text(
            'Skip for now',
            style: GoogleFonts.lato(
              color: AppColors.oliveGreen.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ).animate().fadeIn(delay: 450.ms),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 10,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? AppColors.oliveGreen
                : AppColors.lemongrass.withOpacity(0.4),
          ),
        );
      }),
    );
  }
}
