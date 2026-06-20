import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'dashboard_screen.dart';
import 'add_device_screen.dart';

class Terrarium {
  final String id;
  String name, animal, emoji;
  double? temperature, humidity;
  bool online;

  Terrarium({required this.id, required this.name, required this.animal,
    required this.emoji, this.temperature, this.humidity, this.online = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'animal': animal,
    'emoji': emoji, 'temperature': temperature, 'humidity': humidity, 'online': online};

  factory Terrarium.fromJson(Map<String, dynamic> j) => Terrarium(
    id: j['id'], name: j['name'], animal: j['animal'] ?? 'Animal',
    emoji: j['emoji'] ?? '🦎',
    temperature: j['temperature']?.toDouble(),
    humidity: j['humidity']?.toDouble(),
    online: j['online'] ?? false,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Terrarium> _items = [];
  bool _loaded = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    setState(() {
      _items = raw.map((e) => Terrarium.fromJson(jsonDecode(e))).toList();
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('terrariums', _items.map((t) => jsonEncode(t.toJson())).toList());
  }

  void _add() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => AddDeviceScreen(
      onDeviceAdded: (id, name, emoji, animal) {
        setState(() => _items.add(Terrarium(id: id, name: name, animal: animal, emoji: emoji)));
        _save();
      },
    ),
  ));

  Future<void> _delete(int index) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text('Supprimer "${_items[index].name}" ?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) { setState(() => _items.removeAt(index)); _save(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BONJOUR', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Yoni', style: T.serif(30)),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(21)),
                        child: const Icon(Icons.notifications_outlined, color: T.textSecondary, size: 22),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: T.gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: T.bg, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: !_loaded
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        // Terrarium cards
                        ..._items.asMap().entries.map((e) => _TerrariumCard(
                          item: e.value,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DashboardScreen(deviceId: e.value.id, deviceName: e.value.name),
                          )),
                          onDelete: () => _delete(e.key),
                        )),

                        // Prises rapides
                        if (_items.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PRISES RAPIDES', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                              Text('Tout voir', style: T.t13.copyWith(color: T.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: const [
                              _RelayQuickBtn(icon: Icons.power_settings_new_rounded, label: 'Lampe UV', status: 'Éteint'),
                              _RelayQuickBtn(icon: Icons.power_settings_new_rounded, label: 'Chauffage', status: 'Éteint'),
                              _RelayQuickBtn(icon: Icons.power_settings_new_rounded, label: 'Brumisateur', status: 'Éteint'),
                              _RelayQuickBtn(icon: Icons.power_settings_new_rounded, label: 'Ventilateur', status: 'Éteint'),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Add card
                        _AddTerrariumCard(onTap: _add),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerrariumCard extends StatelessWidget {
  final Terrarium item;
  final VoidCallback onTap, onDelete;
  const _TerrariumCard({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: T.card2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: T.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: item.online ? T.green : T.textTertiary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(item.online ? 'En ligne' : 'Hors ligne',
                      style: T.t13.copyWith(color: item.online ? T.green : T.textSecondary)),
                ]),
                const Spacer(),
                Text('Terrarium #1', style: T.t13.copyWith(color: T.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.eco_outlined, color: T.green, size: 22),
              const SizedBox(width: 8),
              Text(item.name, style: T.serif(22)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _MetricBox(
                icon: Icons.thermostat_outlined,
                label: 'TEMPÉRATURE',
                value: item.temperature != null ? '${item.temperature}' : null,
                unit: '°C',
                iconColor: T.gold,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MetricBox(
                icon: Icons.water_drop_outlined,
                label: 'HUMIDITÉ',
                value: item.humidity != null ? '${item.humidity?.toInt()}' : null,
                unit: '%',
                iconColor: T.gold,
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String unit;
  final Color iconColor;
  const _MetricBox({required this.icon, required this.label, this.value, required this.unit, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 5),
            Text(label, style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          value != null
              ? Text('$value $unit', style: T.t22.copyWith(color: T.textPrimary))
              : Row(children: [
                  Container(width: 20, height: 2, color: T.textTertiary, margin: const EdgeInsets.only(right: 4)),
                  Text(unit, style: T.t16.copyWith(color: T.textSecondary)),
                ]),
        ],
      ),
    );
  }
}

class _RelayQuickBtn extends StatelessWidget {
  final IconData icon;
  final String label, status;
  const _RelayQuickBtn({required this.icon, required this.label, required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(14), border: Border.all(color: T.border)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: T.textSecondary, size: 18),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w600)),
            Text(status, style: T.t12.copyWith(color: T.textSecondary)),
          ],
        ),
      ],
    ),
  );
}

class _AddTerrariumCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTerrariumCard({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: T.border)),
    child: Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: T.green.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.add, color: T.green, size: 24),
        ),
        const SizedBox(height: 12),
        Text('Ajoute ton premier terrarium', style: T.serif(20), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('Connecte ton ESP32 pour démarrer la surveillance',
            style: T.t14.copyWith(color: T.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(color: T.greenBtn, borderRadius: BorderRadius.circular(24)),
            child: Text('Configurer', style: T.t15.copyWith(color: const Color(0xFF0A1A0F), fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}
