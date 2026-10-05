import 'package:flutter/foundation.dart';

/// Active tab index: Home, Analytics, AI Coach, Food, then Profile.
final ValueNotifier<int> currentTab = ValueNotifier<int>(0);
