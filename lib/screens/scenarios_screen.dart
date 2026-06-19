import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TriggerType { time, temperature, humidity }
enum ActionType { relayOn, relayOff }

class Scenario {
  String name;
  TriggerType triggerType;
  double triggerValue;
  String triggerOperator;
  TimeOfDay? triggerTime;
  ActionType actionType;
  int relayIndex;
  int? durationMinutes;
  bool active;

  Scenario({
    required this.name,
    required this.triggerType,
    required this.triggerValue,
    required this.triggerOperator,
    this.triggerTime,
    required this.actionType,
    required this.relayIndex,
    this.durationMinutes,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'triggerType': triggerType.index,
        'triggerValue': triggerValue,
        'triggerOperator': triggerOperator,
        'triggerHour': triggerTime?.hour,
        'triggerMinute': triggerTime?.minute,
        'actionType': actionType.index,
        'relayIndex': relayIndex,
        'durationMinutes': durationMinutes,
        'active': active,
      };

  factory Scenario.fromJson(Map<String, dynamic> json) => Scenario(
        name: json['name'],
        triggerType: TriggerType.values[json['triggerType']],
        triggerValue: (json['triggerValue'] as num).toDouble(),
        triggerOperator: json['triggerOperator'],
        triggerTime: json['triggerHour'] != null
            ? TimeOfDay(
                hour: json['triggerHour'],
                minute: json['triggerMinute'] ?? 0)
            : null,
        actionType: ActionType.values[json['actionType']],
        relayIndex: json['relayIndex'],
        durationMinutes: json['durationMinutes'],
        active: json['active'] ?? true,
      );
}

class ScenariosScreen extends StatefulWidget {
  final String deviceId;
  final List<String> relayNames;
  final List<String> relayIcons;
  const ScenariosScreen({
    super.key,
    required this.deviceId,
    required this.relayNames,
    required this.relayIcons,
  });
  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  List<Scenario> scenarios = [];
  bool _loaded = false;

  String get _prefsKey => 'scenarios_${widget.deviceId}';

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    setState(() {
      if (raw.isEmpty) {
        // Scénarios de démo
        scenarios = [
          Scenario(
            name: 'Mode nuit',
            triggerType: TriggerType.time,
            triggerValue: 0,
            triggerOperator: '==',
            triggerTime: const TimeOfDay(hour: 20, minute: 0),
            actionType: ActionType.relayOff,
            relayIndex: 0,
          ),
          Scenario(
            name: 'Brumisation auto',
            triggerType: TriggerType.humidity,
            triggerValue: 60,
            triggerOperator: '<',
            actionType: ActionType.relayOn,
            relayIndex: 1,
            durationMinutes: 5,
          ),
        ];
      } else {
        scenarios = raw
            .map((e) => Scenario.fromJson(jsonDecode(e)))
            .toList();
      }
      _loaded = true;
    });
  }

  Future<void> _saveScenarios() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      scenarios.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  String _triggerLabel(Scenario s) {
    switch (s.triggerType) {
      case TriggerType.time:
        final h = s.triggerTime!.hour.toString().padLeft(2, '0');
        final m = s.triggerTime!.minute.toString().padLeft(2, '0');
        return 'À $h:$m';
      case TriggerType.temperature:
        return 'Temp. ${s.triggerOperator} ${s.triggerValue.toInt()}°C';
      case TriggerType.humidity:
        return 'Hygro. ${s.triggerOperator} ${s.triggerValue.toInt()}%';
    }
  }

  String _actionLabel(Scenario s) {
    final relay =
        '${widget.relayIcons[s.relayIndex]} ${widget.relayNames[s.relayIndex]}';
    final action = s.actionType == ActionType.relayOn ? 'ON' : 'OFF';
    final duration =
        s.durationMinutes != null ? ' · ${s.durationMinutes} min' : '';
    return '$relay → $action$duration';
  }

