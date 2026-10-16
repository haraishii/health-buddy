import 'package:flutter/material.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/api/session.dart';
import '../../../../theme.dart';
import '../../../../widgets/common.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
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
      // On success the session switches the app to Home and the app closes this screen.
      await SessionScope.of(context).signUp(name: _name.text, email: _email.text, password: _password.text);
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BackHeader('Create account'),
                  const SizedBox(height: 18),
                  const FadeUp(
                    child: AuthHero(
                      greeting: 'Nice to meet you!',
                      message: 'Create an account so I can learn your habits and give personal tips.',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeUp(
                    delayMs: 80,
                    child: AppCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          AuthTextField(
                            label: 'Name',
                            controller: _name,
                            hint: 'What should I call you?',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                            enabled: !_loading,
                          ),
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
                            hint: 'At least 8 characters',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (v) {
                              final n = (v ?? '').length;
                              if (n < 8) return 'Use at least 8 characters';
                              if (n > 72) return 'Use at most 72 characters';
                              return null;
                            },
                            enabled: !_loading,
                          ),
                          AuthTextField(
                            label: 'Confirm password',
                            controller: _confirm,
                            hint: 'Type it again',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                            onSubmitted: (_) => _submit(),
                            enabled: !_loading,
                          ),
                          if (_error != null) AuthErrorBanner(_error!),
                          AuthSubmitButton(label: 'Create account', loading: _loading, onTap: _submit),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeUp(
                    delayMs: 140,
                    child: Text(
                      'Health Buddy gives lifestyle tips, not medical advice.',
                      textAlign: TextAlign.center,
                      style: ts(12.5, FontWeight.w400, AppColors.muted),
                    ),
                  ),
                  FadeUp(
                    delayMs: 160,
                    child: AuthSwitchLink(
                      question: 'Already have an account?',
                      action: 'Sign in',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
