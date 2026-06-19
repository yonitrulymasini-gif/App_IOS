import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modèle de données historiques ───────────────────────────────────────────
class _DataPoint {
  final DateTime time;
  final double value;
  _DataPoint(this.time, this.value);
}

class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  List<Map<String, dynamic>> _terrariums = [];
  String? _selectedId;
  String _selectedName = '';
  String _selectedEmoji = '🦎';
  bool _loading = true;

  // Données simulées (à remplacer par MQTT historique)
  late List<_DataPoint> _tempHistory;
  late List<_DataPoint> _humidHistory;

  int _rangeHours = 24;

  @override
  void initState() {
    super.initState();
    _loadTerrariums();
  }

  Future<void> _loadTerrariums() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    setState(() {
      _terrariums = list;
      if (list.isNotEmpty) {
        _selectedId = list[0]['id'];
        _selectedName = list[0]['name'];
        _selectedEmoji = list[0]['emoji'] ?? '🦎';
        _generateFakeHistory(list[0]);
      }
      _loading = false;
    });
  }

  void _generateFakeHistory(Map<String, dynamic> t) {
    final rng = Random(t['id'].hashCode);
    final now = DateTime.now();
    final baseTemp = (t['temperature'] as num?)?.toDouble() ?? 28.0;
    final baseHumid = (t['humidity'] as num?)?.toDouble() ?? 65.0;

    _tempHistory = List.generate(72, (i) {
      final time = now.subtract(Duration(hours: 72 - i));
      // Cycle jour/nuit + bruit
      final dayPhase = sin((time.hour - 6) * pi / 12);
      final noise = (rng.nextDouble() - 0.5) * 1.5;
      return _DataPoint(time, baseTemp + dayPhase * 3 + noise);
    });

    _humidHistory = List.generate(72, (i) {
      final time = now.subtract(Duration(hours: 72 - i));
      final noise = (rng.nextDouble() - 0.5) * 8;
      return _DataPoint(time, (baseHumid + noise).clamp(30, 95));
    });
  }

  List<_DataPoint> _filtered(List<_DataPoint> data) {
    final cutoff =
        DateTime.now().subtract(Duration(hours: _rangeHours));
    return data.where((d) => d.time.isAfter(cutoff)).toList();
  }

  double _avg(List<_DataPoint> data) {
    if (data.isEmpty) return 0;
    return data.map((d) => d.value).reduce((a, b) => a + b) /
        data.length;
  }

  double _min(List<_DataPoint> data) =>
      data.isEmpty ? 0 : data.map((d) => d.value).reduce(min);
  double _max(List<_DataPoint> data) =>
      data.isEmpty ? 0 : data.map((d) => d.value).reduce(max);

  @override
  Widget build(BuildContext context) {
    final filteredTemp = _filtered(_tempHistory);
    final filteredHumid = _filtered(_humidHistory);

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _terrariums.isEmpty
                ? _buildEmpty()
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: Color(0xFFE8F0E8),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Historique des capteurs',
                                style: TextStyle(
                                    color: Color(0xFF6B8F6B), fontSize: 13),
                              ),
                              const SizedBox(height: 16),

                              // Sélecteur terrarium
                              if (_terrariums.length > 1)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _terrariums.map((t) {
                                      final sel = t['id'] == _selectedId;
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedId = t['id'];
                                          _selectedName = t['name'];
                                          _selectedEmoji =
                                              t['emoji'] ?? '🦎';
                                          _generateFakeHistory(t);
                                        }),
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: sel
                                                ? const Color(0xFF2D3F2D)
                                                : const Color(0xFF242B24),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: sel
                                                ? Border.all(
                                                    color: const Color(
                                                        0xFF4ADE80))
                                                : null,
                                          ),
                                          child: Row(children: [
                                            Text(t['emoji'] ?? '🦎',
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                            const SizedBox(width: 6),
                                            Text(
                                              t['name'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: sel
                                                    ? const Color(0xFF4ADE80)
                                                    : const Color(0xFF6B8F6B),
                                                fontWeight: sel
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ]),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Sélecteur plage temporelle
                              Row(
                                children: [6, 24, 48, 72].map((h) {
                                  final sel = _rangeHours == h;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _rangeHours = h),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF4ADE80)
                                            : const Color(0xFF242B24),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${h}h',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: sel
                                              ? const Color(0xFF1A1F1A)
                                              : const Color(0xFF6B8F6B),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // ── Stats rapides ─────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _StatCard(
                                icon: '🌡️',
                                label: 'Temp. moy.',
                                value:
                                    '${_avg(filteredTemp).toStringAsFixed(1)}°C',
                                color: const Color(0xFF4ADE80),
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: '🔺',
                                label: 'Temp. max',
                                value:
                                    '${_max(filteredTemp).toStringAsFixed(1)}°C',
                                color: const Color(0xFFFB923C),
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: '🔻',
                                label: 'Temp. min',
                                value:
                                    '${_min(filteredTemp).toStringAsFixed(1)}°C',
                                color: const Color(0xFF60A5FA),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _StatCard(
                                icon: '💧',
                                label: 'Hygro. moy.',
                                value:
                                    '${_avg(filteredHumid).toStringAsFixed(0)}%',
                                color: const Color(0xFF60A5FA),
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: '🔺',
                                label: 'Hygro. max',
                                value:
                                    '${_max(filteredHumid).toStringAsFixed(0)}%',
                                color: const Color(0xFFFB923C),
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: '🔻',
                                label: 'Hygro. min',
                                value:
                                    '${_min(filteredHumid).toStringAsFixed(0)}%',
                                color: const Color(0xFF4ADE80),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // ── Graphique Température ─────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _ChartCard(
                            title: 'Température',
                            unit: '°C',
                            color: const Color(0xFF4ADE80),
                            data: filteredTemp,
                            minY: 15,
                            maxY: 45,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      // ── Graphique Humidité ────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: _ChartCard(
                            title: 'Humidité',
                            unit: '%',
                            color: const Color(0xFF60A5FA),
                            data: filteredHumid,
                            minY: 20,
                            maxY: 100,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📊', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Aucun terrarium',
              style: TextStyle(
                  color: Color(0xFFE8F0E8),
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text(
            'Ajoute un terrarium depuis\nl\'onglet Accueil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B8F6B), fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Chart card ──────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Color color;
  final List<_DataPoint> data;
  final double minY;
  final double maxY;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.data,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final current =
        data.isNotEmpty ? data.last.value : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242B24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Color(0xFFE8F0E8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${current.toStringAsFixed(1)} $unit',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: data.isEmpty
                ? const Center(
                    child: Text('Pas de données',
                        style: TextStyle(color: Color(0xFF6B8F6B))))
                : CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _LinePainter(
                      data: data,
                      color: color,
                      minY: minY,
                      maxY: maxY,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // Axe temps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (data.isNotEmpty)
                Text(
                  _formatTime(data.first.time),
                  style: const TextStyle(
                      color: Color(0xFF6B8F6B), fontSize: 10),
                ),
              Text(
                'Maintenant',
                style:
                    const TextStyle(color: Color(0xFF6B8F6B), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Painter courbe ───────────────────────────────────────────────────────────
class _LinePainter extends CustomPainter {
  final List<_DataPoint> data;
  final Color color;
  final double minY;
  final double maxY;

  _LinePainter(
      {required this.data,
      required this.color,
      required this.minY,
      required this.maxY});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final range = maxY - minY;
    final startTime = data.first.time.millisecondsSinceEpoch.toDouble();
    final endTime = data.last.time.millisecondsSinceEpoch.toDouble();
    final timeRange = endTime - startTime;

    // Grilles horizontales
    final gridPaint = Paint()
      ..color = const Color(0xFF2D3F2D)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Labels Y
    final textStyle = const TextStyle(
      color: Color(0xFF6B8F6B),
      fontSize: 9,
    );
    for (int i = 0; i <= 4; i++) {
      final val = maxY - (maxY - minY) * i / 4;
      final y = size.height * i / 4;
      final tp = TextPainter(
        text: TextSpan(
            text: val.toStringAsFixed(0), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 6));
    }

    // Zone remplie (gradient)
    final fillPath = Path();
    Offset? firstPoint;

    for (int i = 0; i < data.length; i++) {
      final t = data[i];
      final x = timeRange == 0
          ? 0.0
          : (t.time.millisecondsSinceEpoch - startTime) /
              timeRange *
              size.width;
      final y = size.height -
          ((t.value - minY) / range * size.height).clamp(0, size.height);

      if (i == 0) {
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        firstPoint = Offset(x, y);
      } else {
        final prev = data[i - 1];
        final px = timeRange == 0
            ? 0.0
            : (prev.time.millisecondsSinceEpoch - startTime) /
                timeRange *
                size.width;
        final py = size.height -
            ((prev.value - minY) / range * size.height)
                .clamp(0, size.height);
        // Courbe de Bézier cubique pour effet smooth
        final cp1x = px + (x - px) / 2;
        fillPath.cubicTo(cp1x, py, cp1x, y, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Ligne principale
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final t = data[i];
      final x = timeRange == 0
          ? 0.0
          : (t.time.millisecondsSinceEpoch - startTime) /
              timeRange *
              size.width;
      final y = size.height -
          ((t.value - minY) / range * size.height).clamp(0, size.height);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final prev = data[i - 1];
        final px = timeRange == 0
            ? 0.0
            : (prev.time.millisecondsSinceEpoch - startTime) /
                timeRange *
                size.width;
        final py = size.height -
            ((prev.value - minY) / range * size.height)
                .clamp(0, size.height);
        final cp1x = px + (x - px) / 2;
        linePath.cubicTo(cp1x, py, cp1x, y, x, y);
      }
    }
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Point actuel (dernier point)
    final lastT = data.last;
    final lx = size.width;
    final ly = size.height -
        ((lastT.value - minY) / range * size.height).clamp(0, size.height);
    canvas.drawCircle(
        Offset(lx, ly),
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(lx, ly),
        7,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.data != data || old.color != color;
}
