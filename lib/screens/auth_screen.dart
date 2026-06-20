import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'app_theme.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;
  String? _loading;
  String? _error;

  void _goHome() => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const MainShell()));

  void _setLoading(String? p) => setState(() { _loading = p; _error = null; });

  Future<void> _submitEmail() async {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      setState(() => _error = 'Champs requis.'); return;
    }
    _setLoading('email');
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text.trim());
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text.trim());
      }
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
        'user-not-found'       => 'Compte introuvable.',
        'wrong-password'       => 'Mot de passe incorrect.',
        'invalid-credential'   => 'Identifiants incorrects.',
        'email-already-in-use' => 'Email déjà utilisé.',
        'weak-password'        => 'Mot de passe trop court.',
        _                      => e.message ?? 'Erreur.',
      });
    } finally { _setLoading(null); }
  }

  Future<void> _google() async {
    _setLoading('google');
    try {
      final u = await GoogleSignIn().signIn();
      if (u == null) { _setLoading(null); return; }
      final auth = await u.authentication;
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken));
      _goHome();
    } catch (_) { setState(() => _error = 'Connexion Google annulée.'); }
    finally { _setLoading(null); }
  }

  Future<void> _apple() async {
    _setLoading('apple');
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      await FirebaseAuth.instance.signInWithCredential(
          OAuthProvider('apple.com').credential(
              idToken: cred.identityToken, accessToken: cred.authorizationCode));
      _goHome();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) { setState(() => _error = 'Erreur Apple.'); }
    } finally { _setLoading(null); }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) { setState(() => _error = 'Entre ton email d\'abord.'); return; }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email envoyé')));
  }

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: T.textSecondary),
                label: Text('Retour', style: T.t15.copyWith(color: T.textSecondary)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Icon
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.eco_outlined, color: T.green, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('Bon retour', style: T.serif(32)),
                    const SizedBox(height: 6),
                    Text('Connecte-toi à ta jungle', style: T.t15.copyWith(color: T.textSecondary)),
                    const SizedBox(height: 32),

                    // Google
                    _SocialBtn(
                      onTap: _loading != null ? null : _google,
                      loading: _loading == 'google',
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 20, height: 20,
                          errorBuilder: (context, error, stack) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text('Continuer avec Google', style: T.t16.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou', style: T.t14.copyWith(color: T.textSecondary))),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),

                    // Email
                    _InputField(
                      controller: _email,
                      hint: 'ton@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // Password
                    _InputField(
                      controller: _password,
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      onSubmit: _submitEmail,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: T.textSecondary, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    if (_isLogin) Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgot,
                        child: Text('Mot de passe oublié ?', style: T.t13.copyWith(color: T.textSecondary)),
                      ),
                    ) else const SizedBox(height: 12),

                    if (_error != null) Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: T.t13.copyWith(color: T.red)),
                    ),

                    // Submit
                    _GreenBtn(
                      label: _isLogin ? 'Se connecter' : 'Créer le compte',
                      loading: _loading == 'email',
                      disabled: _loading != null,
                      onTap: _submitEmail,
                    ),
                    const SizedBox(height: 16),

                    // Toggle
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? ',
                        style: T.t14.copyWith(color: T.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                        child: Text(
                          _isLogin ? 'Inscris-toi' : 'Se connecter',
                          style: T.t14.copyWith(color: T.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final VoidCallback? onSubmit;
  const _InputField({required this.controller, required this.hint, required this.icon,
    this.obscure = false, this.keyboardType, this.suffix, this.onSubmit});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: T.t16.copyWith(color: T.textPrimary),
    onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: T.textSecondary, size: 20),
      suffixIcon: suffix,
    ),
  );
}

class _SocialBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool loading;
  const _SocialBtn({required this.child, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: T.card2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.border),
      ),
      child: loading
          ? const Center(child: CupertinoActivityIndicator())
          : Center(child: child),
    ),
  );
}

class _GreenBtn extends StatelessWidget {
  final String label;
  final bool loading, disabled;
  final VoidCallback onTap;
  const _GreenBtn({required this.label, required this.onTap,
    this.loading = false, this.disabled = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: disabled ? null : onTap,
    child: Container(
      height: 58,
      decoration: BoxDecoration(
        color: T.greenBtn,
        borderRadius: BorderRadius.circular(16),
      ),
      child: loading
          ? const Center(child: CupertinoActivityIndicator(color: Color(0xFF0A1A0F)))
          : Center(child: Text(label,
              style: T.t17.copyWith(color: const Color(0xFF0A1A0F)))),
    ),
  );
}
