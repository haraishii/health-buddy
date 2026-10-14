import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/common.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // On success the session switches the app to Home; nothing else to do here.
      await SessionScope.of(context).signIn(email: _email.text, password: _password.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeUp(
                    child: Row(
                      spacing: 8,
                      children: [
                        const IconBadge(Icons.favorite_rounded, color: AppColors.green, bg: AppColors.greenSoft),
                        Text('Health Buddy', style: ts(18, FontWeight.w800, AppColors.greenDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FadeUp(
                    delayMs: 60,
                    child: AuthHero(greeting: 'Welcome back!', message: 'Sign in to see your health insights.'),
                  ),
                  const SizedBox(height: 24),
                  FadeUp(
                    delayMs: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text('Sign in', style: ts(26, FontWeight.w800)),
                        Text(
                          'Track your food, sleep, stress and exercise in one place.',
                          style: ts(15, FontWeight.w400, AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeUp(
                    delayMs: 180,
                    child: AppCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          AuthTextField(
                            label: 'Email',
                            controller: _email,
                            hint: 'you@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: validateEmail,
                            enabled: !_loading,
                          ),
                          AuthTextField(
                            label: 'Password',
                            controller: _password,
                            hint: 'Your password',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                            onSubmitted: (_) => _submit(),
                            enabled: !_loading,
                          ),
                          if (_error != null) AuthErrorBanner(_error!),
                          AuthSubmitButton(label: 'Sign in', loading: _loading, onTap: _submit),
                        ],
                      ),
                    ),
                  ),
                  FadeUp(
                    delayMs: 240,
                    child: AuthSwitchLink(
                      question: 'New to Health Buddy?',
                      action: 'Create an account',
                      onTap: () => Navigator.of(context).push(slideRoute<void>(const RegisterScreen())),
                    ),
                  ),
                  if (kDebugMode) _DevHint(onUse: (email) => setState(() => _fillTestAccount(email))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _fillTestAccount(String email) {
    _email.text = email;
    _password.text = 'password123';
    _error = null;
  }
}

/// Debug builds only: which server the app talks to, plus one-tap test accounts from the backend seed.
class _DevHint extends StatelessWidget {
  const _DevHint({required this.onUse});

  final ValueChanged<String> onUse;

  static const _accounts = ['annida@example.com', 'bima@example.com', 'citra@example.com'];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('Developer · API: $apiBaseUrl', style: ts(12, FontWeight.w600, AppColors.muted)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in _accounts)
                PressScale(
                  label: 'Use test account $a',
                  onTap: () => onUse(a),
                  child: Pill(a.split('@').first, size: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
