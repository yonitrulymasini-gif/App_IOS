import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class Terrarium {
  final String id;
  final String name;
  final String animal;
  final String emoji;
  double? temperature;
  double? humidity;
  bool online;

  Terrarium({
    required this.id,
    required this.name,
    required this.animal,
    required this.emoji,
    this.temperature,
    this.humidity,
    this.online = false,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pour l'instant les terrariums sont en dur
  // Plus tard ils viendront de ton backend
  final List<Terrarium> terrariums = [
    Terrarium(
      id: 'terrarium_001',
      name: 'Terrarium Victor',
      animal: 'Pogona',
      emoji: '🦎',
      temperature: 28.5,
      humidity: 65,
      online: true,
    ),
  ];

  void _addTerrarium() {
    // Dialog pour ajouter un boîtier
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final idController = TextEditingController();
        return AlertDialog(
          title: const Text('Ajouter un boîtier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom (ex: Terrarium Victor)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID du boîtier (ex: terrarium_001)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && idController.text.isNotEmpty) {
                  setState(() {
                    terrariums.add(Terrarium(
                      id: idController.text,
                      name: nameController.text,
                      animal: 'Animal',
                      emoji: '🐾',
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes terrariums'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...terrariums.map((t) => _TerrariumCard(
            terrarium: t,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardScreen(deviceId: t.id),
              ),
            ),
          )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addTerrarium,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un boîtier'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerrariumCard extends StatelessWidget {
  final Terrarium terrarium;
  final VoidCallback onTap;

  const _TerrariumCard({required this.terrarium, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(terrarium.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(terrarium.name,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                    Text(terrarium.animal,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    if (terrarium.temperature != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${terrarium.temperature}°C · ${terrarium.humidity?.toInt()}%',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ]
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                size: 10,
                color: terrarium.online ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}