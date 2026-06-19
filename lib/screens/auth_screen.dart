import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'app_theme.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin        = true;
  bool _obscure        = true;
  String? _loading;   // 'email' | 'google' | 'apple' | 'anon'
  String? _error;

  void _goHome() => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const MainShell()));

  void _setLoading(String? p) =>
      setState(() { _loading = p; _error = null; });

  Future<void> _submitEmail() async {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      setState(() => _error = 'Champs requis.');
      return;
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
        'user-not-found'      => 'Compte introuvable.',
        'wrong-password'      => 'Mot de passe incorrect.',
        'invalid-credential'  => 'Identifiants incorrects.',
        'email-already-in-use'=> 'Email déjà utilisé.',
        'weak-password'       => 'Mot de passe trop court.',
        _                     => e.message ?? 'Erreur.',
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
          GoogleAuthProvider.credential(
              accessToken: auth.accessToken, idToken: auth.idToken));
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
      if (e.code != AuthorizationErrorCode.canceled)
        setState(() => _error = 'Erreur Apple.');
    } finally { _setLoading(null); }
  }

  Future<void> _anon() async {
    _setLoading('anon');
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _goHome();
    } catch (_) { setState(() => _error = 'Erreur.'); }
    finally { _setLoading(null); }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Entre ton email d\'abord.');
      return;
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // Logo
              const Text('🦎', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(_isLogin ? 'Connexion' : 'Créer un compte',
                  textAlign: TextAlign.center,
                  style: T.t22.copyWith(color: T.textPrimary)),
              const SizedBox(height: 4),
              Text('TerrariumApp',
                  textAlign: TextAlign.center,
                  style: T.t13.copyWith(color: T.textSecondary)),
              const SizedBox(height: 36),

              // Email
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: T.textPrimary, fontSize: 15),
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 10),

              // Password
              TextField(
                controller: _password,
                obscureText: _obscure,
                style: const TextStyle(color: T.textPrimary, fontSize: 15),
                onSubmitted: (_) => _submitEmail(),
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: T.textSecondary, size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              // Mot de passe oublié
              if (_isLogin) Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgot,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36)),
                  child: Text('Mot de passe oublié ?',
                      style: T.t13.copyWith(color: T.textSecondary)),
                ),
              ) else const SizedBox(height: 10),

              // Erreur
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: T.t13.copyWith(color: T.red)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),

              // Bouton principal
              _Btn(
                label: _isLogin ? 'Se connecter' : 'Créer le compte',
                loading: _loading == 'email',
                disabled: _loading != null,
                onTap: _submitEmail,
                primary: true,
              ),
              const SizedBox(height: 20),

              // Séparateur
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: T.t13.copyWith(color: T.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              // Google
              _Btn(
                label: 'Continuer avec Google',
                loading: _loading == 'google',
                disabled: _loading != null,
                onTap: _google,
                icon: const _GoogleIcon(),
              ),
              const SizedBox(height: 10),

              // Apple
              _Btn(
                label: 'Continuer avec Apple',
                loading: _loading == 'apple',
                disabled: _loading != null,
                onTap: _apple,
                icon: const Icon(Icons.apple, color: T.textPrimary, size: 18),
              ),
              const SizedBox(height: 10),

              // Anonyme
              _Btn(
                label: 'Continuer en tant qu\'invité',
                loading: _loading == 'anon',
                disabled: _loading != null,
                onTap: _anon,
                ghost: true,
              ),
              const SizedBox(height: 28),

              // Toggle
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  _isLogin ? 'Pas encore de compte ?' : 'Déjà un compte ?',
                  style: T.t13.copyWith(color: T.textSecondary),
                ),
                TextButton(
                  onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: Text(
                    _isLogin ? 'S\'inscrire' : 'Se connecter',
                    style: T.t13.copyWith(color: T.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool loading, disabled, primary, ghost;
  final VoidCallback onTap;
  final Widget? icon;
  const _Btn({
    required this.label, required this.loading,
    required this.disabled, required this.onTap,
    this.primary = false, this.ghost = false, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled && !loading ? 0.5 : 1.0,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: primary ? T.green : (ghost ? Colors.transparent : T.elevated),
            borderRadius: BorderRadius.circular(10),
            border: ghost ? Border.all(color: T.border) : null,
          ),
          child: loading
              ? Center(child: CupertinoActivityIndicator(
                  color: primary ? T.bg : T.textSecondary))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label, style: T.t14.copyWith(
                    color: primary ? T.bg : (ghost ? T.textSecondary : T.textPrimary),
                    fontWeight: FontWeight.w600,
                  )),
                ]),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18, height: 18,
    child: CustomPaint(painter: _GP()),
  );
}

class _GP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    const cols = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1.5),
        (i * 90 - 45) * 3.14159 / 180, 80 * 3.14159 / 180, false,
        Paint()..color = cols[i]..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.butt,
      );
    }
    canvas.drawLine(Offset(c.dx, c.dy), Offset(c.dx + r - 1.5, c.dy),
        Paint()..color = const Color(0xFF4285F4)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_GP _) => false;
}
