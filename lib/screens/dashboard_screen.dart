import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'scenarios_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  const DashboardScreen({super.key, required this.deviceId, required this.deviceName});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MqttServerClient _client;
  final _states = [false, false, false, false];
  var _names  = ['Prise 1', 'Prise 2', 'Prise 3', 'Prise 4'];
  var _icons  = ['🔌', '🔌', '🔌', '🔌'];
  bool _connected = false;
  bool _connecting = true;

  String get _key => 'relays_${widget.deviceId}';

  static const _availableIcons = [
    ('💡', 'LED'), ('💧', 'Brumisateur'), ('🔥', 'Chauffage'),
    ('🌀', 'Ventilateur'), ('📷', 'Caméra'), ('🔌', 'Autre'),
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig().then((_) => _connect());
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _names = List<String>.from(d['names'] ?? _names);
        _icons = List<String>.from(d['icons'] ?? _icons);
      });
    }
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'names': _names, 'icons': _icons}));
  }

  Future<void> _connect() async {
    _client = MqttServerClient('broker.hivemq.com',
        'terrarium_${DateTime.now().millisecondsSinceEpoch}');
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 5000;
    _client.onDisconnected = () { if (mounted) setState(() => _connected = false); };
    try {
      await _client.connect();
      if (mounted) setState(() { _connected = true; _connecting = false; });
      for (int i = 0; i < 4; i++) {
        _client.subscribe('${widget.deviceId}/relay/$i/state', MqttQos.atLeastOnce);
      }
      _client.updates?.listen((msgs) {
        for (final m in msgs) {
          final payload = MqttPublishPayload.bytesToStringAsString(
              (m.payload as MqttPublishMessage).payload.message);
          for (int i = 0; i < 4; i++) {
            if (m.topic == '${widget.deviceId}/relay/$i/state') {
              if (mounted) setState(() => _states[i] = payload == 'ON');
            }
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() { _connected = false; _connecting = false; });
    }
  }

  void _toggle(int i) {
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boîtier hors ligne'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final next = !_states[i];
    final b = MqttClientPayloadBuilder()..addString(next ? 'ON' : 'OFF');
    _client.publishMessage('${widget.deviceId}/relay/$i/set', MqttQos.atLeastOnce, b.payload!);
    setState(() => _states[i] = next);
  }

  void _editRelay(int index) {
    final ctrl = TextEditingController(text: _names[index]);
    String selIcon = _icons[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(),
              const SizedBox(height: 4),
              Text('Personnaliser', style: T.t17.copyWith(color: T.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: ctrl, style: const TextStyle(color: T.textPrimary),
                  decoration: const InputDecoration(hintText: 'Nom de la prise')),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableIcons.map((t) {
                    final (ico, lbl) = t;
                    final sel = selIcon == ico;
                    return GestureDetector(
                      onTap: () => setS(() => selIcon = ico),
                      child: Container(
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? T.green.withValues(alpha: 0.12) : T.elevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sel ? T.green : Colors.transparent),
                        ),
                        child: Column(children: [
                          Text(ico, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(lbl, style: T.t12.copyWith(color: T.textSecondary), textAlign: TextAlign.center),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _names[index] = ctrl.text.isEmpty ? 'Prise ${index + 1}' : ctrl.text;
                    _icons[index] = selIcon;
                  });
                  _saveConfig();
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: T.green, foregroundColor: T.bg,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try { _client.disconnect(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
        actions: [
          // Statut connexion
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _connecting
                      ? T.amber
                      : _connected ? T.green : T.textTertiary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bolt_outlined),
            tooltip: 'Scénarios',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ScenariosScreen(
                deviceId: widget.deviceId,
                relayNames: _names,
                relayIcons: _icons,
              ),
            )),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: 4,
        separatorBuilder: (_, i) => const Padding(
          padding: EdgeInsets.only(left: 68),
          child: Divider(height: 0),
        ),
        itemBuilder: (_, i) => _RelayRow(
          name: _names[i],
          icon: _icons[i],
          on: _states[i],
          connected: _connected,
          onToggle: () => _toggle(i),
          onEdit: () => _editRelay(i),
        ),
      ),
    );
  }
}

class _RelayRow extends StatelessWidget {
  final String name, icon;
  final bool on, connected;
  final VoidCallback onToggle, onEdit;
  const _RelayRow({required this.name, required this.icon, required this.on,
    required this.connected, required this.onToggle, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: on ? T.green.withValues(alpha: 0.12) : T.elevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
                Text(
                  on ? 'Allumé' : (connected ? 'Éteint' : 'Hors ligne'),
                  style: T.t13.copyWith(color: on ? T.green : T.textSecondary),
                ),
              ],
            )),
            CupertinoSwitch(
              value: on,
              onChanged: (_) => onToggle(),
              activeTrackColor: T.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: T.border, borderRadius: BorderRadius.circular(2)),
    ),
  );
}
