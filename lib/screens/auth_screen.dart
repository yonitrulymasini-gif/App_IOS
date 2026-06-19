import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _passwordVisible = false;
  String? _error;
  String? _loadingProvider;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _setLoading(String? provider) => setState(() {
        _loadingProvider = provider;
        _loading = provider != null;
        _error = null;
      });

  Future<void> _submitEmail() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    _setLoading('email');
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: password);
      }
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'user-not-found' => 'Aucun compte avec cet email.',
            'wrong-password' => 'Mot de passe incorrect.',
            'invalid-credential' => 'Email ou mot de passe incorrect.',
            'email-already-in-use' => 'Cet email est déjà utilisé.',
            'weak-password' => 'Mot de passe trop faible (6 car. min).',
            'invalid-email' => 'Format email invalide.',
            _ => 'Erreur : ${e.message}',
          });
    } finally {
      _setLoading(null);
    }
  }

  Future<void> _signInWithGoogle() async {
    _setLoading('google');
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { _setLoading(null); return; }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Google : ${e.message}');
    } catch (_) {
      setState(() => _error = 'Connexion Google annulée.');
    } finally {
      _setLoading(null);
    }
  }

  Future<void> _signInWithApple() async {
    _setLoading('apple');
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      _goHome();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        setState(() => _error = 'Apple : ${e.message}');
      }
    } catch (_) {
      setState(() => _error = 'Connexion Apple annulée.');
    } finally {
      _setLoading(null);
    }
  }

  Future<void> _signInAnonymously() async {
    _setLoading('anonymous');
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Erreur : ${e.message}');
    } finally {
      _setLoading(null);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Entre ton email d\'abord.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé ✓'),
            backgroundColor: Color(0xFF2D3F2D),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = 'Erreur : ${e.message}');
    }
  }

  void _toggleMode() {
    setState(() { _isLogin = !_isLogin; _error = null; });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text('🦎',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 64)),
                const SizedBox(height: 10),
                const Text('TerrariumApp',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(
                  _isLogin ? 'Connexion' : 'Créer un compte',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFE8F0E8),
                      fontSize: 24,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),

                // Email
                _label('Email'),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFFE8F0E8)),
                  decoration: _inputDecoration(
                      hint: 'ton@email.com', icon: Icons.email_outlined),
                ),
                const SizedBox(height: 12),

                // Mot de passe
                _label('Mot de passe'),
                const SizedBox(height: 6),
                TextField(
                  controller: _password,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(color: Color(0xFFE8F0E8)),
                  onSubmitted: (_) => _submitEmail(),
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffix: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B8F6B),
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),

                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36)),
                      child: const Text('Mot de passe oublié ?',
                          style: TextStyle(
                              color: Color(0xFF6B8F6B), fontSize: 12)),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // Erreur
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Bouton email/mdp
                FilledButton(
                  onPressed: _loading ? null : _submitEmail,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: const Color(0xFF1A1F1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loadingProvider == 'email'
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Color(0xFF1A1F1A), strokeWidth: 2))
                      : Text(
                          _isLogin ? 'Se connecter' : 'Créer le compte',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                ),

                // Séparateur
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: Divider(
                          color: const Color(0xFF2D3F2D), thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou',
                        style: TextStyle(
                            color: Color(0xFF6B8F6B), fontSize: 13)),
                  ),
                  Expanded(
                      child: Divider(
                          color: const Color(0xFF2D3F2D), thickness: 1)),
                ]),
                const SizedBox(height: 16),

                // Google
                _SocialButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  loading: _loadingProvider == 'google',
                  label: 'Continuer avec Google',
                  icon: const _GoogleIcon(),
                ),
                const SizedBox(height: 10),

                // Apple
                _SocialButton(
                  onPressed: _loading ? null : _signInWithApple,
                  loading: _loadingProvider == 'apple',
                  label: 'Continuer avec Apple',
                  icon: const Icon(Icons.apple,
                      color: Color(0xFFE8F0E8), size: 20),
                ),
                const SizedBox(height: 10),

                // Anonyme
                _SocialButton(
                  onPressed: _loading ? null : _signInAnonymously,
                  loading: _loadingProvider == 'anonymous',
                  label: 'Continuer en tant qu\'invité',
                  icon: const Icon(Icons.person_outline,
                      color: Color(0xFF6B8F6B), size: 20),
                  subtle: true,
                ),

                const SizedBox(height: 20),

                // Bascule login/register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? 'Pas encore de compte ?'
                          : 'Déjà un compte ?',
                      style: const TextStyle(
                          color: Color(0xFF6B8F6B), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: _toggleMode,
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6)),
                      child: Text(
                        _isLogin ? 'S\'inscrire' : 'Se connecter',
                        style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontWeight: FontWeight.w500,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Color(0xFF6B8F6B), fontSize: 12));

  InputDecoration _inputDecoration(
          {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF2D3F2D)),
        prefixIcon: Icon(icon, color: const Color(0xFF6B8F6B), size: 18),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D3F2D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4ADE80)),
        ),
        filled: true,
        fillColor: const Color(0xFF242B24),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ─── Bouton social ────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final Widget icon;
  final bool subtle;

  const _SocialButton({
    required this.onPressed,
    required this.loading,
    required this.label,
    required this.icon,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: subtle
                  ? const Color(0xFF2D3F2D)
                  : const Color(0xFF3D4F3D)),
          backgroundColor:
              subtle ? Colors.transparent : const Color(0xFF242B24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Color(0xFF4ADE80), strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label,
                      style: TextStyle(
                          color: subtle
                              ? const Color(0xFF6B8F6B)
                              : const Color(0xFFE8F0E8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}

// ─── Icône Google ─────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1.5),
        (i * 90 - 45) * 3.14159 / 180,
        80 * 3.14159 / 180,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.butt,
      );
    }
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r - 1.5, c.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}