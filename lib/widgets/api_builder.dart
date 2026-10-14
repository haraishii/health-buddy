import 'package:flutter/material.dart';

import '../data/api/api_client.dart';
import '../data/api/health_buddy_api.dart';
import '../data/api/session.dart';
import '../theme.dart';
import 'common.dart';

/// Loads data from the API and shows, with a crossfade:
///  * [loading] (a shimmer skeleton) the first time,
///  * [builder] once data arrives,
///  * a friendly error card with "Try again" when the request fails and there is nothing to show.
///
/// Data is cached per [cacheKey]: reopening a screen shows the last data instantly and refreshes it quietly.
/// It also reloads whenever `session.dataChanged()` is called (after logging a meal, editing the profile, ...).
class ApiBuilder<T extends Object> extends StatefulWidget {
  const ApiBuilder({
    super.key,
    required this.cacheKey,
    required this.load,
    required this.builder,
    required this.loading,
  });

  final String cacheKey;
  final Future<T> Function(HealthBuddyApi api) load;
  final Widget Function(BuildContext context, T data) builder;
  final Widget loading;

  @override
  State<ApiBuilder<T>> createState() => _ApiBuilderState<T>();
}

class _ApiBuilderState<T extends Object> extends State<ApiBuilder<T>> {
  Session? _session;
  T? _data;
  String? _error;
  bool _networkError = false;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = SessionScope.of(context);
    if (session != _session) {
      _session?.dataVersion.removeListener(_fetch);
      _session = session..dataVersion.addListener(_fetch);
      _data = session.cached<T>(widget.cacheKey);
      _fetch();
    }
  }

  @override
  void didUpdateWidget(ApiBuilder<T> old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey) {
      _data = _session!.cached<T>(widget.cacheKey);
      _error = null;
      _fetch();
    }
  }

  @override
  void dispose() {
    _session?.dataVersion.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    final id = ++_request;
    final key = widget.cacheKey;
    try {
      final data = await _session!.fetch<T>(key, widget.load);
      if (mounted && id == _request) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted && id == _request) {
        setState(() {
          _error = e.message;
          _networkError = e.isNetwork;
        });
      }
    } catch (e, stack) {
      debugPrint('ApiBuilder($key): $e\n$stack');
      if (mounted && id == _request) {
        setState(() {
          _error = 'Something went wrong while reading the data.';
          _networkError = false;
        });
      }
    }
  }

  void _retry() {
    setState(() => _error = null);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final Widget child;
    final String state;
    if (data != null) {
      // Stale data stays on screen if a background refresh fails.
      (child, state) = (widget.builder(context, data), 'data');
    } else if (_error != null) {
      (child, state) = (ErrorState(message: _error!, network: _networkError, onRetry: _retry), 'error');
    } else {
      (child, state) = (widget.loading, 'loading');
    }
    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 280),
      switchInCurve: Motion.standard,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }
}

/// Shown when a screen has no data because the request failed.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry, this.network = false});

  final String message;
  final VoidCallback onRetry;
  final bool network;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeUp(
          child: AppCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                IconBadge(
                  network ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                  color: AppColors.orangeDark,
                  bg: AppColors.orangeSoft,
                  size: 52,
                  iconSize: 26,
                  radius: 16,
                ),
                Text(
                  network ? "Can't connect right now" : "Couldn't load your data",
                  style: ts(17, FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                Text(message, style: ts(14, FontWeight.w400, AppColors.muted), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                OutlineChipButton(label: 'Try again', icon: Icons.refresh_rounded, onTap: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pull-to-refresh in the app's green that reloads every screen.
class AppRefresh extends StatelessWidget {
  const AppRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: Colors.white,
      onRefresh: SessionScope.of(context).refreshAll,
      child: child,
    );
  }
}

/// Runs a save action with a toast for errors; returns true on success. Reloads the screens afterwards.
Future<bool> saveWithFeedback(BuildContext context, Future<void> Function(HealthBuddyApi api) action) async {
  final session = SessionScope.of(context);
  try {
    await action(session.api);
    session.dataChanged();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showToast(context, e.message, icon: Icons.error_outline_rounded);
    return false;
  }
}
