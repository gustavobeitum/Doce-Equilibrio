import 'package:doce_equilibrio/features/food/screens/food_library_screen.dart';
import 'package:flutter/material.dart';

abstract interface class FoodLibraryNavigator {
  Future<void> open(BuildContext context);
}

class FlutterFoodLibraryNavigator implements FoodLibraryNavigator {
  @override
  Future<void> open(BuildContext context) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const FoodLibraryScreen()),
    );
  }
}
