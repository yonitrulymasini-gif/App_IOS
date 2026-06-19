import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  bool _notifs = true;
  bool _autoConnect = true;
  String _broker = 'broker.hivemq.com';

  Future<void> _signOut() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
    }
  }

  Future<void> _resetPassword() async {
    if (_user?.email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: _user!.email!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email envoyé')));
  }

  void _editBroker() {
    final ctrl = TextEditingController(text: _broker);
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Broker MQTT'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(controller: ctrl, placeholder: 'broker.hivemq.com'),
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () { setState(() => _broker = ctrl.text.trim()); Navigator.pop(context); },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'Invité';
    final initial = email[0].toUpperCase();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Profil'), backgroundColor: T.bg, surfaceTintColor: Colors.transparent),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Avatar ──────────────────────────────────────────────
                const SizedBox(height: 24),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: T.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(initial,
                      style: T.t22.copyWith(color: T.green, fontSize: 22))),
                ),
                const SizedBox(height: 10),
                Text(email, style: T.t15.copyWith(color: T.textPrimary)),
                const SizedBox(height: 4),
                Text(_user?.isAnonymous == true ? 'Compte invité' : 'Compte Firebase',
                    style: T.t13.copyWith(color: T.textSecondary)),
                const SizedBox(height: 32),

                // ── Section Notifications ────────────────────────────────
                _SectionHeader('NOTIFICATIONS'),
                _ToggleRow(label: 'Alertes capteurs', value: _notifs,
                    onChanged: (v) => setState(() => _notifs = v)),
                const Divider(height: 0, indent: 16),

                // ── Section Connexion ────────────────────────────────────
                const SizedBox(height: 24),
                _SectionHeader('CONNEXION MQTT'),
                _ToggleRow(label: 'Auto-connexion', value: _autoConnect,
                    onChanged: (v) => setState(() => _autoConnect = v)),
                const Divider(height: 0, indent: 16),
                _TapRow(label: 'Broker', value: _broker, onTap: _editBroker),

                // ── Section Compte ───────────────────────────────────────
                const SizedBox(height: 24),
                _SectionHeader('COMPTE'),
                _TapRow(label: 'Changer le mot de passe', onTap: _resetPassword),
                const Divider(height: 0, indent: 16),
                _TapRow(label: 'Version', value: '1.0.1', onTap: null),

                // ── Déconnexion ──────────────────────────────────────────
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _signOut,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: T.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Se déconnecter',
                          textAlign: TextAlign.center,
                          style: T.t15.copyWith(color: T.red, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: T.t12.copyWith(color: T.textSecondary, letterSpacing: 0.5)),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: T.t15.copyWith(color: T.textPrimary))),
      CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: T.green),
    ]),
  );
}

class _TapRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _TapRow({required this.label, this.value, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(child: Text(label, style: T.t15.copyWith(color: T.textPrimary))),
        if (value != null)
          Text(value!, style: T.t15.copyWith(color: T.textSecondary)),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: T.textTertiary, size: 16),
        ],
      ]),
    ),
  );
}
