import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import '../widgets/scene_3d_view.dart';
import '../models/room_models.dart';
import '../assets_registry.dart';

class RoomDemoScreen extends StatefulWidget {
  const RoomDemoScreen({Key? key}) : super(key: key);

  @override
  _RoomDemoScreenState createState() => _RoomDemoScreenState();
}

class _RoomDemoScreenState extends State<RoomDemoScreen> {
  final List<FurnitureAsset> _demoAssets = [];

  @override
  void initState() {
    super.initState();
    _setupDemoRoom();
  }

  void _setupDemoRoom() {
    // Creamos una cocina demo profesional
    
    // 1. Heladera Grande
    _demoAssets.add(AssetRegistry.createAsset(101, v.Vector3(-1.5, 0, -1.5)));
    
    // 2. Cocina Gas
    _demoAssets.add(AssetRegistry.createAsset(104, v.Vector3(-0.5, 0, -1.5)));
    
    // 3. Gabinete con Microondas encima
    _demoAssets.add(AssetRegistry.createAsset(111, v.Vector3(0.5, 0, -1.5)));
    _demoAssets.add(AssetRegistry.createAsset(106, v.Vector3(0.5, 0.9, -1.5))); // Elevado
    
    // 4. Barra de Cocina
    _demoAssets.add(AssetRegistry.createAsset(115, v.Vector3(0, 0, 1.0)));
    
    // 5. Taburetes
    _demoAssets.add(AssetRegistry.createAsset(119, v.Vector3(-0.5, 0, 1.8)));
    _demoAssets.add(AssetRegistry.createAsset(119, v.Vector3(0.5, 0, 1.8)));
    
    // 6. Cafetera sobre la barra
    _demoAssets.add(AssetRegistry.createAsset(108, v.Vector3(0, 1.0, 1.0)));

    // Marcamos algunos como que tienen notas para ver el pulso neón
    _demoAssets[0].hasUnreadNotes = true; // Heladera
    _demoAssets[6].hasUnreadNotes = true; // Cafetera
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DEMO: Calidad 3D & Gemelo Digital', 
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent),
                ),
                child: const Text('INSIGHT MODE', 
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // El visualizador 3D en modo inspección (rotación automática)
          Scene3DView(
            assets: _demoAssets,
            isInspectionMode: true,
            onAssetSelected: (asset) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seleccionado: ${asset.name}'),
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
          ),
          
          // Overlay de información
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoTag(Icons.grid_4x4, 'Grilla de Precisión: Activa'),
                const SizedBox(height: 8),
                _infoTag(Icons.visibility, 'Paredes Dinámicas: Sims Style'),
                const SizedBox(height: 8),
                _infoTag(Icons.sensors, 'Sync WiFi: Simulando Cocina'),
              ],
            ),
          ),
          
          // Guía de usuario demo
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PROTOTIPO DE CALIBRACIÓN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los objetos que "vibran" tienen notas activas. Girando la cámara verás cómo las paredes se recortan automáticamente para no tapar la visión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 14),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
