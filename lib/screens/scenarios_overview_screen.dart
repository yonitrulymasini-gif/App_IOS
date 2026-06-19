import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vue globale des scénarios — accessible depuis le footer.
/// Agrège les scénarios de tous les terrariums enregistrés.
class ScenariosOverviewScreen extends StatefulWidget {
  const ScenariosOverviewScreen({super.key});

  @override
  State<ScenariosOverviewScreen> createState() =>
      _ScenariosOverviewScreenState();
}

class _ScenariosOverviewScreenState extends State<ScenariosOverviewScreen> {
  // { deviceId: { name, scenarios: [...] } }
  List<_DeviceScenarios> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Récupère la liste des terrariums
    final terrariumsRaw = prefs.getStringList('terrariums') ?? [];
    final result = <_DeviceScenarios>[];

    for (final t in terrariumsRaw) {
      final terrarium = jsonDecode(t) as Map<String, dynamic>;
      final id = terrarium['id'] as String;
      final name = terrarium['name'] as String;
      final emoji = terrarium['emoji'] as String? ?? '🦎';

      final scenariosRaw =
          prefs.getStringList('scenarios_$id') ?? [];
      final scenarios = scenariosRaw
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();

      result.add(_DeviceScenarios(
        deviceId: id,
        deviceName: name,
        deviceEmoji: emoji,
        scenarios: scenarios,
      ));
    }

    setState(() {
      _data = result;
      _loading = false;
    });
  }

  Future<void> _toggleScenario(
      String deviceId, int scenarioIndex, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('scenarios_$deviceId') ?? [];
    if (scenarioIndex >= raw.length) return;
    final scenario =
        jsonDecode(raw[scenarioIndex]) as Map<String, dynamic>;
    scenario['active'] = value;
    raw[scenarioIndex] = jsonEncode(scenario);
    await prefs.setStringList('scenarios_$deviceId', raw);
    await _load();
  }

  Color _triggerColor(int type) => switch (type) {
        0 => const Color(0xFF60A5FA),
        1 => const Color(0xFFFB923C),
        2 => const Color(0xFF4ADE80),
        _ => const Color(0xFF6B8F6B),
      };

  String _triggerIcon(int type) => switch (type) {
        0 => '⏰',
        1 => '🌡️',
        2 => '💧',
        _ => '❓',
      };

  String _scenarioSummary(Map<String, dynamic> s) {
    final action = s['actionType'] == 0 ? 'Allumer' : 'Éteindre';
    final relay = s['relayIndex'] as int;
    return '$action prise ${relay + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Scénarios',
                style: TextStyle(
                  color: Color(0xFFE8F0E8),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Automatisations de tous tes terrariums',
                style:
                    TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _data.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: _data.length,
                              itemBuilder: (ctx, i) =>
                                  _buildDeviceSection(_data[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSection(_DeviceScenarios device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header du terrarium
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(device.deviceEmoji,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                device.deviceName,
                style: const TextStyle(
                  color: Color(0xFF6B8F6B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        if (device.scenarios.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF242B24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF2D3F2D), size: 16),
                SizedBox(width: 8),
                Text('Aucun scénario configuré',
                    style: TextStyle(
                        color: Color(0xFF6B8F6B), fontSize: 13)),
              ],
            ),
          )
        else
          ...device.scenarios.asMap().entries.map(
                (entry) => _ScenarioTile(
                  scenario: entry.value,
                  triggerIcon: _triggerIcon(entry.value['triggerType'] as int),
                  triggerColor:
                      _triggerColor(entry.value['triggerType'] as int),
                  summary: _scenarioSummary(entry.value),
                  onToggle: (v) => _toggleScenario(
                      device.deviceId, entry.key, v),
                ),
              ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('⚡', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Aucun scénario',
            style: TextStyle(
                color: Color(0xFFE8F0E8),
                fontSize: 17,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Ouvre un terrarium pour créer\ndes automatisations.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final Map<String, dynamic> scenario;
  final String triggerIcon;
  final Color triggerColor;
  final String summary;
  final ValueChanged<bool> onToggle;

  const _ScenarioTile({
    required this.scenario,
    required this.triggerIcon,
    required this.triggerColor,
    required this.summary,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final active = scenario['active'] as bool? ?? true;
    return Opacity(
      opacity: active ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: triggerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(triggerIcon,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario['name'] as String,
                    style: const TextStyle(
                        color: Color(0xFFE8F0E8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    style: const TextStyle(
                        color: Color(0xFF6B8F6B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: active,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceScenarios {
  final String deviceId;
  final String deviceName;
  final String deviceEmoji;
  final List<Map<String, dynamic>> scenarios;

  _DeviceScenarios({
    required this.deviceId,
    required this.deviceName,
    required this.deviceEmoji,
    required this.scenarios,
  });
}
