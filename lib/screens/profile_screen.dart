import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  bool _notificationsEnabled = true;
  bool _mqttAutoConnect = true;
  String _mqttBroker = 'broker.hivemq.com';

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242B24),
        title: const Text('Déconnexion',
            style: TextStyle(color: Color(0xFFE8F0E8))),
        content: const Text('Tu seras redirigé vers l\'écran de connexion.',
            style: TextStyle(color: Color(0xFF6B8F6B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B8F6B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_user?.email == null) return;
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de réinitialisation envoyé ✓'),
            backgroundColor: Color(0xFF2D3F2D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _editMqttBroker() {
    final ctrl = TextEditingController(text: _mqttBroker);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242B24),
        title: const Text('Broker MQTT',
            style: TextStyle(color: Color(0xFFE8F0E8))),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Color(0xFFE8F0E8)),
          decoration: const InputDecoration(
            hintText: 'broker.hivemq.com',
            hintStyle: TextStyle(color: Color(0xFF2D3F2D)),
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2D3F2D))),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4ADE80))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B8F6B))),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _mqttBroker = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1A1F1A)),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? 'Non connecté';
    final initiale = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Profil',
                style: TextStyle(
                  color: Color(0xFFE8F0E8),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // ── Avatar + email ──────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3F2D),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF4ADE80), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initiale,
                          style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 28,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      email,
                      style: const TextStyle(
                          color: Color(0xFFE8F0E8), fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text('Compte Firebase',
                        style: TextStyle(
                            color: Color(0xFF6B8F6B), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section Notifications ───────────────────────────────
              _SectionTitle('Notifications'),
              _SettingToggle(
                icon: '🔔',
                label: 'Alertes capteurs',
                subtitle: 'Température et humidité hors limites',
                value: _notificationsEnabled,
                onChanged: (v) =>
                    setState(() => _notificationsEnabled = v),
              ),
              const SizedBox(height: 16),

              // ── Section MQTT ────────────────────────────────────────
              _SectionTitle('Connexion MQTT'),
              _SettingToggle(
                icon: '🔄',
                label: 'Auto-connexion',
                subtitle: 'Reconnexion automatique au démarrage',
                value: _mqttAutoConnect,
                onChanged: (v) =>
                    setState(() => _mqttAutoConnect = v),
              ),
              const SizedBox(height: 8),
              _SettingTap(
                icon: '🌐',
                label: 'Broker MQTT',
                value: _mqttBroker,
                onTap: _editMqttBroker,
              ),
              const SizedBox(height: 16),

              // ── Section Compte ──────────────────────────────────────
              _SectionTitle('Compte'),
              _SettingTap(
                icon: '🔑',
                label: 'Changer le mot de passe',
                value: 'Par email',
                onTap: _changePassword,
              ),
              const SizedBox(height: 8),
              _SettingTap(
                icon: 'ℹ️',
                label: 'Version',
                value: '1.0.1',
                onTap: null,
              ),
              const SizedBox(height: 28),

              // ── Bouton déconnexion ──────────────────────────────────
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            color: Color(0xFF6B8F6B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF242B24),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFFE8F0E8), fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF6B8F6B), fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingTap extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SettingTap({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFFE8F0E8), fontSize: 14)),
            ),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF6B8F6B), fontSize: 13)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: Color(0xFF6B8F6B), size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
