import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class _Point { final DateTime t; final double v; _Point(this.t, this.v); }

class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});
  @override
  State<DashboardStatsScreen> createState() => _State();
}

class _State extends State<DashboardStatsScreen> {
  List<Map<String, dynamic>> _terrariums = [];
  String? _selId;
  bool _loading = true;
  int _range = 24;

  List<_Point> _temp  = [];
  List<_Point> _humid = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('terrariums') ?? [];
    final list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    setState(() {
      _terrariums = list;
      if (list.isNotEmpty) {
        _selId = list[0]['id'];
        _gen(list[0]);
      }
      _loading = false;
    });
  }

  void _gen(Map<String, dynamic> t) {
    final rng  = Random(t['id'].hashCode);
    final now  = DateTime.now();
    final base = (t['temperature'] as num?)?.toDouble() ?? 28.0;
    final hum  = (t['humidity'] as num?)?.toDouble() ?? 65.0;
    _temp  = List.generate(72, (i) {
      final dt = now.subtract(Duration(hours: 72 - i));
      return _Point(dt, base + sin((dt.hour - 6) * pi / 12) * 3 + (rng.nextDouble() - 0.5) * 1.5);
    });
    _humid = List.generate(72, (i) {
      final dt = now.subtract(Duration(hours: 72 - i));
      return _Point(dt, (hum + (rng.nextDouble() - 0.5) * 8).clamp(30.0, 95.0));
    });
  }

  List<_Point> _f(List<_Point> d) {
    final cut = DateTime.now().subtract(Duration(hours: _range));
    return d.where((p) => p.t.isAfter(cut)).toList();
  }

  double _avg(List<_Point> d) => d.isEmpty ? 0 : d.map((p) => p.v).reduce((a, b) => a + b) / d.length;
  double _min(List<_Point> d) => d.isEmpty ? 0 : d.map((p) => p.v).reduce(min);
  double _max(List<_Point> d) => d.isEmpty ? 0 : d.map((p) => p.v).reduce(max);

  @override
  Widget build(BuildContext context) {
    final ft = _f(_temp);
    final fh = _f(_humid);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Dashboard'),
              backgroundColor: T.bg, surfaceTintColor: Colors.transparent),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()))
          else if (_terrariums.isEmpty)
            SliverFillRemaining(child: Center(
              child: Text('Aucun terrarium', style: T.t15.copyWith(color: T.textSecondary)),
            ))
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Sélecteur terrarium
                    if (_terrariums.length > 1) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _terrariums.map((t) {
                            final sel = t['id'] == _selId;
                            return GestureDetector(
                              onTap: () => setState(() { _selId = t['id']; _gen(t); }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel ? T.green.withValues(alpha: 0.12) : T.elevated,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: sel ? T.green : Colors.transparent),
                                ),
                                child: Text('${t['emoji']} ${t['name']}',
                                    style: T.t13.copyWith(
                                        color: sel ? T.green : T.textSecondary,
                                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sélecteur plage
                    Row(
                      children: [6, 24, 48, 72].map((h) {
                        final sel = _range == h;
                        return GestureDetector(
                          onTap: () => setState(() => _range = h),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel ? T.green : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${h}h', style: T.t13.copyWith(
                                color: sel ? T.bg : T.textSecondary,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Stat row temp
                    _StatRow(
                      label: 'Température',
                      unit: '°C',
                      color: T.green,
                      avg: _avg(ft), mn: _min(ft), mx: _max(ft),
                    ),
                    const SizedBox(height: 8),
                    _Chart(data: ft, color: T.green, minY: 15, maxY: 45),
                    const SizedBox(height: 28),

                    // Stat row humid
                    _StatRow(
                      label: 'Humidité',
                      unit: '%',
                      color: T.blue,
                      avg: _avg(fh), mn: _min(fh), mx: _max(fh),
                    ),
                    const SizedBox(height: 8),
                    _Chart(data: fh, color: T.blue, minY: 20, maxY: 100),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, unit;
  final Color color;
  final double avg, mn, mx;
  const _StatRow({required this.label, required this.unit, required this.color,
    required this.avg, required this.mn, required this.mx});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500))),
    _Val('moy', '${avg.toStringAsFixed(1)}$unit', color),
    const SizedBox(width: 16),
    _Val('min', '${mn.toStringAsFixed(1)}$unit', T.textSecondary),
    const SizedBox(width: 16),
    _Val('max', '${mx.toStringAsFixed(1)}$unit', T.textSecondary),
  ]);
}

class _Val extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Val(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(value, style: T.t13.copyWith(color: color, fontWeight: FontWeight.w600)),
    Text(label,  style: T.t12.copyWith(color: T.textTertiary)),
  ]);
}

class _Chart extends StatelessWidget {
  final List<_Point> data;
  final Color color;
  final double minY, maxY;
  const _Chart({required this.data, required this.color, required this.minY, required this.maxY});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 100,
    child: data.isEmpty
        ? Center(child: Text('Pas de données', style: T.t13.copyWith(color: T.textTertiary)))
        : CustomPaint(size: const Size(double.infinity, 100),
            painter: _Painter(data: data, color: color, minY: minY, maxY: maxY)),
  );
}

class _Painter extends CustomPainter {
  final List<_Point> data;
  final Color color;
  final double minY, maxY;
  _Painter({required this.data, required this.color, required this.minY, required this.maxY});

  double _x(int i, double w) {
    final st = data.first.t.millisecondsSinceEpoch.toDouble();
    final en = data.last.t.millisecondsSinceEpoch.toDouble();
    if (en == st) return w;
    return (data[i].t.millisecondsSinceEpoch - st) / (en - st) * w;
  }

  double _y(double v, double h) => h - ((v - minY) / (maxY - minY) * h).clamp(0, h);

  @override
  void paint(Canvas canvas, Size s) {
    // Grid lines
    for (int i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, s.height * i / 3), Offset(s.width, s.height * i / 3),
          Paint()..color = T.border..strokeWidth = 0.5);
    }

    if (data.length < 2) return;

    // Fill
    final fill = Path()..moveTo(_x(0, s.width), s.height);
    fill.lineTo(_x(0, s.width), _y(data[0].v, s.height));
    for (int i = 1; i < data.length; i++) {
      final px = _x(i - 1, s.width), py = _y(data[i - 1].v, s.height);
      final cx = _x(i, s.width),     cy = _y(data[i].v, s.height);
      final cpx = px + (cx - px) / 2;
      fill.cubicTo(cpx, py, cpx, cy, cx, cy);
    }
    fill..lineTo(_x(data.length - 1, s.width), s.height)..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));

    // Line
    final line = Path()..moveTo(_x(0, s.width), _y(data[0].v, s.height));
    for (int i = 1; i < data.length; i++) {
      final px = _x(i - 1, s.width), py = _y(data[i - 1].v, s.height);
      final cx = _x(i, s.width),     cy = _y(data[i].v, s.height);
      final cpx = px + (cx - px) / 2;
      line.cubicTo(cpx, py, cpx, cy, cx, cy);
    }
    canvas.drawPath(line, Paint()
      ..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Dot dernier point
    final lx = _x(data.length - 1, s.width);
    final ly = _y(data.last.v, s.height);
    canvas.drawCircle(Offset(lx, ly), 3, Paint()..color = color);
    canvas.drawCircle(Offset(lx, ly), 6, Paint()..color = color.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(_Painter o) => o.data != data;
}
