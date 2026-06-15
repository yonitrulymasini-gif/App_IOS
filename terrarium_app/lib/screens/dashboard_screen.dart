import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'scenarios_screen.dart';


class DashboardScreen extends StatefulWidget {
  final String deviceId;
  const DashboardScreen({super.key, required this.deviceId});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late MqttServerClient client;
  List<bool> relayStates = [false, false, false, false];
  List<String> relayNames = ['Prise 1', 'Prise 2', 'Prise 3', 'Prise 4'];
  List<String> relayIcons = ['🔌', '🔌', '🔌', '🔌'];
  bool connected = false;

final List<Map<String, String>> availableIcons = [
  {'icon': '💡', 'label': 'LED'},
  {'icon': '💧', 'label': 'Brumisateur'},
  {'icon': '🔥', 'label': 'Chauffage'},
  {'icon': '🌀', 'label': 'Ventilateur'},
  {'icon': '📷', 'label': 'Caméra'},
  {'icon': '🔌', 'label': 'Autre'},
];

void _editRelay(int index) {
  final nameController = TextEditingController(text: relayNames[index]);
  String selectedIcon = relayIcons[index];

  showModalBottomSheet(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Personnaliser la prise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la prise',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Icône', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableIcons.map((item) => GestureDetector(
                  onTap: () => setModalState(() => selectedIcon = item['icon']!),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedIcon == item['icon']
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                        width: selectedIcon == item['icon'] ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(item['label']!,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )).toList(),
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
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    ),
  );
}  

  @override
  void initState() {
    super.initState();
    connectMQTT();
  }

  Future<void> connectMQTT() async {
    client = MqttServerClient('broker.hivemq.com', 'terrarium_app_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.onDisconnected = () => setState(() => connected = false);

    try {
      await client.connect();
      setState(() => connected = true);

      for (int i = 0; i < 4; i++) {
        client.subscribe('${widget.deviceId}/relay/$i/state', MqttQos.atLeastOnce);
      }

      client.updates!.listen((messages) {
        for (var msg in messages) {
          final topic = msg.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            (msg.payload as MqttPublishMessage).payload.message
          );
          for (int i = 0; i < 4; i++) {
            if (topic == '${widget.deviceId}/relay/$i/state') {
              setState(() => relayStates[i] = payload == 'ON');
            }
          }
        }
      });
    } catch (e) {
      setState(() => connected = false);
    }
  }

  void toggleRelay(int index) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(widget.deviceId),
      actions: [
        IconButton(
      icon: const Icon(Icons.auto_awesome),
      onPressed: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ScenariosScreen(
          deviceId: widget.deviceId,
          relayNames: relayNames,
          relayIcons: relayIcons,
        ),
      )),
    ),
  ],
),
      body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: List.generate(4, (i) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: GestureDetector(
          onTap: () => _editRelay(i),
          child: Text(relayIcons[i], style: const TextStyle(fontSize: 28)),
        ),
        title: Text(relayNames[i]),
        subtitle: Text(
          relayStates[i] ? 'Allumé' : 'Éteint',
          style: TextStyle(
            fontSize: 12,
            color: relayStates[i] ? Colors.green : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              onPressed: () => _editRelay(i),
            ),
            Switch(
              value: relayStates[i],
              onChanged: connected ? (_) => toggleRelay(i) : null,
            ),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }
}