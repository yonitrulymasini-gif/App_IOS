import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum TriggerType { time, temperature, humidity }
enum ActionType  { relayOn, relayOff }

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

  Scenario({required this.name, required this.triggerType, required this.triggerValue,
    required this.triggerOperator, this.triggerTime, required this.actionType,
    required this.relayIndex, this.durationMinutes, this.active = true});

  Map<String, dynamic> toJson() => {
    'name': name, 'triggerType': triggerType.index, 'triggerValue': triggerValue,
    'triggerOperator': triggerOperator, 'triggerHour': triggerTime?.hour,
    'triggerMinute': triggerTime?.minute, 'actionType': actionType.index,
    'relayIndex': relayIndex, 'durationMinutes': durationMinutes, 'active': active,
  };

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
    name: j['name'], triggerType: TriggerType.values[j['triggerType']],
    triggerValue: (j['triggerValue'] as num).toDouble(),
    triggerOperator: j['triggerOperator'],
    triggerTime: j['triggerHour'] != null
        ? TimeOfDay(hour: j['triggerHour'], minute: j['triggerMinute'] ?? 0) : null,
    actionType: ActionType.values[j['actionType']],
    relayIndex: j['relayIndex'], durationMinutes: j['durationMinutes'],
    active: j['active'] ?? true,
  );
}

class ScenariosScreen extends StatefulWidget {
  final String deviceId;
  final List<String> relayNames;
  final List<String> relayIcons;
  const ScenariosScreen({super.key, required this.deviceId, required this.relayNames, required this.relayIcons});
  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  List<Scenario> _list = [];
  bool _loaded = false;
  String get _key => 'scenarios_${widget.deviceId}';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    setState(() {
      if (raw.isEmpty) {
        _list = [
          Scenario(name: 'Mode nuit', triggerType: TriggerType.time, triggerValue: 0,
              triggerOperator: '==', triggerTime: const TimeOfDay(hour: 20, minute: 0),
              actionType: ActionType.relayOff, relayIndex: 0),
          Scenario(name: 'Brumisation auto', triggerType: TriggerType.humidity, triggerValue: 60,
              triggerOperator: '<', actionType: ActionType.relayOn, relayIndex: 1, durationMinutes: 5),
        ];
      } else {
        _list = raw.map((e) => Scenario.fromJson(jsonDecode(e))).toList();
      }
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _list.map((s) => jsonEncode(s.toJson())).toList());
  }

  void _delete(int i) {
    setState(() => _list.removeAt(i));
    _save();
  }

