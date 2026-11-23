import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../services/mock_auth_service.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final MockAuthService auth;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (!widget.auth.login(_phone.text, _password.text)) {
      setState(() => _error = 'Incorrect phone number or password.');
    }
  }

  void _fillDemo() {
    _formKey.currentState!.reset();
    _phone.text = MockAuthService.demoResident.phone;
    _password.text = MockAuthService.demoPassword;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      maxWidth: 1060,
      child: LayoutBuilder(
        builder: (context, size) {
          final wide = size.maxWidth >= 720;
          final form = Padding(
            padding: EdgeInsets.all(wide ? 40 : 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: mist,
                      child: Icon(Icons.key_outlined, color: sea),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PageHeading(
                    'Welcome back',
                    'Log in to access your resident services.',
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your phone number.';
                      }
                      if (!RegExp(r'^\d{11}$').hasMatch(value.trim())) {
                        return 'Enter an 11-digit phone number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    enableSuggestions: false,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _login,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward, size: 19),
                    label: const Text('Login'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _fillDemo,
                      child: const Text('Fill demo credentials'),
                    ),
                  ],
                ],
              ),
            ),
          );
          final hero = _CoastPanel(compact: !wide);
          return Panel(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: wide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 11,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 490),
                              child: hero,
                            ),
                          ),
                          Expanded(flex: 10, child: Center(child: form)),
                        ],
                      ),
                    )
                  : Column(children: [hero, form]),
            ),
          );
        },
      ),
    );
  }
}

class _CoastPanel extends StatelessWidget {
  const _CoastPanel({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomLeft,
      constraints: BoxConstraints(minHeight: compact ? 172 : 0),
      padding: EdgeInsets.all(compact ? 22 : 36),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/north_coast.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: navy.withValues(alpha: .93),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HAP North Coast',
                    style: heading(compact ? 28 : 38)
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resident Portal',
                    style: TextStyle(color: Color(0xFFD5E9EB), fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
