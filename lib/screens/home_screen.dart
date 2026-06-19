import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
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
    'id': id, 'name': name, 'animal': animal, 'emoji': emoji,
    'temperature': temperature, 'humidity': humidity, 'online': online,
  };

  factory Terrarium.fromJson(Map<String, dynamic> j) => Terrarium(
    id: j['id'], name: j['name'],
    animal: j['animal'] ?? 'Animal', emoji: j['emoji'] ?? '🦎',
    temperature: j['temperature']?.toDouble(),
    humidity: j['humidity']?.toDouble(),
    online: j['online'] ?? false,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Terrarium> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    var list = raw.map((e) => Terrarium.fromJson(jsonDecode(e))).toList();
    if (list.isEmpty) {
      list = [
        Terrarium(id: 'terrarium_001', name: 'Terrarium Théo',
            animal: 'Pogona', emoji: '🦎',
            temperature: 28.5, humidity: 65, online: true),
      ];
      await _save(list);
    }
    setState(() { _items = list; _loaded = true; });
  }

  Future<void> _save(List<Terrarium> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('terrariums', list.map((t) => jsonEncode(t.toJson())).toList());
  }

  void _add() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => AddDeviceScreen(
      onDeviceAdded: (id, name, emoji, animal) {
        setState(() => _items.add(Terrarium(id: id, name: name, animal: animal, emoji: emoji)));
        _save(_items);
      },
    ),
  ));

  Future<void> _delete(int index) async {
    final t = _items[index];
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${t.name}" ?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _items.removeAt(index));
      _save(_items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: T.bg,
            surfaceTintColor: Colors.transparent,
            title: const Text('Mes terrariums'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: T.green, size: 24),
                onPressed: _add,
              ),
            ],
          ),
          if (!_loaded)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(child: _Empty(onAdd: _add))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: _AddRow(onTap: _add),
                    );
                  }
                  return _Row(
                    item: _items[i],
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        deviceId: _items[i].id,
                        deviceName: _items[i].name,
                      ),
                    )),
                    onDelete: () => _delete(i),
                    showDivider: i < _items.length - 1,
                  );
                },
                childCount: _items.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Row item ─────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final Terrarium item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDivider;
  const _Row({required this.item, required this.onTap, required this.onDelete, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: T.bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // Avatar emoji
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: T.elevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: T.t15.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 1),
                        Text(item.animal, style: T.t13.copyWith(color: T.textSecondary)),
                      ],
                    ),
                  ),
                  // Métriques inline
                  if (item.temperature != null) ...[
                    _Metric(value: '${item.temperature}°', color: T.green),
                    const SizedBox(width: 12),
                    _Metric(value: '${item.humidity?.toInt()}%', color: T.blue),
                    const SizedBox(width: 12),
                  ],
                  // Status dot
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: item.online ? T.green : T.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: T.textTertiary, size: 16),
                ],
              ),
            ),
            if (showDivider)
              const Padding(
                padding: EdgeInsets.only(left: 68),
                child: Divider(height: 0),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final Color color;
  const _Metric({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(value, style: T.t13.copyWith(color: color, fontWeight: FontWeight.w500));
  }
}

// ─── Add row ──────────────────────────────────────────────────────────────────
class _AddRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: T.elevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: T.green, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Ajouter un boîtier', style: T.t15.copyWith(color: T.green)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🦎', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Aucun terrarium', style: T.t17.copyWith(color: T.textPrimary)),
          const SizedBox(height: 6),
          Text('Ajoute un boîtier pour commencer.', style: T.t14.copyWith(color: T.textSecondary)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: T.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Ajouter', style: T.t14.copyWith(color: T.green, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
