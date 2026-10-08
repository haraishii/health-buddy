import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/ai_coach/presentation/pages/ai_coach_screen.dart';
import '../features/analytics/presentation/pages/analytics_screen.dart';
import '../features/food/presentation/pages/food_screen.dart';
import '../features/home/presentation/pages/home_screen.dart';
import '../features/profile/presentation/pages/profile_screen.dart';
import '../theme.dart';
import '../widgets/animated.dart';
import '../widgets/common.dart';
import 'navigation/app_tab_controller.dart';

void runHealthBuddyApp() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HealthBuddyApp());
}

class HealthBuddyApp extends StatelessWidget {
  const HealthBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Buddy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AppShell(),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _TabSpec('Home', Icons.home_outlined, Icons.home_rounded),
  _TabSpec('Analytics', Icons.bar_chart_rounded, Icons.bar_chart_rounded),
  _TabSpec('AI Coach', Icons.smart_toy_outlined, Icons.smart_toy_rounded),
  _TabSpec('Food', Icons.restaurant_outlined, Icons.restaurant_rounded),
  _TabSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  Widget _page(int i) {
    switch (i) {
      case 1:
        return const AnalyticsScreen();
      case 2:
        return const AiCoachScreen();
      case 3:
        return const FoodScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentTab,
      builder: (context, index, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          // Tab switch: crossfade + small slide (220 ms).
          child: AnimatedSwitcher(
            duration: reduceMotion(context) ? Duration.zero : Motion.tab,
            switchInCurve: Motion.standard,
            switchOutCurve: Curves.easeOut,
            layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.025, 0), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey<int>(index), child: _page(index)),
          ),
        ),
        bottomNavigationBar: _BottomNav(index: index, onTap: (i) => currentTab.value = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: _tabs[i].label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: SizedBox(
                        height: 52,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 3,
                          children: [
                            BounceOnSelect(
                              selected: i == index,
                              child: Icon(
                                i == index ? _tabs[i].activeIcon : _tabs[i].icon,
                                size: 25,
                                color: i == index ? AppColors.green : AppColors.muted,
                              ),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: ts(
                                12,
                                i == index ? FontWeight.w700 : FontWeight.w500,
                                i == index ? AppColors.greenDark : AppColors.muted,
                              ).copyWith(fontFamily: DefaultTextStyle.of(context).style.fontFamily),
                              child: Text(_tabs[i].label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
