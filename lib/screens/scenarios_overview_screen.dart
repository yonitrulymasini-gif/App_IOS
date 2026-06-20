import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_theme.dart';

class _Scenario {
  final IconData icon;
  final Color iconBg;
  final String name, desc;
  bool active;
  _Scenario({required this.icon, required this.iconBg, required this.name, required this.desc, this.active = true});
}

class ScenariosOverviewScreen extends StatefulWidget {
  const ScenariosOverviewScreen({super.key});
  @override
  State<ScenariosOverviewScreen> createState() => _ScenariosOverviewScreenState();
}

class _ScenariosOverviewScreenState extends State<ScenariosOverviewScreen> {
  final _scenarios = [
    _Scenario(icon: Icons.wb_sunny_outlined,  iconBg: Color(0x203DD68C), name: 'Cycle jour',      desc: 'Lampe UV ON de 8h à 20h',           active: true),
    _Scenario(icon: Icons.nightlight_outlined, iconBg: Color(0x203DD68C), name: 'Cycle nuit',      desc: 'Chauffage ON si T° < 22°C',          active: true),
    _Scenario(icon: Icons.water_drop_outlined, iconBg: Color(0x10FFFFFF), name: 'Brumisation',     desc: 'Brumisateur 30s toutes les 4h',      active: false),
    _Scenario(icon: Icons.thermostat_outlined, iconBg: Color(0x203DD68C), name: 'Alerte canicule', desc: 'Ventilateur ON si T° > 32°C',        active: true),
  ];

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
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AUTOMATISATIONS', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Scénarios', style: T.serif(30)),
                ])),
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: T.greenBtn, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Color(0xFF0A1A0F), size: 22),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: [
                  // Idée card
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: T.card2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: T.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome_outlined, color: T.gold, size: 18),
                        const SizedBox(width: 8),
                        Text('Idée', style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Les scénarios déclenchent une action sur tes prises en fonction des capteurs ou de l\'heure.',
                        style: T.t14.copyWith(color: T.textSecondary, height: 1.5),
                      ),
                    ]),
                  ),

                  Text('EXEMPLES', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  ..._scenarios.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: T.card2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: T.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: s.iconBg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(s.icon, color: s.active ? T.green : T.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w600)),
                        Text(s.desc, style: T.t13.copyWith(color: T.textSecondary)),
                      ])),
                      CupertinoSwitch(
                        value: s.active,
                        onChanged: (v) => setState(() => s.active = v),
                        activeTrackColor: T.green,
                      ),
                    ]),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
