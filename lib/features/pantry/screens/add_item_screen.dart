// FILE LOCATION: lib/features/pantry/screens/add_item_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/pantry_provider.dart';
import '../../../core/models/pantry_item_model.dart';
import '../../../core/models/user_model.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../../auth/widgets/tag_chip_selector.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _addressCtrl = TextEditingController();

  File? _imageFile;
  String _category = kItemCategories.first;
  String _unit = 'pieces';
  DateTime? _expirationDate;
  List<String> _selectedDietary = [];
  double? _lat, _lng;
  bool _fetchingLocation = false;
  bool _loading = false;

  final List<String> _units = [
    'pieces',
    'kg',
    'g',
    'lbs',
    'cups',
    'liters',
    'ml',
    'packs',
    'boxes',
    'bags',
    'servings',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.oliveGreen,
            onSurface: AppColors.barkBrown,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _detectLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _lat = pos.latitude;
      _lng = pos.longitude;

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressCtrl.text =
            '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}'
                .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    setState(() => _fetchingLocation = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or select a photo of the item.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set an expiration date.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final pantry = context.read<PantryProvider>();
    final user = auth.userModel!;

    final id = await pantry.addItem(
      giverId: user.uid,
      giverName: user.displayName,
      giverPhotoUrl: user.photoUrl,
      giverVerified: user.isVerified,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      dietaryTags: _selectedDietary,
      imageFile: _imageFile!,
      quantity: double.tryParse(_quantityCtrl.text) ?? 1,
      unit: _unit,
      expirationDate: _expirationDate!,
      latitude: _lat,
      longitude: _lng,
      address:
          _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (id != null) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item posted to the pantry! 🌻'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pantry.error ?? 'Failed to post item.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSheet = Navigator.canPop(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: isSheet
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.zero,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isSheet ? null : AppBar(title: const Text('Share from Pantry')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                if (isSheet) _buildSheetHandle(),

                Text(
                  'Share from Your Pantry',
                  style: Theme.of(context).textTheme.displaySmall,
                ).animate().fadeIn(),
                const SizedBox(height: 4),
                Text(
                  'Give your extra food a good home',
                  style: GoogleFonts.lato(
                      color: AppColors.oliveGreen, fontSize: 13),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // Photo
                _buildPhotoSection().animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 20),

                // Title
                AuthTextField(
                  controller: _titleCtrl,
                  label: 'Item Name',
                  hint: 'e.g. Extra Eggs, Half a bag of rice',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Item name is required' : null,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Describe the condition, how much is left, any notes...',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Description is required' : null,
                ).animate().fadeIn(delay: 220.ms),

                const SizedBox(height: 14),

                // Category
                _buildCategoryDropdown().animate().fadeIn(delay: 240.ms),

                const SizedBox(height: 14),

                // Quantity + Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AuthTextField(
                        controller: _quantityCtrl,
                        label: 'Quantity',
                        hint: '1',
                        icon: Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildUnitDropdown(),
                    ),
                  ],
                ).animate().fadeIn(delay: 260.ms),

                const SizedBox(height: 14),

                // Expiration date
                _buildExpiryPicker().animate().fadeIn(delay: 280.ms),

                const SizedBox(height: 20),

                // Dietary tags
                Text(
                  '🌱 Dietary Tags (optional)',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep,
                      fontSize: 14),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 10),
                TagChipSelector(
                  tags: kDietaryTags,
                  selected: _selectedDietary,
                  onChanged: (tag, sel) => setState(() {
                    if (sel) {
                      _selectedDietary.add(tag);
                    } else {
                      _selectedDietary.remove(tag);
                    }
                  }),
                ).animate().fadeIn(delay: 320.ms),

                const SizedBox(height: 20),

                // Pickup location
                _buildLocationSection().animate().fadeIn(delay: 340.ms),

                const SizedBox(height: 28),

                // Submit
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.oliveGreen),
                      )
                    : ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.local_florist, size: 20),
                        label: const Text('Post to Pantry'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: AppColors.oliveGreen,
                        ),
                      ).animate().fadeIn(delay: 360.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lemongrass.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _imageFile != null
                ? AppColors.oliveGreen
                : AppColors.lemongrass.withOpacity(0.5),
            width: 2,
            style: _imageFile != null ? BorderStyle.solid : BorderStyle.solid,
          ),
          color: AppColors.lightMoss.withOpacity(0.3),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.forestDeep.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: AppColors.cream, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 40, color: AppColors.oliveGreen),
                  const SizedBox(height: 8),
                  Text(
                    'Take or upload a photo',
                    style: GoogleFonts.lato(
                        color: AppColors.oliveGreen,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Required — tap to add',
                    style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.oliveGreen.withOpacity(0.6)),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.oliveGreen),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.oliveGreen),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: kItemCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
      style: GoogleFonts.lato(color: AppColors.barkBrown, fontSize: 15),
      dropdownColor: AppColors.cream,
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _unit,
      decoration: const InputDecoration(
        labelText: 'Unit',
        prefixIcon: Icon(Icons.straighten_outlined),
      ),
      items: _units
          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
          .toList(),
      onChanged: (v) => setState(() => _unit = v!),
      style: GoogleFonts.lato(color: AppColors.barkBrown, fontSize: 15),
      dropdownColor: AppColors.cream,
    );
  }

  Widget _buildExpiryPicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightMoss.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expirationDate != null
                ? AppColors.oliveGreen
                : AppColors.lemongrass.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                color: AppColors.oliveGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _expirationDate != null
                    ? 'Expires: ${DateFormat('MMMM dd, yyyy').format(_expirationDate!)}'
                    : 'Set expiration date (required)',
                style: GoogleFonts.lato(
                  color: _expirationDate != null
                      ? AppColors.barkBrown
                      : AppColors.oliveGreen.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: _expirationDate != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.oliveGreen.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 Pickup Location (optional)',
          style: GoogleFonts.lato(
              fontWeight: FontWeight.w700,
              color: AppColors.forestDeep,
              fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter pickup address or area',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _fetchingLocation ? null : _detectLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lemongrass,
                  foregroundColor: AppColors.forestDeep,
                  padding: const EdgeInsets.all(14),
                  minimumSize: const Size(52, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _fetchingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.forestDeep),
                      )
                    : const Icon(Icons.my_location, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
