import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'add_device_screen.dart';

class Terrarium {
  final String id;
  String name;
  String animal;
  String emoji;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'animal': animal,
        'emoji': emoji,
        'temperature': temperature,
        'humidity': humidity,
        'online': online,
      };

  factory Terrarium.fromJson(Map<String, dynamic> json) => Terrarium(
        id: json['id'],
        name: json['name'],
        animal: json['animal'] ?? 'Animal',
        emoji: json['emoji'] ?? '🦎',
        temperature: json['temperature']?.toDouble(),
        humidity: json['humidity']?.toDouble(),
        online: json['online'] ?? false,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Terrarium> terrariums = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTerrariums();
  }

  Future<void> _loadTerrariums() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    setState(() {
      terrariums =
          raw.map((e) => Terrarium.fromJson(jsonDecode(e))).toList();
      if (terrariums.isEmpty) {
        terrariums = [
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
        _saveTerrariums();
      }
      _loaded = true;
    });
  }

  Future<void> _saveTerrariums() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'terrariums',
      terrariums.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  void _addTerrarium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDeviceScreen(
          onDeviceAdded: (id, name, emoji, animal) {
            setState(() {
              terrariums.add(Terrarium(
                  id: id, name: name, animal: animal, emoji: emoji));
            });
            _saveTerrariums();
          },
        ),
      ),
    );
  }

  Future<void> _deleteTerrarium(int index) async {
    final t = terrariums[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242B24),
        title: const Text('Supprimer ?',
            style: TextStyle(color: Color(0xFFE8F0E8))),
        content: Text('Supprimer "${t.name}" de la liste ?',
            style: const TextStyle(color: Color(0xFF6B8F6B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF6B8F6B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => terrariums.removeAt(index));
      _saveTerrariums();
    }
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
              // Header
              const SizedBox(height: 8),
              const Text(
                'Bonjour 👋',
                style:
                    TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mes terrariums',
                style: TextStyle(
                    color: Color(0xFFE8F0E8),
                    fontSize: 22,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Liste
              Expanded(
                child: !_loaded
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          if (terrariums.isEmpty)
                            _EmptyState(onAdd: _addTerrarium),

                          ...terrariums.asMap().entries.map(
                                (entry) => _TerrariumCard(
                                  terrarium: entry.value,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DashboardScreen(
                                        deviceId: entry.value.id,
                                        deviceName: entry.value.name,
                                      ),
                                    ),
                                  ),
                                  onDelete: () =>
                                      _deleteTerrarium(entry.key),
                                ),
                              ),

                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: _addTerrarium,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF2D3F2D),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text('+',
                                      style: TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('Ajouter un boîtier',
                                      style: TextStyle(
                                          color: Color(0xFF6B8F6B),
                                          fontSize: 14)),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🦎', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aucun terrarium connecté',
              style: TextStyle(
                  color: Color(0xFFE8F0E8),
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text(
            'Ajoute ton premier boîtier\npour commencer à le contrôler.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un boîtier'),
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

class _TerrariumCard extends StatelessWidget {
  final Terrarium terrarium;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _TerrariumCard({
    required this.terrarium,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3F2D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(terrarium.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(terrarium.name,
                          style: const TextStyle(
                              color: Color(0xFFE8F0E8),
                              fontWeight: FontWeight.w500,
                              fontSize: 15)),
                      Text(terrarium.animal,
                          style: const TextStyle(
                              color: Color(0xFF6B8F6B),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: terrarium.online
                        ? const Color(0xFF2D3F2D)
                        : const Color(0xFF1A1F1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: terrarium.online
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF6B8F6B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        terrarium.online ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                            fontSize: 10,
                            color: terrarium.online
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF6B8F6B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (terrarium.temperature != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      value: '${terrarium.temperature}°',
                      label: 'Température',
                      color: const Color(0xFF4ADE80),
                      icon: '🌡️',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      value: '${terrarium.humidity?.toInt()}%',
                      label: 'Humidité',
                      color: const Color(0xFF60A5FA),
                      icon: '💧',
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

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String icon;
  const _StatChip(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B8F6B), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}