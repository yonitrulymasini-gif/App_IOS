import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'app_theme.dart';

class AddDeviceScreen extends StatefulWidget {
  final Function(String id, String name, String emoji, String animal) onDeviceAdded;
  const AddDeviceScreen({super.key, required this.onDeviceAdded});
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _name   = TextEditingController();
  final _idCtrl = TextEditingController();
  final _scanner = MobileScannerController();
  bool _scanning = true;
  bool _scanned  = false;
  String? _scannedId;
  String _emoji  = '🦎';
  String _animal = 'Animal';

  static const _animals = [
    ('🦎', 'Agame'), ('🐍', 'Serpent'), ('🐢', 'Tortue'),
    ('🦖', 'Gecko'), ('🐊', 'Caïman'), ('🐸', 'Grenouille'),
    ('🦋', 'Insecte'), ('🌿', 'Plante'),
  ];

  @override
  void dispose() { _scanner.dispose(); _name.dispose(); _idCtrl.dispose(); super.dispose(); }

  void _onDetect(BarcodeCapture c) {
    if (_scanned) return;
    final val = c.barcodes.firstOrNull?.rawValue ?? '';
    if (val.startsWith('terrarium:')) {
      final id = val.replaceFirst('terrarium:', '');
      _scanner.stop();
      setState(() { _scanned = true; _scanning = false; _scannedId = id; });
    }
  }

  void _submit() {
    final id = _scannedId ?? _idCtrl.text.trim();
    final nm = _name.text.trim();
    if (id.isEmpty || nm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID et nom requis')));
      return;
    }
    widget.onDeviceAdded(id, nm, _emoji, _animal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un boîtier'),
        actions: _scanning
            ? [TextButton(
                onPressed: () { _scanner.stop(); setState(() { _scanning = false; _scanned = true; }); },
                child: Text('Manuel', style: T.t14.copyWith(color: T.green)),
              )]
            : null,
      ),
      body: _scanning ? _buildScanner() : _buildForm(),
    );
  }

  Widget _buildScanner() => Stack(children: [
    MobileScanner(controller: _scanner, onDetect: _onDetect),
    Center(child: Container(
      width: 200, height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: T.green, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    )),
    Positioned(bottom: 48, left: 0, right: 0,
      child: Text('Scanne le QR code du boîtier',
          textAlign: TextAlign.center, style: T.t14.copyWith(color: T.textPrimary))),
  ]);

  Widget _buildForm() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      // ID scanné
      if (_scannedId != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: T.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: T.green.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_outline, color: T.green, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_scannedId!, style: T.t13.copyWith(color: T.green))),
          ]),
        ),
        const SizedBox(height: 20),
      ],

      // ID manuel
      if (_scannedId == null) ...[
        _Label('ID du boîtier'),
        const SizedBox(height: 6),
        TextField(
          controller: _idCtrl,
          style: const TextStyle(color: T.textPrimary, fontSize: 15),
          decoration: const InputDecoration(hintText: 'terrarium_001'),
        ),
        const SizedBox(height: 20),
      ],

      // Nom
      _Label('Nom'),
      const SizedBox(height: 6),
      TextField(
        controller: _name,
        style: const TextStyle(color: T.textPrimary, fontSize: 15),
        decoration: const InputDecoration(hintText: 'Ex: Terrarium Victor'),
      ),
      const SizedBox(height: 24),

      // Animal
      _Label('Animal'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _animals.map((a) {
          final (ico, lbl) = a;
          final sel = _emoji == ico;
          return GestureDetector(
            onTap: () => setState(() { _emoji = ico; _animal = lbl; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? T.green.withValues(alpha: 0.12) : T.elevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? T.green : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ico, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(lbl, style: T.t13.copyWith(
                    color: sel ? T.green : T.textSecondary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 32),

      FilledButton(
        onPressed: _submit,
        style: FilledButton.styleFrom(
          backgroundColor: T.green, foregroundColor: T.bg,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: T.t12.copyWith(color: T.textSecondary, letterSpacing: 0.3));
}