  void _add() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => _AddSheet(
        relayNames: widget.relayNames, relayIcons: widget.relayIcons,
        onAdd: (s) { setState(() => _list.add(s)); _save(); },
      ),
    );
  }

  Color _color(TriggerType t) => switch (t) {
    TriggerType.time        => T.blue,
    TriggerType.temperature => T.amber,
    TriggerType.humidity    => T.green,
  };

  IconData _icon(TriggerType t) => switch (t) {
    TriggerType.time        => Icons.access_time,
    TriggerType.temperature => Icons.thermostat,
    TriggerType.humidity    => Icons.water_drop_outlined,
  };

  String _triggerLabel(Scenario s) => switch (s.triggerType) {
    TriggerType.time => () {
      final h = s.triggerTime!.hour.toString().padLeft(2, '0');
      final m = s.triggerTime!.minute.toString().padLeft(2, '0');
      return 'À $h:$m';
    }(),
    TriggerType.temperature => 'Temp. ${s.triggerOperator} ${s.triggerValue.toInt()}°C',
    TriggerType.humidity    => 'Hygro. ${s.triggerOperator} ${s.triggerValue.toInt()}%',
  };

  String _actionLabel(Scenario s) {
    final relay = '${widget.relayIcons[s.relayIndex]} ${widget.relayNames[s.relayIndex]}';
    final action = s.actionType == ActionType.relayOn ? 'ON' : 'OFF';
    final dur = s.durationMinutes != null ? ' · ${s.durationMinutes}min' : '';
    return '$relay → $action$dur';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scénarios'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ],
      ),
      body: !_loaded
          ? const Center(child: CupertinoActivityIndicator())
          : _list.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bolt_outlined, color: T.textTertiary, size: 36),
                  const SizedBox(height: 12),
                  Text('Aucun scénario', style: T.t17.copyWith(color: T.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Appuie sur + pour créer une automatisation.',
                      style: T.t14.copyWith(color: T.textSecondary)),
                ]))
              : ListView.separated(
                  itemCount: _list.length,
                  separatorBuilder: (_, i) => const Padding(
                    padding: EdgeInsets.only(left: 46),
                    child: Divider(height: 0),
                  ),
                  itemBuilder: (_, i) {
                    final s = _list[i];
                    return Dismissible(
                      key: ValueKey('$i${s.name}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: T.red.withValues(alpha: 0.1),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: T.red, size: 20),
                      ),
                      onDismissed: (_) => _delete(i),
                      child: Opacity(
                        opacity: s.active ? 1.0 : 0.4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(children: [
                            Icon(_icon(s.triggerType), color: _color(s.triggerType), size: 18),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.name, style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('${_triggerLabel(s)}  ·  ${_actionLabel(s)}',
                                  style: T.t13.copyWith(color: T.textSecondary)),
                            ])),
                            CupertinoSwitch(
                              value: s.active,
                              onChanged: (v) { setState(() => s.active = v); _save(); },
                              activeTrackColor: T.green,
                            ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── Sheet création ───────────────────────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  final List<String> relayNames, relayIcons;
  final Function(Scenario) onAdd;
  const _AddSheet({required this.relayNames, required this.relayIcons, required this.onAdd});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _name = TextEditingController();
  TriggerType _ttype = TriggerType.time;
  double _tval = 60;
  String _tOp = '<';
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  ActionType _atype = ActionType.relayOff;
  int _relay = 0;
  bool _hasDur = false;
  int _dur = 5;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Handle(),
        Text('Nouveau scénario', style: T.t17.copyWith(color: T.textPrimary)),
        const SizedBox(height: 16),

        TextField(
          controller: _name,
          style: const TextStyle(color: T.textPrimary, fontSize: 15),
          decoration: const InputDecoration(hintText: 'Nom du scénario'),
        ),
        const SizedBox(height: 16),

        Text('Déclencheur', style: T.t12.copyWith(color: T.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        CupertinoSegmentedControl<TriggerType>(
          groupValue: _ttype,
          onValueChanged: (v) => setState(() { _ttype = v; _tval = v == TriggerType.temperature ? 25 : 60; }),
          children: const {
            TriggerType.time:        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Heure')),
            TriggerType.temperature: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Temp.')),
            TriggerType.humidity:    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Hygro.')),
          },
        ),
        const SizedBox(height: 12),

        if (_ttype == TriggerType.time)
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: T.elevated, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.access_time, color: T.textSecondary, size: 16),
                const SizedBox(width: 10),
                Text(_time.format(context), style: T.t15.copyWith(color: T.textPrimary)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: T.textTertiary, size: 16),
              ]),
            ),
          )
        else
          Column(children: [
            Row(children: [
              Container(
                decoration: BoxDecoration(color: T.elevated, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tOp,
                    dropdownColor: T.elevated,
                    style: T.t15.copyWith(color: T.textPrimary),
                    items: ['<', '>', '=='].map((o) => DropdownMenuItem(value: o, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(o),
                    ))).toList(),
                    onChanged: (v) => setState(() => _tOp = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_tval.toInt()}${_ttype == TriggerType.temperature ? '°C' : '%'}',
                style: T.t17.copyWith(color: T.textPrimary),
              ),
            ]),
            Slider(
              value: _tval,
              min: _ttype == TriggerType.temperature ? 15 : 20,
              max: _ttype == TriggerType.temperature ? 45 : 100,
              activeColor: T.green,
              inactiveColor: T.elevated,
              onChanged: (v) => setState(() => _tval = v),
            ),
          ]),

        const SizedBox(height: 16),
        Text('Action', style: T.t12.copyWith(color: T.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(color: T.elevated, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _relay, isExpanded: true,
              dropdownColor: T.elevated,
              style: T.t15.copyWith(color: T.textPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              items: List.generate(4, (i) => DropdownMenuItem(
                value: i,
                child: Text('${widget.relayIcons[i]}  ${widget.relayNames[i]}'),
              )),
              onChanged: (v) => setState(() => _relay = v!),
            ),
          ),
        ),
        const SizedBox(height: 8),

        CupertinoSegmentedControl<ActionType>(
          groupValue: _atype,
          onValueChanged: (v) => setState(() => _atype = v),
          children: const {
            ActionType.relayOn:  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Allumer')),
            ActionType.relayOff: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Éteindre')),
          },
        ),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: Text('Durée limitée', style: T.t14.copyWith(color: T.textPrimary))),
          CupertinoSwitch(value: _hasDur, onChanged: (v) => setState(() => _hasDur = v), activeTrackColor: T.green),
        ]),
        if (_hasDur) ...[
          Text('${_dur}min', style: T.t13.copyWith(color: T.textSecondary)),
          Slider(
            value: _dur.toDouble(), min: 1, max: 60,
            activeColor: T.green, inactiveColor: T.elevated,
            onChanged: (v) => setState(() => _dur = v.toInt()),
          ),
        ],
        const SizedBox(height: 16),

        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            widget.onAdd(Scenario(
              name: _name.text.trim(), triggerType: _ttype,
              triggerValue: _tval, triggerOperator: _tOp,
              triggerTime: _ttype == TriggerType.time ? _time : null,
              actionType: _atype, relayIndex: _relay,
              durationMinutes: _hasDur ? _dur : null,
            ));
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: T.green, foregroundColor: T.bg,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ]),
    ),
  );
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Container(
    width: 32, height: 4, margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: T.border, borderRadius: BorderRadius.circular(2)),
  ));
}
