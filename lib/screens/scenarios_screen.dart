import 'package:flutter/material.dart';

enum TriggerType { time, temperature, humidity }
enum ActionType { relayOn, relayOff }

class Scenario {
  String name;
  TriggerType triggerType;
  double triggerValue;
  String triggerOperator; // '>', '<', '=='
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
  List<Scenario> scenarios = [
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
    Scenario(
      name: 'Alerte chaleur',
      triggerType: TriggerType.temperature,
      triggerValue: 35,
      triggerOperator: '>',
      actionType: ActionType.relayOff,
      relayIndex: 2,
    ),
  ];

  String _triggerLabel(Scenario s) {
    switch (s.triggerType) {
      case TriggerType.time:
        final h = s.triggerTime!.hour.toString().padLeft(2, '0');
        final m = s.triggerTime!.minute.toString().padLeft(2, '0');
        return 'À $h:$m';
      case TriggerType.temperature:
        return 'Temp ${s.triggerOperator} ${s.triggerValue.toInt()}°C';
      case TriggerType.humidity:
        return 'Hygro ${s.triggerOperator} ${s.triggerValue.toInt()}%';
    }
  }

  String _actionLabel(Scenario s) {
  final relay = '${widget.relayIcons[s.relayIndex]} ${widget.relayNames[s.relayIndex]}';
  final action = s.actionType == ActionType.relayOn ? 'ON' : 'OFF';
  final duration = s.durationMinutes != null ? ' · ${s.durationMinutes} min' : '';
  return '$relay → $action$duration';
}

  void _addScenario() {
    showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => _AddScenarioSheet(
        relayNames: widget.relayNames,
        relayIcons: widget.relayIcons,
        onAdd: (scenario) {
          setState(() => scenarios.add(scenario));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scénarios')),
      body: scenarios.isEmpty
        ? const Center(child: Text('Aucun scénario — appuie sur + pour en créer un'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scenarios.length,
            itemBuilder: (ctx, i) {
              final s = scenarios[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.bolt, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(_triggerLabel(s),
                                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.arrow_forward, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(_actionLabel(s),
                                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Switch(
                            value: s.active,
                            onChanged: (v) => setState(() => s.active = v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => setState(() => scenarios.removeAt(i)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addScenario,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddScenarioSheet extends StatefulWidget {
  final List<String> relayNames;
  final List<String> relayIcons;
  final Function(Scenario) onAdd;
  const _AddScenarioSheet({required this.relayNames, required this.relayIcons, required this.onAdd});
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
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nouveau scénario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du scénario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Déclencheur', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<TriggerType>(
              segments: const [
                ButtonSegment(value: TriggerType.time, label: Text('Heure')),
                ButtonSegment(value: TriggerType.temperature, label: Text('Temp')),
                ButtonSegment(value: TriggerType.humidity, label: Text('Hygro')),
              ],
              selected: {_triggerType},
              onSelectionChanged: (v) => setState(() {
                _triggerType = v.first;
                _triggerValue = _triggerType == TriggerType.temperature ? 25 : 60;
              }),
            ),
            const SizedBox(height: 12),
            if (_triggerType == TriggerType.time)
              ListTile(
                title: Text('Heure : ${_triggerTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: _triggerTime);
                  if (t != null) setState(() => _triggerTime = t);
                },
              )
            else
              Column(children: [
                Row(children: [
                  DropdownButton<String>(
                    value: _triggerOperator,
                    items: ['<', '>', '=='].map((op) =>
                      DropdownMenuItem(value: op, child: Text(op))).toList(),
                    onChanged: (v) => setState(() => _triggerOperator = v!),
                  ),
                  const SizedBox(width: 12),
                  Text('${_triggerValue.toInt()}${_triggerType == TriggerType.temperature ? '°C' : '%'}'),
                ]),
                Slider(
                  value: _triggerValue.clamp(
                    _triggerType == TriggerType.temperature ? 15.0 : 20.0,
                    _triggerType == TriggerType.temperature ? 45.0 : 100.0,
                  ),
                  min: _triggerType == TriggerType.temperature ? 15 : 20,
                  max: _triggerType == TriggerType.temperature ? 45 : 100,
                  onChanged: (v) => setState(() => _triggerValue = v),
                ),
              ]),
            const SizedBox(height: 16),
            const Text('Action', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _relayIndex,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: List.generate(4, (i) => DropdownMenuItem(
                value: i,
                child: Text('${widget.relayIcons[i]} ${widget.relayNames[i]}'),
              )),
              onChanged: (v) => setState(() => _relayIndex = v!),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ActionType>(
              segments: const [
                ButtonSegment(value: ActionType.relayOn, label: Text('Allumer')),
                ButtonSegment(value: ActionType.relayOff, label: Text('Éteindre')),
              ],
              selected: {_actionType},
              onSelectionChanged: (v) => setState(() => _actionType = v.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Durée limitée'),
              value: _hasDuration,
              onChanged: (v) => setState(() => _hasDuration = v),
            ),
            if (_hasDuration) ...[
              Text('Durée : $_duration minutes'),
              Slider(
                value: _duration.toDouble(),
                min: 1, max: 60,
                onChanged: (v) => setState(() => _duration = v.toInt()),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_nameController.text.isEmpty) return;
                widget.onAdd(Scenario(
                  name: _nameController.text,
                  triggerType: _triggerType,
                  triggerValue: _triggerValue,
                  triggerOperator: _triggerOperator,
                  triggerTime: _triggerType == TriggerType.time ? _triggerTime : null,
                  actionType: _actionType,
                  relayIndex: _relayIndex,
                  durationMinutes: _hasDuration ? _duration : null,
                ));
              },
              child: const Text('Créer le scénario'),
            ),
          ],
        ),
      ),
    );
  }
}