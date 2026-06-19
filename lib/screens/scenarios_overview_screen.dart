import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ScenariosOverviewScreen extends StatefulWidget {
  const ScenariosOverviewScreen({super.key});
  @override
  State<ScenariosOverviewScreen> createState() => _ScenariosOverviewScreenState();
}

class _ScenariosOverviewScreenState extends State<ScenariosOverviewScreen> {
  List<_DS> _data = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    final result = <_DS>[];
    for (final t in raw) {
      final ter = jsonDecode(t) as Map<String, dynamic>;
      final id   = ter['id'] as String;
      final sraw = prefs.getStringList('scenarios_$id') ?? [];
      result.add(_DS(
        id: id,
        name: ter['name'] as String,
        emoji: ter['emoji'] as String? ?? '🦎',
        scenarios: sraw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList(),
      ));
    }
    setState(() { _data = result; _loading = false; });
  }

  Future<void> _toggle(String deviceId, int idx, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('scenarios_$deviceId') ?? [];
    if (idx >= raw.length) return;
    final s = jsonDecode(raw[idx]) as Map<String, dynamic>;
    s['active'] = v;
    raw[idx] = jsonEncode(s);
    await prefs.setStringList('scenarios_$deviceId', raw);
    _load();
  }

  static Color _color(int type) => [T.blue, T.amber, T.green][type.clamp(0, 2)];
  static IconData _icon(int type) => [Icons.access_time, Icons.thermostat, Icons.water_drop][type.clamp(0, 2)];

  String _summary(Map<String, dynamic> s) {
    final action = s['actionType'] == 0 ? 'Allumer' : 'Éteindre';
    final relay = (s['relayIndex'] as int) + 1;
    return '$action prise $relay';
  }

  @override
  Widget build(BuildContext context) {
    final allEmpty = _data.every((d) => d.scenarios.isEmpty);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Scénarios'),
              backgroundColor: T.bg, surfaceTintColor: Colors.transparent),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
          else if (allEmpty || _data.isEmpty)
            SliverFillRemaining(child: _Empty())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((ctx, di) {
                final device = _data[di];
                if (device.scenarios.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text('${device.emoji}  ${device.name}',
                          style: T.t12.copyWith(color: T.textSecondary, letterSpacing: 0.3)),
                    ),
                    ...device.scenarios.asMap().entries.map((e) {
                      final s = e.value;
                      final active = s['active'] as bool? ?? true;
                      final type = s['triggerType'] as int? ?? 0;
                      final isLast = e.key == device.scenarios.length - 1;
                      return Column(children: [
                        Opacity(
                          opacity: active ? 1.0 : 0.4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              Icon(_icon(type), color: _color(type), size: 18),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'] as String,
                                      style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
                                  Text(_summary(s), style: T.t13.copyWith(color: T.textSecondary)),
                                ],
                              )),
                              CupertinoSwitch(
                                value: active,
                                onChanged: (v) => _toggle(device.id, e.key, v),
                                activeTrackColor: T.green,
                              ),
                            ]),
                          ),
                        ),
                        if (!isLast) const Padding(
                          padding: EdgeInsets.only(left: 46),
                          child: Divider(height: 0),
                        ),
                      ]);
                    }),
                  ],
                );
              }, childCount: _data.length),
            ),
        ],
      ),
    );
  }
}

class _DS {
  final String id, name, emoji;
  final List<Map<String, dynamic>> scenarios;
  _DS({required this.id, required this.name, required this.emoji, required this.scenarios});
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.bolt_outlined, color: T.textTertiary, size: 36),
      const SizedBox(height: 12),
      Text('Aucun scénario', style: T.t17.copyWith(color: T.textPrimary)),
      const SizedBox(height: 6),
      Text('Configure des automatisations\ndepuis un terrarium.',
          textAlign: TextAlign.center, style: T.t14.copyWith(color: T.textSecondary)),
    ]),
  );
}
