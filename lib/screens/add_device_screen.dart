import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddDeviceScreen extends StatefulWidget {
  final Function(String id, String name, String emoji, String animal) onDeviceAdded;
  const AddDeviceScreen({super.key, required this.onDeviceAdded});
  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  bool _scanned = false;
  bool _scanning = true;
  String? _scannedId;
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🦎');
  final MobileScannerController _scannerController = MobileScannerController();

  final List<String> _animalEmojis = [
    '🦎', '🐍', '🐢', '🦕', '🦖', '🐊', '🦜', '🐸', '🦋', '🌿'
  ];
  String _selectedEmoji = '🦎';
  String _selectedAnimal = 'Animal';

  void _onQRDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final value = barcode!.rawValue!;
    // Le QR code doit contenir "terrarium:terrarium_001" par exemple
    if (value.startsWith('terrarium:')) {
      final id = value.replaceFirst('terrarium:', '');
      setState(() {
        _scanned = true;
        _scanning = false;
        _scannedId = id;
      });
      _scannerController.stop();
    }
  }

  void _addManually() {
    setState(() {
      _scanning = false;
      _scanned = true;
      _scannedId = null; // on laissera l'utilisateur taper l'ID
    });
    _scannerController.stop();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F1A),
      appBar: AppBar(
        title: const Text('Ajouter un boîtier'),
        backgroundColor: const Color(0xFF1A1F1A),
      ),
      body: _scanning ? _buildScanner() : _buildForm(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onQRDetected,
              ),
              // Overlay avec viseur
              Center(
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4ADE80), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Coins du viseur
                      Positioned(top: 0, left: 0, child: _corner()),
                      Positioned(top: 0, right: 0,
                        child: Transform.flip(flipX: true, child: _corner())),
                      Positioned(bottom: 0, left: 0,
                        child: Transform.flip(flipY: true, child: _corner())),
                      Positioned(bottom: 0, right: 0,
                        child: Transform.flip(flipX: true,
                          child: Transform.flip(flipY: true, child: _corner()))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Scanne le QR code collé sur ton boîtier',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFE8F0E8), fontSize: 15)),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _addManually,
                  child: const Text('Entrer l\'ID manuellement',
                    style: TextStyle(color: Color(0xFF6B8F6B))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _corner() {
    return Container(
      width: 20, height: 20,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF4ADE80), width: 3),
          left: BorderSide(color: Color(0xFF4ADE80), width: 3),
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
      ),
    );
  }

  Widget _buildForm() {
    final idController = TextEditingController(text: _scannedId ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Succès du scan
          if (_scannedId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF242B24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4ADE80), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                    color: Color(0xFF4ADE80), size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Boîtier détecté !',
                        style: TextStyle(color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.w500)),
                      Text(_scannedId!,
                        style: const TextStyle(color: Color(0xFF6B8F6B),
                          fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ID manuel si pas de scan
          if (_scannedId == null) ...[
            const Text('ID du boîtier',
              style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: idController,
              style: const TextStyle(color: Color(0xFFE8F0E8)),
              decoration: const InputDecoration(
                hintText: 'ex: terrarium_001',
                hintStyle: TextStyle(color: Color(0xFF2D3F2D)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF4ADE80))),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Nom du terrarium
          const Text('Nom du terrarium',
            style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Color(0xFFE8F0E8)),
            decoration: const InputDecoration(
              hintText: 'ex: Terrarium Victor',
              hintStyle: TextStyle(color: Color(0xFF2D3F2D)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2D3F2D))),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4ADE80))),
            ),
          ),
          const SizedBox(height: 24),

          // Choix de l'emoji
          const Text('Animal',
            style: TextStyle(color: Color(0xFF6B8F6B), fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _animalEmojis.map((emoji) => GestureDetector(
                onTap: () => setState(() { _selectedEmoji = emoji; _selectedAnimal = emoji; }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedEmoji == emoji
                      ? const Color(0xFF2D3F2D) : const Color(0xFF242B24),
                    border: Border.all(
                      color: _selectedEmoji == emoji
                        ? const Color(0xFF4ADE80) : const Color(0xFF2D3F2D)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: () {
              final id = _scannedId ?? idController.text.trim();
              final name = _nameController.text.trim();
              if (id.isEmpty || name.isEmpty) return;
              widget.onDeviceAdded(id, name, _selectedEmoji, _selectedAnimal);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFF4ADE80),
              foregroundColor: const Color(0xFF1A1F1A),
            ),
            child: const Text('Ajouter le boîtier',
              style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}