import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class _Point { final DateTime t; final double v; _Point(this.t, this.v); }

class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});
  @override
  State<DashboardStatsScreen> createState() => _State();
}

class _State extends State<DashboardStatsScreen> {
  List<Map<String, dynamic>> _terrariums = [];
  bool _loading = true;
  List<_Point> _temp = [], _humid = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    final list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    if (list.isNotEmpty) _gen(list[0]);
    setState(() { _terrariums = list; _loading = false; });
  }

  void _gen(Map<String, dynamic> t) {
    final rng = Random(t['id'].hashCode);
    final now = DateTime.now();
    final base = (t['temperature'] as num?)?.toDouble() ?? 28.0;
    final hum  = (t['humidity'] as num?)?.toDouble() ?? 65.0;
    _temp  = List.generate(72, (i) { final dt = now.subtract(Duration(hours: 72 - i)); return _Point(dt, base + sin((dt.hour - 6) * pi / 12) * 3 + (rng.nextDouble() - 0.5) * 1.5); });
    _humid = List.generate(72, (i) { final dt = now.subtract(Duration(hours: 72 - i)); return _Point(dt, (hum + (rng.nextDouble() - 0.5) * 8).clamp(30.0, 95.0)); });
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MESURES', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Dashboard', style: T.serif(30)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      children: [
                        // Temp air
                        _SensorCard(
                          icon: Icons.thermostat_outlined, iconColor: T.gold,
                          label: 'Température air', tag: 'AM2320',
                          value: _temp.isNotEmpty ? _temp.last.v : null, unit: '°C',
                        ),
                        const SizedBox(height: 10),
                        // Sondes grid
                        Row(children: [
                          Expanded(child: _SensorCard(
                            icon: Icons.thermostat_outlined, iconColor: T.gold,
                            label: 'Sonde 1', tag: 'DS18B20',
                            value: null, unit: '°C',
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _SensorCard(
                            icon: Icons.thermostat_outlined, iconColor: T.gold,
                            label: 'Sonde 2', tag: 'DS18B20',
                            value: null, unit: '°C',
                          )),
                        ]),
                        const SizedBox(height: 10),
                        // Humidité
                        _SensorCard(
                          icon: Icons.water_drop_outlined, iconColor: T.gold,
                          label: 'Humidité', tag: 'AM2320',
                          value: _humid.isNotEmpty ? _humid.last.v : null, unit: '%',
                        ),
                        const SizedBox(height: 24),
                        Text('CONTRÔLE DES PRISES',
                            style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _RelayItem(icon: Icons.light_outlined, label: 'Lampe UV', sub: 'Prise 1'),
                        _RelayItem(icon: Icons.local_fire_department_outlined, label: 'Chauffage', sub: 'Prise 2'),
                        _RelayItem(icon: Icons.cloud_outlined, label: 'Brumisateur', sub: 'Prise 3'),
                        _RelayItem(icon: Icons.air, label: 'Ventilateur', sub: 'Prise 4'),
                        const SizedBox(height: 12),
                        Text('Connecte ton ESP32 via MQTT pour activer les données en direct',
                            style: T.t13.copyWith(color: T.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, tag;
  final double? value;
  final String unit;
  const _SensorCard({required this.icon, required this.iconColor, required this.label,
    required this.tag, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: T.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500))),
        Text(tag, style: T.t12.copyWith(color: T.textSecondary)),
      ]),
      const SizedBox(height: 10),
      value != null
          ? Text('${value!.toStringAsFixed(1)} $unit', style: T.t22.copyWith(color: T.textPrimary, fontSize: 24))
          : Row(children: [
              Container(width: 20, height: 2, color: T.textTertiary, margin: const EdgeInsets.only(right: 4)),
              Text(unit, style: T.t16.copyWith(color: T.textSecondary)),
            ]),
    ]),
  );
}

class _RelayItem extends StatefulWidget {
  final IconData icon;
  final String label, sub;
  const _RelayItem({required this.icon, required this.label, required this.sub});
  @override
  State<_RelayItem> createState() => _RelayItemState();
}

class _RelayItemState extends State<_RelayItem> {
  bool _on = false;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(16), border: Border.all(color: T.border)),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(10)),
        child: Icon(widget.icon, color: T.textSecondary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label, style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w600)),
        Text(widget.sub, style: T.t13.copyWith(color: T.textSecondary)),
      ])),
      CupertinoSwitch(value: _on, onChanged: (v) => setState(() => _on = v), activeTrackColor: T.green),
    ]),
  );
}
