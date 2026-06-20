import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
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
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()), (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Invité';
    final name  = user?.displayName ?? email.split('@').first;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'Y';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PROFIL', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Mon compte', style: T.serif(30)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  // User card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: T.border)),
                    child: Row(children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF4A8A5A), Color(0xFF6AB07A)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(initial, style: T.serif(24, c: Colors.white))),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: T.t17.copyWith(color: T.textPrimary)),
                        const SizedBox(height: 2),
                        Text(email, style: T.t13.copyWith(color: T.textSecondary)),
                      ]),
                    ]),
                  ),

                  _ProfileItem(icon: Icons.memory_outlined,   label: 'Mes appareils', sub: '0 ESP32 connecté'),
                  _ProfileItem(icon: Icons.settings_outlined, label: 'Paramètres',     sub: 'Notifications, unités'),
                  _ProfileItem(icon: Icons.help_outline,      label: 'Aide',           sub: 'Guide ESP32, MQTT, FAQ'),

                  const SizedBox(height: 8),

                  // Logout
                  GestureDetector(
                    onTap: () => _signOut(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: T.redBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: T.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.logout_rounded, color: T.red, size: 20),
                        const SizedBox(width: 8),
                        Text('Se déconnecter', style: T.t16.copyWith(color: T.red, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Version
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.eco_outlined, color: T.green, size: 14),
                    const SizedBox(width: 6),
                    Text('Terra · v0.1', style: T.t13.copyWith(color: T.textSecondary)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  const _ProfileItem({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(16), border: Border.all(color: T.border)),
    child: Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: T.textSecondary, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
        Text(sub, style: T.t13.copyWith(color: T.textSecondary)),
      ])),
      const Icon(Icons.chevron_right, color: T.textTertiary, size: 18),
    ]),
  );
}
