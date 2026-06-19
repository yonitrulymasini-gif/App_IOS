import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scenarios_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  const DashboardScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MqttServerClient client;
  List<bool> relayStates = [false, false, false, false];
  List<String> relayNames = ['Prise 1', 'Prise 2', 'Prise 3', 'Prise 4'];
  List<String> relayIcons = ['🔌', '🔌', '🔌', '🔌'];
  bool connected = false;
  bool _connecting = true;

  final List<Map<String, String>> availableIcons = [
    {'icon': '💡', 'label': 'LED'},
    {'icon': '💧', 'label': 'Brumisateur'},
    {'icon': '🔥', 'label': 'Chauffage'},
    {'icon': '🌀', 'label': 'Ventilateur'},
    {'icon': '📷', 'label': 'Caméra'},
    {'icon': '🔌', 'label': 'Autre'},
  ];

  // ── Clé de persistance par device ──────────────────────────────────────────
  String get _prefsKey => 'relays_${widget.deviceId}';

  @override
  void initState() {
    super.initState();
    _loadRelayConfig().then((_) => connectMQTT());
  }

  Future<void> _loadRelayConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        relayNames = List<String>.from(data['names'] ?? relayNames);
        relayIcons = List<String>.from(data['icons'] ?? relayIcons);
      });
    }
  }

  Future<void> _saveRelayConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({'names': relayNames, 'icons': relayIcons}),
    );
  }

  void _editRelay(int index) {
    final nameController = TextEditingController(text: relayNames[index]);
    String selectedIcon = relayIcons[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242B24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const Text('Personnaliser la prise',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8F0E8))),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color(0xFFE8F0E8)),
                decoration: const InputDecoration(
                  labelText: 'Nom de la prise',
                  labelStyle: TextStyle(color: Color(0xFF6B8F6B)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4ADE80))),
                  filled: true,
                  fillColor: Color(0xFF1A1F1A),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Icône',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE8F0E8))),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availableIcons
                      .map((item) => GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedIcon = item['icon']!),
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1F1A),
                                border: Border.all(
                                  color: selectedIcon == item['icon']
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF2D3F2D),
                                  width: selectedIcon == item['icon'] ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(item['icon']!,
                                      style:
                                          const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(item['label']!,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF6B8F6B)),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    relayNames[index] = nameController.text.isEmpty
                        ? 'Prise ${index + 1}'
                        : nameController.text;
                    relayIcons[index] = selectedIcon;
                  });
                  _saveRelayConfig(); // FIXED: persistence
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: const Color(0xFF1A1F1A),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> connectMQTT() async {
    setState(() => _connecting = true);
    client = MqttServerClient(
      'broker.hivemq.com',
      'terrarium_app_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.connectTimeoutPeriod = 5000;
    client.onDisconnected = () {
      if (mounted) setState(() => connected = false);
    };

    try {
      await client.connect();
      if (mounted) setState(() { connected = true; _connecting = false; });
      for (int i = 0; i < 4; i++) {
        client.subscribe(
            '${widget.deviceId}/relay/$i/state', MqttQos.atLeastOnce);
      }
      client.updates!.listen((messages) {
        for (var msg in messages) {
          final topic = msg.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
              (msg.payload as MqttPublishMessage).payload.message);
          for (int i = 0; i < 4; i++) {
            if (topic == '${widget.deviceId}/relay/$i/state') {
              if (mounted) setState(() => relayStates[i] = payload == 'ON');
            }
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() { connected = false; _connecting = false; });
    }
  }

  void toggleRelay(int index) {
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.wifi_off, color: Color(0xFF6B8F6B), size: 16),
            SizedBox(width: 8),
            Text('Boîtier hors ligne'),
          ]),
          backgroundColor: Color(0xFF242B24),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final newState = !relayStates[index];
    final builder = MqttClientPayloadBuilder();
    builder.addString(newState ? 'ON' : 'OFF');
    client.publishMessage(
      '${widget.deviceId}/relay/$index/set',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    setState(() => relayStates[index] = newState);
  }

  @override
  void dispose() {
    try { client.disconnect(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
        actions: [
          // Statut connexion cliquable (reconnect)
          GestureDetector(
            onTap: connected ? null : connectMQTT,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: connected
                    ? const Color(0xFF2D3F2D)
                    : const Color(0xFF1A1F1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: connected
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF2D3F2D),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_connecting)
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF6B8F6B)),
                    )
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: connected
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF6B8F6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 5),
                  Text(
                    _connecting
                        ? 'Connexion…'
                        : connected
                            ? 'En ligne'
                            : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 11,
                      color: connected
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF6B8F6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scénarios
          IconButton(
            icon: const Icon(Icons.auto_awesome,
                color: Color(0xFF6B8F6B)),
            tooltip: 'Scénarios',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScenariosScreen(
                  deviceId: widget.deviceId,
                  relayNames: relayNames,
                  relayIcons: relayIcons,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (i) => _RelayCard(
              name: relayNames[i],
              icon: relayIcons[i],
              state: relayStates[i],
              connected: connected,
              onToggle: () => toggleRelay(i),
              onEdit: () => _editRelay(i),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Carte relai ──────────────────────────────────────────────────────────────
class _RelayCard extends StatelessWidget {
  final String name;
  final String icon;
  final bool state;
  final bool connected;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _RelayCard({
    required this.name,
    required this.icon,
    required this.state,
    required this.connected,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF242B24),
        borderRadius: BorderRadius.circular(14),
        border: state
            ? Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Icône avec glow si allumé
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: state
                  ? const Color(0xFF2D3F2D)
                  : const Color(0xFF1E261E),
              borderRadius: BorderRadius.circular(10),
              boxShadow: state
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: Color(0xFFE8F0E8),
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF6B8F6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      state ? 'Allumé' : 'Éteint',
                      style: TextStyle(
                          fontSize: 11,
                          color: state
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF6B8F6B)),
                    ),
                    if (!connected) ...[
                      const SizedBox(width: 8),
                      const Text('· hors ligne',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B8F6B))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: Color(0xFF6B8F6B)),
            onPressed: onEdit,
          ),
          Switch(
            value: state,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}
