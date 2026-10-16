import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme.dart';
import '../../../../widgets/animated.dart';
import '../../../../widgets/common.dart';

/// Robot mascot with a speech bubble, the same look as the AI Coach header.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, required this.greeting, required this.message});

  final String greeting;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      color: AppColors.greenSoft,
      borderColor: AppColors.greenBubbleBorder,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
      child: Row(
        spacing: 10,
        children: [
          const RobotMascot(width: 76),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(greeting, style: ts(15, FontWeight.w700)),
                  Text("I'm Health Buddy AI.", style: ts(15, FontWeight.w700, AppColors.greenDark)),
                  const SizedBox(height: 2),
                  Text(message, style: ts(13, FontWeight.w400, AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labelled text field in the app's input style (white, 14 px radius, green focus ring).
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.icon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.obscure = false,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  /// Password field: hides the text and shows an eye button.
  final bool obscure;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _hidden = widget.obscure;

  OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(widget.label, style: ts(14, FontWeight.w600)),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          autocorrect: false,
          enableSuggestions: !widget.obscure,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          style: ts(15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: ts(15, FontWeight.w400, AppColors.muted),
            helperText: widget.helper,
            helperStyle: ts(12, FontWeight.w400, AppColors.muted),
            errorStyle: ts(12, FontWeight.w500, AppColors.red),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: widget.icon == null ? null : Icon(widget.icon, size: 20, color: AppColors.muted),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: _border(AppColors.borderStrong),
            disabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.green, 1.5),
            errorBorder: _border(AppColors.red),
            focusedErrorBorder: _border(AppColors.red, 1.5),
          ),
        ),
      ],
    );
  }
}

/// Green primary button that shows a spinner and ignores taps while [loading].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({super.key, required this.label, required this.loading, required this.onTap});

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      label: label,
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: loading ? AppColors.greenDark : AppColors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label, style: ts(16, FontWeight.w700, Colors.white)),
      ),
    );
  }
}

/// Soft red box for errors from the server (wrong password, no connection, ...).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF3D0D0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.red),
            Expanded(child: Text(message, style: ts(13.5, FontWeight.w500, AppColors.red))),
          ],
        ),
      ),
    );
  }
}

/// "Question? Action" line under the form.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      label: action,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text.rich(
          TextSpan(
            text: '$question ',
            style: ts(14, FontWeight.w400, AppColors.muted),
            children: [TextSpan(text: action, style: ts(14, FontWeight.w700, AppColors.greenDark))],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

String? validateEmail(String? v) {
  final s = v?.trim() ?? '';
  if (s.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'This email does not look right';
  return null;
}
