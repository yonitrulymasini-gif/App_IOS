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
  final List<Terrarium> terrariums = [
    Terrarium(
      id: 'terrarium_001',
      name: 'Terrarium Théo',
      animal: 'Pogona',
      emoji: '🦎',
      temperature: 28.5,
      humidity: 65,
      online: true,
    ),
  ];

  void _addTerrarium() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final idController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF242B24),
          title: const Text('Ajouter un boîtier',
            style: TextStyle(color: Color(0xFFE8F0E8))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color(0xFFE8F0E8)),
                decoration: const InputDecoration(
                  labelText: 'Nom du terrarium',
                  labelStyle: TextStyle(color: Color(0xFF6B8F6B)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ADE80))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idController,
                style: const TextStyle(color: Color(0xFFE8F0E8)),
                decoration: const InputDecoration(
                  labelText: 'ID du boîtier (ex: terrarium_001)',
                  labelStyle: TextStyle(color: Color(0xFF6B8F6B)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ADE80))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B8F6B)))),
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
              child: const Text('Ajouter')),
          ],
        );
      },
    );
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
              const Text('Bonjour 👋',
                style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Mes terrariums',
                style: TextStyle(color: Color(0xFFE8F0E8),
                  fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ...terrariums.map((t) => _TerrariumCard(
                      terrarium: t,
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(deviceId: t.id, deviceName: t.name))),
                    )),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _addTerrarium,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF2D3F2D), width: 1.5,
                            style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('+', style: TextStyle(
                              color: Color(0xFF4ADE80), fontSize: 18)),
                            SizedBox(width: 8),
                            Text('Ajouter un boîtier',
                              style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3F2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(terrarium.emoji,
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(terrarium.name,
                        style: const TextStyle(
                          color: Color(0xFFE8F0E8),
                          fontWeight: FontWeight.w500, fontSize: 15)),
                      Text(terrarium.animal,
                        style: const TextStyle(
                          color: Color(0xFF6B8F6B), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: terrarium.online
                      ? const Color(0xFF4ADE80) : const Color(0xFF6B8F6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (terrarium.temperature != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('${terrarium.temperature}°',
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 18, fontWeight: FontWeight.w500)),
                          const Text('Température',
                            style: TextStyle(
                              color: Color(0xFF6B8F6B), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('${terrarium.humidity?.toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 18, fontWeight: FontWeight.w500)),
                          const Text('Humidité',
                            style: TextStyle(
                              color: Color(0xFF6B8F6B), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}