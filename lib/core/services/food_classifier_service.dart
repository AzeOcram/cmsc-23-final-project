// FILE LOCATION: lib/core/services/food_classifier_service.dart
//
// Uses Google ML Kit Image Labeling (MobileNetV2 / ImageNet-1K).
// Exhaustive keyword mapping covers every food-related ImageNet label.
//
// Strategy:
//   1. Run ML Kit → get labels with confidence scores
//   2. Match labels against exhaustive keyword tables → category + title
//   3. Dietary tags only added on POSITIVE evidence, never by elimination
//   4. Uncertain tags get flagged (uncertainTags) → shown with ⚠ in UI
//   5. If no food label found → hasResult=false, reason='Could not identify food'

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../models/pantry_item_model.dart';
import '../models/user_model.dart';

// ── Result ────────────────────────────────────────────────────────────────────

class FoodClassificationResult {
  final String? category;
  final String? suggestedTitle;
  final List<String> dietaryTags;      // confident tags
  final List<String> uncertainTags;    // shown with ⚠ warning
  final double confidence;
  final bool hasResult;
  final String? failReason;            // 'Could not identify food' etc.

  const FoodClassificationResult({
    required this.category,
    required this.suggestedTitle,
    required this.dietaryTags,
    required this.uncertainTags,
    required this.confidence,
    required this.hasResult,
    this.failReason,
  });

  static const empty = FoodClassificationResult(
    category: null,
    suggestedTitle: null,
    dietaryTags: [],
    uncertainTags: [],
    confidence: 0,
    hasResult: false,
  );

  static FoodClassificationResult notFood() => const FoodClassificationResult(
    category: null,
    suggestedTitle: null,
    dietaryTags: [],
    uncertainTags: [],
    confidence: 0,
    hasResult: false,
    failReason: 'Could not identify food in this photo.',
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class FoodClassifierService {
  FoodClassifierService._();
  static final FoodClassifierService instance = FoodClassifierService._();

  ImageLabeler? _labeler;

  ImageLabeler _getLabeler() {
    _labeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.45),
    );
    return _labeler!;
  }