  void _addScenario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddScenarioSheet(
        relayNames: widget.relayNames,
        relayIcons: widget.relayIcons,
        onAdd: (scenario) {
          setState(() => scenarios.add(scenario));
          _saveScenarios();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _deleteScenario(int index) {
    final s = scenarios[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242B24),
        title: const Text('Supprimer ?',
            style: TextStyle(color: Color(0xFFE8F0E8))),
        content: Text('Supprimer "${s.name}" ?',
            style: const TextStyle(color: Color(0xFF6B8F6B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B8F6B))),
          ),
          TextButton(
            onPressed: () {
              setState(() => scenarios.removeAt(index));
              _saveScenarios();
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Color _triggerColor(TriggerType t) => switch (t) {
        TriggerType.time => const Color(0xFF60A5FA),
        TriggerType.temperature => const Color(0xFFFB923C),
        TriggerType.humidity => const Color(0xFF4ADE80),
      };

  String _triggerIcon(TriggerType t) => switch (t) {
        TriggerType.time => '⏰',
        TriggerType.temperature => '🌡️',
        TriggerType.humidity => '💧',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scénarios')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : scenarios.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: scenarios.length,
                  itemBuilder: (ctx, i) => _ScenarioCard(
                    scenario: scenarios[i],
                    triggerLabel: _triggerLabel(scenarios[i]),
                    actionLabel: _actionLabel(scenarios[i]),
                    triggerColor: _triggerColor(scenarios[i].triggerType),
                    triggerIcon: _triggerIcon(scenarios[i].triggerType),
                    onToggle: (v) {
                      setState(() => scenarios[i].active = v);
                      _saveScenarios();
                    },
                    onDelete: () => _deleteScenario(i),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addScenario,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('Aucun scénario',
              style: TextStyle(
                  color: Color(0xFFE8F0E8),
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Automatise ton terrarium\nselon l\'heure ou les capteurs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addScenario,
            icon: const Icon(Icons.add),
            label: const Text('Créer un scénario'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF1A1F1A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte scénario ───────────────────────────────────────────────────────────
class _ScenarioCard extends StatelessWidget {
  final Scenario scenario;
  final String triggerLabel;
  final String actionLabel;
  final Color triggerColor;
  final String triggerIcon;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ScenarioCard({
    required this.scenario,
    required this.triggerLabel,
    required this.actionLabel,
    required this.triggerColor,
    required this.triggerIcon,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: scenario.active ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône déclencheur
              Container(
                width: 40,
                height: 40,
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
                    Text(scenario.name,
                        style: const TextStyle(
                            color: Color(0xFFE8F0E8),
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(triggerLabel,
                        style: TextStyle(
                            fontSize: 12, color: triggerColor)),
                    const SizedBox(height: 2),
                    Text(actionLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B8F6B))),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: scenario.active,
                    onChanged: onToggle,
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet création scénario ──────────────────────────────────────────────────
class _AddScenarioSheet extends StatefulWidget {
  final List<String> relayNames;
  final List<String> relayIcons;
  final Function(Scenario) onAdd;
  const _AddScenarioSheet({
    required this.relayNames,
    required this.relayIcons,
    required this.onAdd,
  });
  @override
  State<_AddScenarioSheet> createState() => _AddScenarioSheetState();
}

class _AddScenarioSheetState extends State<_AddScenarioSheet> {
  final _nameController = TextEditingController();
  TriggerType _triggerType = TriggerType.time;
  double _triggerValue = 60;
  String _triggerOperator = '<';
  TimeOfDay _triggerTime = const TimeOfDay(hour: 20, minute: 0);
  ActionType _actionType = ActionType.relayOff;
  int _relayIndex = 0;
  int _duration = 5;
  bool _hasDuration = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3F2D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text('Nouveau scénario',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0E8))),
            const SizedBox(height: 16),

            // Nom
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Color(0xFFE8F0E8)),
              decoration: const InputDecoration(
                labelText: 'Nom du scénario',
                labelStyle: TextStyle(color: Color(0xFF6B8F6B)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ADE80))),
                filled: true,
                fillColor: Color(0xFF242B24),
              ),
            ),
            const SizedBox(height: 16),

            // Déclencheur
            const Text('Déclencheur',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0E8))),
            const SizedBox(height: 8),
            SegmentedButton<TriggerType>(
              segments: const [
                ButtonSegment(
                    value: TriggerType.time,
                    label: Text('Heure'),
                    icon: Icon(Icons.access_time, size: 14)),
                ButtonSegment(
                    value: TriggerType.temperature,
                    label: Text('Temp.'),
                    icon: Icon(Icons.thermostat, size: 14)),
                ButtonSegment(
                    value: TriggerType.humidity,
                    label: Text('Hygro.'),
                    icon: Icon(Icons.water_drop, size: 14)),
              ],
              selected: {_triggerType},
              onSelectionChanged: (v) => setState(() {
                _triggerType = v.first;
                _triggerValue =
                    _triggerType == TriggerType.temperature ? 25 : 60;
              }),
            ),
            const SizedBox(height: 12),

            if (_triggerType == TriggerType.time)
              GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: _triggerTime);
                  if (t != null) setState(() => _triggerTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242B24),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFF2D3F2D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Color(0xFF6B8F6B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _triggerTime.format(context),
                        style: const TextStyle(
                            color: Color(0xFFE8F0E8), fontSize: 15),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF6B8F6B)),
                    ],
                  ),
                ),
              )
            else
              Column(children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242B24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2D3F2D)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _triggerOperator,
                          dropdownColor: const Color(0xFF242B24),
                          style: const TextStyle(
                              color: Color(0xFFE8F0E8)),
                          items: ['<', '>', '==']
                              .map((op) => DropdownMenuItem(
                                  value: op, child: Text(op)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _triggerOperator = v!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_triggerValue.toInt()}${_triggerType == TriggerType.temperature ? '°C' : '%'}',
                      style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Slider(
                  value: _triggerValue.clamp(
                    _triggerType == TriggerType.temperature
                        ? 15.0
                        : 20.0,
                    _triggerType == TriggerType.temperature
                        ? 45.0
                        : 100.0,
                  ),
                  min: _triggerType == TriggerType.temperature
                      ? 15
                      : 20,
                  max: _triggerType == TriggerType.temperature
                      ? 45
                      : 100,
                  activeColor: const Color(0xFF4ADE80),
                  onChanged: (v) => setState(() => _triggerValue = v),
                ),
              ]),

            const SizedBox(height: 16),
            const Text('Action',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE8F0E8))),
            const SizedBox(height: 8),

            // Choix prise
            DropdownButtonFormField<int>(
              initialValue: _relayIndex,
              dropdownColor: const Color(0xFF242B24),
              style: const TextStyle(color: Color(0xFFE8F0E8)),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ADE80))),
                filled: true,
                fillColor: Color(0xFF242B24),
              ),
              items: List.generate(
                4,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                      '${widget.relayIcons[i]} ${widget.relayNames[i]}'),
                ),
              ),
              onChanged: (v) => setState(() => _relayIndex = v!),
            ),
            const SizedBox(height: 8),

            SegmentedButton<ActionType>(
              segments: const [
                ButtonSegment(
                    value: ActionType.relayOn,
                    label: Text('Allumer'),
                    icon: Icon(Icons.power_settings_new, size: 14)),
                ButtonSegment(
                    value: ActionType.relayOff,
                    label: Text('Éteindre'),
                    icon: Icon(Icons.power_off, size: 14)),
              ],
              selected: {_actionType},
              onSelectionChanged: (v) =>
                  setState(() => _actionType = v.first),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Durée limitée',
                  style: TextStyle(color: Color(0xFFE8F0E8))),
              value: _hasDuration,
              onChanged: (v) => setState(() => _hasDuration = v),
              activeColor: const Color(0xFF4ADE80),
            ),
            if (_hasDuration) ...[
              Text(
                'Durée : $_duration minute${_duration > 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF6B8F6B)),
              ),
              Slider(
                value: _duration.toDouble(),
                min: 1,
                max: 60,
                activeColor: const Color(0xFF4ADE80),
                onChanged: (v) => setState(() => _duration = v.toInt()),
              ),
            ],
            const SizedBox(height: 16),

            FilledButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                widget.onAdd(Scenario(
                  name: _nameController.text.trim(),
                  triggerType: _triggerType,
                  triggerValue: _triggerValue,
                  triggerOperator: _triggerOperator,
                  triggerTime:
                      _triggerType == TriggerType.time ? _triggerTime : null,
                  actionType: _actionType,
                  relayIndex: _relayIndex,
                  durationMinutes: _hasDuration ? _duration : null,
                ));
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1A1F1A),
              ),
              child: const Text('Créer le scénario',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
