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
import '../../../core/services/food_classifier_service.dart';
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
  final List<String> _selectedDietary = [];
  double? _lat, _lng;
  bool _fetchingLocation = false;
  bool _loading = false;

  // Food classification state
  bool _classifying = false;
  FoodClassificationResult? _classificationResult;

  final List<String> _units = [
    'pieces', 'kg', 'g', 'lbs', 'cups',
    'liters', 'ml', 'packs', 'boxes', 'bags', 'servings',
  ];

  static const _kDietaryTags = [
    'Vegan', 'Vegetarian', 'Gluten-Free', 'Dairy-Free',
    'Nut-Free', 'Halal', 'Kosher', 'Low-Sugar',
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
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _imageFile = file;
      _classifying = true;
      _classificationResult = null;
    });

    final result = await FoodClassifierService.instance.classify(file);
    if (!mounted) return;
    setState(() {
      _classifying = false;
      _classificationResult = result;
    });
    if (result.hasResult) _applyClassification(result);
  }

  void _applyClassification(FoodClassificationResult result) {
    setState(() {
      if (result.category != null && kItemCategories.contains(result.category)) {
        _category = result.category!;
      }
      // Merge both confident + uncertain tags into selected list
      for (final tag in [...result.dietaryTags, ...result.uncertainTags]) {
        if (!_selectedDietary.contains(tag)) _selectedDietary.add(tag);
      }
      // Auto-fill title only if user has not typed anything yet.
      if (_titleCtrl.text.trim().isEmpty && result.suggestedTitle != null) {
        _titleCtrl.text = result.suggestedTitle!;
      }
    });
  }

  void _dismissClassification() => setState(() => _classificationResult = null);

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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _fetchingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressCtrl.text =
            '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}'.trim();
      }
    } catch (_) {
      // Non-fatal
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) { _showSnack('Please add a photo of the item.'); return; }
    if (_expirationDate == null) { _showSnack('Please set an expiration date.'); return; }

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
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);
    if (id != null) {
      Navigator.pop(context);
      _showSnack('Item posted successfully! 🌻');
    } else {
      _showSnack(pantry.error ?? 'Failed to post item.');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share an Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.oliveGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            if (_classifying) _buildClassifyingBanner(),
            if (!_classifying && _classificationResult != null)
              _buildClassificationBanner(_classificationResult!),
            const SizedBox(height: 16),

            // Title
            AuthTextField(
              controller: _titleCtrl,
              label: 'Item Name',
              hint: 'e.g. Fresh Tomatoes',
              icon: Icons.label_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Description — plain TextFormField (AuthTextField has no maxLines)
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Condition, quantity notes, pickup instructions…',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),

            _buildCategoryDropdown(),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AuthTextField(
                    controller: _quantityCtrl,
                    label: 'Quantity',
                    hint: '1',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildUnitDropdown()),
              ],
            ),
            const SizedBox(height: 12),

            _buildDatePicker(),
            const SizedBox(height: 12),

            Text('Dietary Tags', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            // TagChipSelector uses onChanged(String tag, bool selected)
            TagChipSelector(
              tags: _kDietaryTags,
              selected: _selectedDietary,
              onChanged: (tag, isSelected) {
                setState(() {
                  isSelected
                      ? _selectedDietary.add(tag)
                      : _selectedDietary.remove(tag);
                });
              },
            ),
            const SizedBox(height: 12),

            _buildLocationRow(),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.oliveGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Post Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Tap to add a photo', style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassifyingBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.oliveGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.oliveGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.oliveGreen),
          ),
          const SizedBox(width: 10),
          Text('Identifying food…',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.oliveGreen)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildClassificationBanner(FoodClassificationResult result) {
    // Case 1: could not identify food
    if (!result.hasResult) {
      if (result.failReason == null) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.failReason!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: _dismissClassification,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    // Case 2: food identified
    final pct = (result.confidence * 100).toStringAsFixed(0);
    final hasUncertain = result.uncertainTags.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.oliveGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.oliveGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome, size: 18, color: AppColors.oliveGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected: ${result.suggestedTitle ?? result.category} ($pct%)',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.oliveGreen,
                      fontWeight: FontWeight.w600),
                ),
                if (result.dietaryTags.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tags: ${result.dietaryTags.join(", ")}',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
                if (hasUncertain) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12, color: Colors.orange.shade600),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Uncertain: ${result.uncertainTags.join(", ")} — please verify',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Category, title & tags auto-filled. Please verify before posting.',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _dismissClassification,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: kItemCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _unit,
      decoration: InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => setState(() => _unit = v!),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Expiration Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(
          _expirationDate != null
              ? DateFormat('MMM d, yyyy').format(_expirationDate!)
              : 'Select date',
          style: GoogleFonts.poppins(
            color: _expirationDate != null ? Colors.black : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Expanded(
          child: AuthTextField(
            controller: _addressCtrl,
            label: 'Pickup Address (optional)',
            hint: 'Street, City',
            icon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _fetchingLocation ? null : _detectLocation,
          icon: _fetchingLocation
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, color: AppColors.oliveGreen),
          tooltip: 'Detect my location',
        ),
      ],
    );
  }
}