  Future<FoodClassificationResult> classify(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _getLabeler().processImage(inputImage);
      if (labels.isEmpty) return FoodClassificationResult.notFood();

      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      final scored = labels.map((l) => _ScoredLabel(l.label.toLowerCase(), l.confidence)).toList();

      // Try to find a food match
      final match = _matchCategory(scored);
      if (match == null) return FoodClassificationResult.notFood();

      final dietaryResult = _inferDietaryTags(scored, match.category);

      return FoodClassificationResult(
        category: match.category,
        suggestedTitle: match.title,
        dietaryTags: dietaryResult.confident,
        uncertainTags: dietaryResult.uncertain,
        confidence: match.confidence,
        hasResult: true,
      );
    } catch (e) {
      debugPrint('FoodClassifierService error: $e');
      return FoodClassificationResult.notFood();
    }
  }

  void dispose() {
    _labeler?.close();
    _labeler = null;
  }

  // ── Category matching ─────────────────────────────────────────────────────
  //
  // Each rule: list of ML Kit keywords → (category, human-readable title).
  // Rules are checked in ORDER — first match wins.
  // More specific rules must come before general ones.

  _CategoryMatch? _matchCategory(List<_ScoredLabel> labels) {
    // Helper: returns the confidence of the first matching label, or 0.
    double conf(List<String> keywords) {
      for (final kw in keywords) {
        for (final l in labels) {
          if (l.label.contains(kw)) return l.confidence;
        }
      }
      return 0;
    }

    // ── FRUITS ──────────────────────────────────────────────────────────────
    final fruitMap = {
      'banana':      'Banana',
      'strawberr':   'Strawberries',
      'orange':      'Orange',
      'lemon':       'Lemon',
      'lime':        'Lime',
      'pineapple':   'Pineapple',
      'mango':       'Mango',
      'watermelon':  'Watermelon',
      'fig':         'Fig',
      'pomegranate': 'Pomegranate',
      'jackfruit':   'Jackfruit',
      'coconut':     'Coconut',
      'grapefrut':   'Grapefruit', // mlkit typo variant
      'grapefruit':  'Grapefruit',
      'grape':       'Grapes',
      'apple':       'Apple',
      'pear':        'Pear',
      'peach':       'Peach',
      'plum':        'Plum',
      'cherry':      'Cherries',
      'apricot':     'Apricot',
      'avocado':     'Avocado',
      'kiwi':        'Kiwi',
      'melon':       'Melon',
      'papaya':      'Papaya',
      'guava':       'Guava',
      'durian':      'Durian',
      'rambutan':    'Rambutan',
      'lychee':      'Lychee',
      'longan':      'Longan',
      'passion fruit': 'Passion Fruit',
      'custard apple': 'Atis',
      'soursop':     'Guyabano',
      'calamansi':   'Calamansi',
      'santol':      'Santol',
      'star fruit':  'Star Fruit',
      'pomelo':      'Pomelo',
      'fruit':       'Fresh Fruit',
    };
    for (final entry in fruitMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Fruits', entry.value, c);
    }

    // ── VEGETABLES ──────────────────────────────────────────────────────────
    final vegMap = {
      'broccoli':    'Broccoli',
      'cauliflower': 'Cauliflower',
      'artichoke':   'Artichoke',
      'mushroom':    'Mushroom',
      'zucchini':    'Zucchini',
      'cucumber':    'Cucumber',
      'bell pepper': 'Bell Pepper',
      'hot pepper':  'Chili Pepper',
      'chili':       'Chili',
      'jalapeno':    'Jalapeño',
      'tomato':      'Tomato',
      'potato':      'Potato',
      'sweet potato':'Sweet Potato (Kamote)',
      'yam':         'Yam',
      'carrot':      'Carrot',
      'corn':        'Corn',
      'maize':       'Corn',
      'lettuce':     'Lettuce',
      'spinach':     'Spinach',
      'kale':        'Kale',
      'cabbage':     'Cabbage',
      'onion':       'Onion',
      'garlic':      'Garlic',
      'ginger':      'Ginger',
      'eggplant':    'Eggplant (Talong)',
      'pumpkin':     'Pumpkin',
      'squash':      'Squash',
      'leek':        'Leek',
      'celery':      'Celery',
      'asparagus':   'Asparagus',
      'green bean':  'Green Beans (Sitaw)',
      'string bean': 'String Beans',
      'bean sprout': 'Bean Sprouts',
      'okra':        'Okra',
      'radish':      'Radish',
      'turnip':      'Turnip',
      'beet':        'Beet',
      'bok choy':    'Bok Choy (Pechay)',
      'pechay':      'Pechay',
      'kangkong':    'Water Spinach (Kangkong)',
      'ampalaya':    'Bitter Gourd (Ampalaya)',
      'bitter gourd':'Bitter Gourd (Ampalaya)',
      'malunggay':   'Moringa (Malunggay)',
      'moringa':     'Moringa',
      'vegetable':   'Fresh Vegetables',
      'produce':     'Fresh Produce',
    };
    for (final entry in vegMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Vegetables', entry.value, c);
    }

    // ── MEAT ────────────────────────────────────────────────────────────────
    final meatMap = {
      'meat loaf':   'Meatloaf',
      'meatball':    'Meatballs',
      'hot dog':     'Hot Dog',
      'sausage':     'Sausage',
      'bacon':       'Bacon',
      'ham':         'Ham',
      'pork':        'Pork',
      'beef':        'Beef',
      'steak':       'Steak',
      'chicken':     'Chicken',
      'turkey':      'Turkey',
      'lamb':        'Lamb',
      'goat':        'Goat Meat',
      'poultry':     'Poultry',
      'drumstick':   'Chicken Drumstick',
      'fried chicken':'Fried Chicken',
      'longganisa':  'Longganisa',
      'tocino':      'Tocino',
      'tapa':        'Beef Tapa',
      'chicharon':   'Chicharon',
      'lechon':      'Lechon',
      'sisig':       'Sisig',
      'meat':        'Meat',
    };
    for (final entry in meatMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Meat', entry.value, c);
    }

    // ── SEAFOOD ─────────────────────────────────────────────────────────────
    final seafoodMap = {
      'fish':        'Fish',
      'tench':       'Fish (Tench)',    // common ImageNet label for fish
      'tilapia':     'Tilapia',
      'bangus':      'Bangus (Milkfish)',
      'milkfish':    'Bangus (Milkfish)',
      'salmon':      'Salmon',
      'tuna':        'Tuna',
      'sardine':     'Sardines',
      'mackerel':    'Mackerel (Galunggong)',
      'galunggong':  'Galunggong',
      'shrimp':      'Shrimp (Hipon)',
      'prawn':       'Prawn',
      'lobster':     'Lobster',
      'crab':        'Crab (Alimasag)',
      'squid':       'Squid (Pusit)',
      'octopus':     'Octopus',
      'mussel':      'Mussel (Tahong)',
      'clam':        'Clam (Halaan)',
      'oyster':      'Oyster (Talaba)',
      'scallop':     'Scallop',
      'sea cucumber':'Sea Cucumber',
      'jellyfish':   'Jellyfish',
      'crayfish':    'Crayfish',
      'seafood':     'Seafood',
    };
    for (final entry in seafoodMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Seafood', entry.value, c);
    }

    // ── EGGS ────────────────────────────────────────────────────────────────
    final eggMap = {
      'egg':         'Eggs',
      'omelette':    'Omelette',
      'quiche':      'Quiche',
      'deviled egg': 'Deviled Eggs',
      'salted egg':  'Salted Egg (Itlog na Maalat)',
      'century egg': 'Century Egg',
      'balut':       'Balut',
    };
    for (final entry in eggMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Eggs', entry.value, c);
    }

    // ── DAIRY ────────────────────────────────────────────────────────────────
    final dairyMap = {
      'milk':        'Milk',
      'cheese':      'Cheese',
      'butter':      'Butter',
      'cream':       'Cream',
      'yogurt':      'Yogurt',
      'ice cream':   'Ice Cream',
      'dairy':       'Dairy Product',
    };
    for (final entry in dairyMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Dairy', entry.value, c);
    }

    // ── GRAINS & RICE ────────────────────────────────────────────────────────
    final grainMap = {
      'rice':        'Rice',
      'fried rice':  'Fried Rice',
      'noodle':      'Noodles',
      'pasta':       'Pasta',
      'spaghetti':   'Spaghetti',
      'carbonara':   'Carbonara',
      'ramen':       'Ramen',
      'oat':         'Oats',
      'cereal':      'Cereal',
      'granola':     'Granola',
      'quinoa':      'Quinoa',
      'barley':      'Barley',
      'wheat':       'Wheat',
      'grain':       'Grain',
      'muesli':      'Muesli',
    };
    for (final entry in grainMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Grains & Rice', entry.value, c);
    }

    // ── BREAD & PASTRIES ─────────────────────────────────────────────────────
    final breadMap = {
      'french loaf': 'French Bread',
      'bagel':       'Bagel',
      'pretzel':     'Pretzel',
      'bread':       'Bread',
      'pandesal':    'Pandesal',
      'ensaymada':   'Ensaymada',
      'bun':         'Bun',
      'roll':        'Bread Roll',
      'croissant':   'Croissant',
      'toast':       'Toast',
      'muffin':      'Muffin',
      'cupcake':     'Cupcake',
      'cup cake':    'Cupcake',
      'doughnut':    'Doughnut',
      'donut':       'Donut',
      'waffle':      'Waffle',
      'pancake':     'Pancake',
      'crepe':       'Crepe',
      'cake':        'Cake',
      'pastry':      'Pastry',
      'pie':         'Pie',
      'tart':        'Tart',
      'danish':      'Danish Pastry',
      'bakery':      'Baked Goods',
    };
    for (final entry in breadMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Bread & Pastries', entry.value, c);
    }

    // ── SNACKS ───────────────────────────────────────────────────────────────
    final snackMap = {
      'potato chip': 'Potato Chips',
      'chip':        'Chips',
      'crisp':       'Crisps',
      'popcorn':     'Popcorn',
      'cracker':     'Crackers',
      'saltine':     'Crackers',
      'candy bar':   'Candy Bar',
      'chocolate':   'Chocolate',
      'candy':       'Candy',
      'gummy':       'Gummy Candy',
      'lollipop':    'Lollipop',
      'ice lolly':   'Popsicle',
      'popsicle':    'Popsicle',
      'biscuit':     'Biscuit',
      'cookie':      'Cookies',
      'snack':       'Snack',
      'junk food':   'Junk Food',
      'popcorn box': 'Popcorn',
      'piattos':     'Piattos',
      'nova':        'Nova Chips',
      'chippy':      'Chippy',
      'boy bawang':  'Boy Bawang',
      'oishi':       'Oishi Snacks',
    };
    for (final entry in snackMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Snacks', entry.value, c);
    }

    // ── COOKED MEALS ─────────────────────────────────────────────────────────
    final mealMap = {
      'pizza':       'Pizza',
      'hamburger':   'Hamburger',
      'cheeseburger':'Cheeseburger',
      'burrito':     'Burrito',
      'taco':        'Taco',
      'sandwich':    'Sandwich',
      'hot pot':     'Hot Pot',
      'stew':        'Stew',
      'soup':        'Soup',
      'curry':       'Curry',
      'potpie':      'Pot Pie',
      'pot pie':     'Pot Pie',
      'casserole':   'Casserole',
      'stir fry':    'Stir Fry',
      'adobo':       'Adobo',
      'sinigang':    'Sinigang',
      'kare-kare':   'Kare-Kare',
      'bulalo':      'Bulalo',
      'tinola':      'Tinola',
      'nilaga':      'Nilaga',
      'caldereta':   'Caldereta',
      'menudo':      'Menudo',
      'afritada':    'Afritada',
      'mechado':     'Mechado',
      'paksiw':      'Paksiw',
      'pinakbet':    'Pinakbet',
      'laing':       'Laing',
      'bicol express':'Bicol Express',
      'champorado':  'Champorado',
      'arroz caldo': 'Arroz Caldo',
      'lugaw':       'Lugaw',
      'goto':        'Goto',
      'mashed potato':'Mashed Potato',
      'guacamole':   'Guacamole',
      'dough':       'Dough',
      'dish':        'Cooked Dish',
      'meal':        'Cooked Meal',
      'cooked':      'Cooked Food',
      'fried':       'Fried Food',
    };
    for (final entry in mealMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Cooked Meals', entry.value, c);
    }

    // ── DESSERTS ─────────────────────────────────────────────────────────────
    final dessertMap = {
      'ice cream':   'Ice Cream',
      'sundae':      'Ice Cream Sundae',
      'gelatin':     'Gelatin',
      'pudding':     'Pudding',
      'brownie':     'Brownie',
      'mousse':      'Mousse',
      'flan':        'Leche Flan',
      'leche flan':  'Leche Flan',
      'maja':        'Maja Blanca',
      'halo-halo':   'Halo-Halo',
      'polvoron':    'Polvoron',
      'palitaw':     'Palitaw',
      'bibingka':    'Bibingka',
      'puto':        'Puto',
      'kutsinta':    'Kutsinta',
      'biko':        'Biko',
      'sapin-sapin': 'Sapin-Sapin',
      'dessert':     'Dessert',
      'sweet':       'Sweet',
    };
    for (final entry in dessertMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Desserts', entry.value, c);
    }

    // ── BEVERAGES ────────────────────────────────────────────────────────────
    final bevMap = {
      'espresso':    'Coffee',
      'coffee':      'Coffee',
      'tea':         'Tea',
      'juice':       'Juice',
      'soda':        'Soda',
      'beer':        'Beer',
      'wine':        'Wine',
      'water':       'Water',
      'smoothie':    'Smoothie',
      'milkshake':   'Milkshake',
      'eggnog':      'Eggnog',
      'milo':        'Milo',
      'c2':          'C2 Tea',
      'zesto':       'Zesto Juice',
      'nestea':      'Nestea',
      'beverage':    'Beverage',
      'drink':       'Drink',
      'liquid':      'Beverage',
    };
    for (final entry in bevMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Beverages', entry.value, c);
    }

    // ── CONDIMENTS ───────────────────────────────────────────────────────────
    final condMap = {
      'ketchup':     'Ketchup',
      'sauce':       'Sauce',
      'mayonnaise':  'Mayonnaise',
      'mustard':     'Mustard',
      'vinegar':     'Vinegar',
      'soy sauce':   'Soy Sauce',
      'hot sauce':   'Hot Sauce',
      'salsa':       'Salsa',
      'guacamole':   'Guacamole',
      'hummus':      'Hummus',
      'dressing':    'Salad Dressing',
      'syrup':       'Syrup',
      'jam':         'Jam',
      'jelly':       'Jelly',
      'honey':       'Honey',
      'peanut butter':'Peanut Butter',
      'spread':      'Spread',
      'datu puti':   'Datu Puti Vinegar',
      'silver swan':  'Silver Swan Soy Sauce',
      'bagoong':     'Bagoong',
      'patis':       'Fish Sauce (Patis)',
      'alamang':     'Shrimp Paste (Alamang)',
      'condiment':   'Condiment',
    };
    for (final entry in condMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Condiments', entry.value, c);
    }

    // ── SPICES & HERBS ───────────────────────────────────────────────────────
    final spiceMap = {
      'basil':       'Basil',
      'thyme':       'Thyme',
      'oregano':     'Oregano',
      'rosemary':    'Rosemary',
      'parsley':     'Parsley',
      'cilantro':    'Cilantro',
      'coriander':   'Coriander',
      'mint':        'Mint',
      'bay leaf':    'Bay Leaf',
      'turmeric':    'Turmeric',
      'cinnamon':    'Cinnamon',
      'paprika':     'Paprika',
      'cumin':       'Cumin',
      'pepper':      'Pepper',
      'peppercorn':  'Peppercorn',
      'salt':        'Salt',
      'herb':        'Herbs',
      'spice':       'Spices',
      'seasoning':   'Seasoning',
    };
    for (final entry in spiceMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Spices & Herbs', entry.value, c);
    }

    // ── OTHER (canned, packaged, unrecognized food containers) ───────────────
    final otherMap = {
      'can':         'Canned Goods',
      'canned':      'Canned Goods',
      'tin can':     'Canned Goods',
      'jar':         'Jarred Goods',
      'packet':      'Packaged Food',
      'package':     'Packaged Food',
      'box':         'Boxed Food',
      'carton':      'Carton',
      'food':        'Food Item',   // last resort — ML Kit saw food but nothing specific
    };
    for (final entry in otherMap.entries) {
      final c = conf([entry.key]);
      if (c > 0) return _CategoryMatch('Other', entry.value, c);
    }

    // Nothing matched at all
    return null;
  }

  // ── Dietary tag inference ─────────────────────────────────────────────────
  //
  // RULE: only add a tag on POSITIVE evidence.
  // Confident tags → shown normally (green chip).
  // Uncertain tags → shown with ⚠ icon (orange chip), user should verify.

  _DietaryResult _inferDietaryTags(List<_ScoredLabel> labels, String category) {
    final confident = <String>[];
    final uncertain = <String>[];

    bool hasLabel(List<String> keywords) =>
        keywords.any((kw) => labels.any((l) => l.label.contains(kw)));

    // ── Helper to add tag at right confidence level ──
    void add(String tag, {required bool sure}) {
      if (sure) {
        if (!confident.contains(tag)) confident.add(tag);
      } else {
        if (!uncertain.contains(tag) && !confident.contains(tag)) uncertain.add(tag);
      }
    }

    // ── VEGAN ────────────────────────────────────────────────────────────────
    // Only for clearly plant-based categories with no animal product labels.
    final isPlantCategory = ['Fruits', 'Vegetables', 'Spices & Herbs'].contains(category);
    final hasAnimalLabel = hasLabel([
      'meat', 'chicken', 'beef', 'pork', 'fish', 'seafood', 'egg',
      'dairy', 'milk', 'cheese', 'butter', 'cream', 'yogurt',
      'shrimp', 'prawn', 'crab', 'lobster', 'sausage', 'bacon', 'ham',
    ]);

    if (isPlantCategory && !hasAnimalLabel) {
      add('Vegan', sure: true);
      add('Vegetarian', sure: true);
    } else if (category == 'Grains & Rice' && !hasAnimalLabel) {
      // Rice and plain grains are usually vegan but might have added ingredients
      add('Vegan', sure: false);
      add('Vegetarian', sure: false);
    }

    // ── VEGETARIAN ───────────────────────────────────────────────────────────
    if (category == 'Dairy' || category == 'Eggs') {
      add('Vegetarian', sure: true);
    }

    // ── GLUTEN-FREE ──────────────────────────────────────────────────────────
    // Naturally gluten-free: fresh fruits, vegetables, plain meat, plain seafood, plain eggs
    const certainlyGF = ['Fruits', 'Vegetables', 'Meat', 'Seafood', 'Eggs', 'Spices & Herbs'];
    const probablyGF  = ['Dairy']; // most dairy is GF but processed variants may not be

    if (certainlyGF.contains(category)) {
      add('Gluten-Free', sure: true);
    } else if (probablyGF.contains(category)) {
      add('Gluten-Free', sure: false);
    }
    // Everything else (Snacks, Grains, Bread, Cooked Meals, etc.) → no GF tag

    // ── DAIRY-FREE ───────────────────────────────────────────────────────────
    // Only tag Dairy-Free if we're sure there's no dairy
    if (['Fruits', 'Vegetables', 'Meat', 'Seafood', 'Eggs',
         'Grains & Rice', 'Spices & Herbs'].contains(category) && !hasAnimalLabel) {
      add('Dairy-Free', sure: false); // uncertain — might have added dairy in processing
    }

    // ── NUT-FREE, HALAL, KOSHER, LOW-SUGAR ───────────────────────────────────
    // Cannot determine these from a photo — skip entirely.
    // User must select these manually.

    return _DietaryResult(confident: confident, uncertain: uncertain);
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _ScoredLabel {
  final String label;
  final double confidence;
  const _ScoredLabel(this.label, this.confidence);
}

class _CategoryMatch {
  final String category;
  final String title;
  final double confidence;
  const _CategoryMatch(this.category, this.title, this.confidence);
}

class _DietaryResult {
  final List<String> confident;
  final List<String> uncertain;
  const _DietaryResult({required this.confident, required this.uncertain});
}